# V9 Integration Module for helper.ps1
# Purpose: Provides seamless integration between existing helper.ps1 functions and V9 CSV format
# Author: GitHub Copilot
# Date: 2025

<#
.SYNOPSIS
    Integration layer between helper.ps1 and V9 CSV adapter

.DESCRIPTION
    This module wraps existing helper.ps1 task functions to:
    1. Auto-detect latest V9 config file from Downloads
    2. Parse V9 multi-section CSV format
    3. Execute task operations on tickets section
    4. Write back with all sections preserved
    5. Maintain backward compatibility with existing commands

.NOTES
    Users can continue using existing commands without any syntax changes.
    The module automatically handles V9 format if available, falls back to legacy format if not.
#>

# Import V9 adapter module
. "$PSScriptRoot/v9_csv_adapter.ps1"

# Global state for V9 integration (using $global: to share across all scripts)
$global:UseV9Format = $false
$global:CurrentV9ConfigFile = $null
$global:V9ConfigData = $null

function Initialize-V9Environment {
    <#
    .SYNOPSIS
        Initializes V9 environment by detecting and loading latest config file
    
    .DESCRIPTION
        Attempts to find and load the latest V9 config file from Downloads.
        If found, sets up V9 mode. Otherwise falls back to legacy mode.
    
    .PARAMETER Force
        Force reload even if already initialized
    
    .OUTPUTS
        Boolean: $true if V9 mode initialized, $false if using legacy mode
    
    .EXAMPLE
        if (Initialize-V9Environment) {
            Write-Host "Running in V9 mode"
        }
    #>
    param(
        [switch]$Force
    )
    
    # Skip if already initialized (unless forced)
    if ($global:UseV9Format -and !$Force) {
        Write-Verbose "V9 environment already initialized"
        return $true
    }
    
    Write-Host "`n🔍 Checking for V9 config files..." -ForegroundColor Cyan
    
    # Try to find latest V9 config file
    $configFile = Get-LatestV9ConfigFile
    
    if ($null -eq $configFile) {
        Write-Host "⚙️  Using legacy mode (task_progress_data.csv)" -ForegroundColor Yellow
        Write-Host "   To use V9 mode: Export config from html_console_v9.html to Downloads folder" -ForegroundColor Yellow
        $global:UseV9Format = $false
        return $false
    }
    
    # Load config file first
    $config = Read-V9ConfigFile -FilePath $configFile -UseCache
    if ($null -eq $config) {
        Write-Host "❌ Failed to load V9 config file" -ForegroundColor Red
        Write-Host "⚙️  Falling back to legacy mode" -ForegroundColor Yellow
        $global:UseV9Format = $false
        return $false
    }
    
    # Validate the loaded config (no file I/O, just data validation)
    if ($config.TaskSizes.Count -eq 0) {
        Write-Host "⚠️  V9 config validation failed: Missing task sizes" -ForegroundColor Red
        Write-Host "⚙️  Falling back to legacy mode" -ForegroundColor Yellow
        $global:UseV9Format = $false
        return $false
    }
    
    # Set V9 mode
    $global:UseV9Format = $true
    $global:CurrentV9ConfigFile = $configFile
    $global:V9ConfigData = $config
    
    Write-Host "✅ V9 mode initialized" -ForegroundColor Green
    Write-Host "   Config: $(Split-Path $configFile -Leaf)" -ForegroundColor Cyan
    Write-Host "   Tickets: $($config.Tickets.Count)" -ForegroundColor Cyan
    Write-Host "   People: $($config.People.Count)" -ForegroundColor Cyan
    Write-Host "   Task Sizes: $($config.TaskSizes.Count)" -ForegroundColor Cyan
    
    return $true
}

function Save-V9Changes {
    <#
    .SYNOPSIS
        Saves V9 config data back to file with backup
    
    .DESCRIPTION
        Writes modified V9 config data back to file while preserving all sections.
        Creates backup before overwriting. Updates cache.
    
    .OUTPUTS
        Boolean: $true if save successful, $false otherwise
    
    .EXAMPLE
        # Modify tickets...
        Save-V9Changes
    #>
    
    if (!$global:UseV9Format) {
        Write-Verbose "Not in V9 mode, skipping save"
        return $false
    }
    
    if ($null -eq $global:V9ConfigData) {
        Write-Host "❌ No V9 config data to save" -ForegroundColor Red
        return $false
    }
    
    $success = Write-V9ConfigFile -FilePath $global:CurrentV9ConfigFile -ConfigData $global:V9ConfigData -CreateBackup
    
    if ($success) {
        Write-Host "✅ Changes saved to V9 config file" -ForegroundColor Green
        
        # Ask if user wants to reload in HTML
        Write-Host "`n💡 To see changes in HTML console:" -ForegroundColor Cyan
        Write-Host "   1. Open html_console_v9.html" -ForegroundColor White
        Write-Host "   2. Click 'Import Config'" -ForegroundColor White
        Write-Host "   3. Select: $(Split-Path $global:CurrentV9ConfigFile -Leaf)" -ForegroundColor White
    }
    
    return $success
}

function Get-V9Tickets {
    <#
    .SYNOPSIS
        Gets tickets from V9 config or legacy CSV
    
    .DESCRIPTION
        Unified function to retrieve tasks regardless of format.
        Returns tickets in V9 format if available, legacy format otherwise.
    
    .PARAMETER EmployeeName
        Optional filter by employee name
    
    .PARAMETER Status
        Optional filter by status
    
    .OUTPUTS
        Array of ticket/task objects
    
    .EXAMPLE
        $tickets = Get-V9Tickets -EmployeeName "Peter"
        $activeTickets = Get-V9Tickets -Status "In Progress"
    #>
    param(
        [string]$EmployeeName,
        [string]$Status
    )
    
    if ($global:UseV9Format) {
        # V9 mode - return tickets from loaded config
        $tickets = $global:V9ConfigData.Tickets
        
        # Apply filters
        if ($EmployeeName) {
            $tickets = $tickets | Where-Object { $_.AssignedTeam -contains $EmployeeName }
        }
        
        if ($Status) {
            $tickets = $tickets | Where-Object { $_.Status -eq $Status }
        }
        
        return $tickets
    } else {
        # Legacy mode - read from flat CSV
        $taskFile = "./task_progress_data.csv"
        if (!(Test-Path $taskFile)) {
            Write-Host "❌ Legacy task file not found: $taskFile" -ForegroundColor Red
            return @()
        }
        
        $tasks = Import-Csv $taskFile
        
        # Apply filters
        if ($EmployeeName) {
            $tasks = $tasks | Where-Object { $_.EmployeeName -eq $EmployeeName }
        }
        
        if ($Status) {
            $tasks = $tasks | Where-Object { $_.Status -eq $Status }
        }
        
        return $tasks
    }
}

function Add-V9Ticket {
    <#
    .SYNOPSIS
        Adds a new ticket to V9 config or legacy CSV
    
    .DESCRIPTION
        Unified function to add tickets regardless of format.
        Automatically handles ID generation, validation, and persistence.
    
    .PARAMETER Description
        Task description (required)
    
    .PARAMETER AssignedTeam
        Array of person names to assign (optional, defaults to unassigned)
    
    .PARAMETER Size
        Task size key (S, M, L, XL, etc.) - required
    
    .PARAMETER Priority
        Priority (P1-P9) - defaults to P3
    
    .PARAMETER StartDate
        Start date in format YYYY-MM-DD (optional)
    
    .PARAMETER Status
        Status (To Do, In Progress, Completed, Blocked, Closed) - defaults to "To Do"
    
    .OUTPUTS
        The created ticket object, or $null if failed
    
    .EXAMPLE
        Add-V9Ticket -Description "New Feature" -AssignedTeam @("Peter", "Vipul") -Size "M" -Priority "P1"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [string[]]$AssignedTeam = @(),
        
        [Parameter(Mandatory=$true)]
        [string]$Size,
        
        [string]$Priority = "P3",
        
        [string]$StartDate = "",
        
        [string]$Status = "To Do"
    )
    
    if ($global:UseV9Format) {
        # V9 mode - add to loaded config
        
        # Validate size
        $validSizes = $global:V9ConfigData.TaskSizes | ForEach-Object { $_.Key }
        if ($Size -notin $validSizes) {
            Write-Host "❌ Invalid size: $Size. Valid sizes: $($validSizes -join ', ')" -ForegroundColor Red
            return $null
        }
        
        # Validate assigned team
        $validPeople = $global:V9ConfigData.People | ForEach-Object { $_.Name }
        $invalidPeople = $AssignedTeam | Where-Object { $_ -notin $validPeople -and $_ -ne '' }
        if ($invalidPeople.Count -gt 0) {
            Write-Host "⚠️  Unknown people in assigned team: $($invalidPeople -join ', ')" -ForegroundColor Yellow
            Write-Host "   Valid people: $($validPeople -join ', ')" -ForegroundColor Yellow
            Write-Host "   Continue anyway? (y/n): " -NoNewline
            $response = Read-Host
            if ($response -ne 'y') {
                return $null
            }
        }
        
        # Generate new ticket ID
        $maxId = ($global:V9ConfigData.Tickets | ForEach-Object { [int]$_.ID } | Measure-Object -Maximum).Maximum
        $newId = $maxId + 1
        
        # Create new ticket
        $newTicket = [PSCustomObject]@{
            ID = $newId
            Description = $Description
            StartDate = $StartDate
            Size = $Size
            Priority = $Priority
            AssignedTeam = $AssignedTeam
            Status = $Status
            TaskType = "Fixed"
            PauseComments = ""
            StartDateHistory = ""
            EndDateHistory = ""
            SizeHistory = ""
            CustomEndDate = ""
            DetailsDescription = ""
            DetailsPositives = ""
            DetailsNegatives = ""
        }
        
        # Add to config
        $global:V9ConfigData.Tickets += $newTicket
        
        # Save changes
        if (Save-V9Changes) {
            Write-Host "✅ Ticket #$newId added successfully" -ForegroundColor Green
            return $newTicket
        } else {
            Write-Host "❌ Failed to save ticket" -ForegroundColor Red
            return $null
        }
        
    } else {
        # Legacy mode - delegate to existing function
        Write-Host "⚠️  Legacy mode: Using Add-TaskProgressEntry function" -ForegroundColor Yellow
        
        # Map parameters to legacy format
        $employeeName = if ($AssignedTeam.Count -gt 0) { $AssignedTeam[0] } else { "UA" }
        
        # Call legacy function (if it exists)
        if (Get-Command Add-TaskProgressEntry -ErrorAction SilentlyContinue) {
            return Add-TaskProgressEntry -EmployeeName $employeeName -TaskDescription $Description
        } else {
            Write-Host "❌ Legacy function Add-TaskProgressEntry not found" -ForegroundColor Red
            return $null
        }
    }
}

function Update-V9Ticket {
    <#
    .SYNOPSIS
        Updates an existing ticket in V9 config or legacy CSV
    
    .DESCRIPTION
        Unified function to update tickets regardless of format.
        Supports partial updates (only specified fields are changed).
    
    .PARAMETER TicketId
        Ticket ID to update (required)
    
    .PARAMETER Description
        New description (optional)
    
    .PARAMETER AssignedTeam
        New assigned team (optional)
    
    .PARAMETER Size
        New size (optional)
    
    .PARAMETER Priority
        New priority (optional)
    
    .PARAMETER StartDate
        New start date (optional)
    
    .PARAMETER Status
        New status (optional)
    
    .OUTPUTS
        The updated ticket object, or $null if failed
    
    .EXAMPLE
        Update-V9Ticket -TicketId 5 -Status "In Progress" -AssignedTeam @("Peter")
        Update-V9Ticket -TicketId 10 -Priority "P1" -Size "L"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$TicketId,
        
        [string]$Description,
        [string[]]$AssignedTeam,
        [string]$Size,
        [string]$Priority,
        [string]$StartDate,
        [string]$Status
    )
    
    if ($global:UseV9Format) {
        # V9 mode - update in loaded config
        
        # Find ticket
        $ticket = $global:V9ConfigData.Tickets | Where-Object { [int]$_.ID -eq $TicketId }
        if ($null -eq $ticket) {
            Write-Host "❌ Ticket #$TicketId not found" -ForegroundColor Red
            return $null
        }
        
        # Update fields (only if provided)
        $changes = @()
        
        if ($Description) {
            $ticket.Description = $Description
            $changes += "Description → '$Description'"
        }
        
        if ($AssignedTeam) {
            $ticket.AssignedTeam = $AssignedTeam
            $changes += "Assigned Team → $($AssignedTeam -join ', ')"
        }
        
        if ($Size) {
            # Validate size
            $validSizes = $global:V9ConfigData.TaskSizes | ForEach-Object { $_.Key }
            if ($Size -notin $validSizes) {
                Write-Host "❌ Invalid size: $Size. Valid sizes: $($validSizes -join ', ')" -ForegroundColor Red
                return $null
            }
            $ticket.Size = $Size
            $changes += "Size → $Size"
        }
        
        if ($Priority) {
            $ticket.Priority = $Priority
            $changes += "Priority → $Priority"
        }
        
        if ($StartDate) {
            $ticket.StartDate = $StartDate
            $changes += "Start Date → $StartDate"
        }
        
        if ($Status) {
            $ticket.Status = $Status
            $changes += "Status → $Status"
        }
        
        if ($changes.Count -eq 0) {
            Write-Host "⚠️  No changes specified" -ForegroundColor Yellow
            return $ticket
        }
        
        # Display changes
        Write-Host "`n📝 Updating Ticket #${TicketId}: $($ticket.Description)" -ForegroundColor Cyan
        $changes | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        
        # Save changes
        if (Save-V9Changes) {
            Write-Host "✅ Ticket #$TicketId updated successfully" -ForegroundColor Green
            return $ticket
        } else {
            Write-Host "❌ Failed to save ticket" -ForegroundColor Red
            return $null
        }
        
    } else {
        # Legacy mode - delegate to existing function
        Write-Host "⚠️  Legacy mode: Manual CSV update required" -ForegroundColor Yellow
        Write-Host "   Use Update-TaskInCSV function with task file path" -ForegroundColor Yellow
        return $null
    }
}

function Remove-V9Ticket {
    <#
    .SYNOPSIS
        Removes a ticket from V9 config or legacy CSV
    
    .DESCRIPTION
        Unified function to delete tickets regardless of format.
        Supports soft delete (move to Closed status) or hard delete (remove from file).
    
    .PARAMETER TicketId
        Ticket ID to remove (required)
    
    .PARAMETER HardDelete
        If specified, permanently removes ticket. Otherwise marks as Closed.
    
    .OUTPUTS
        Boolean: $true if successful, $false otherwise
    
    .EXAMPLE
        Remove-V9Ticket -TicketId 5  # Soft delete (mark as Closed)
        Remove-V9Ticket -TicketId 5 -HardDelete  # Hard delete (remove from file)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$TicketId,
        
        [switch]$HardDelete
    )
    
    if ($global:UseV9Format) {
        # V9 mode - remove from loaded config
        
        # Find ticket
        $ticket = $global:V9ConfigData.Tickets | Where-Object { [int]$_.ID -eq $TicketId }
        if ($null -eq $ticket) {
            Write-Host "❌ Ticket #$TicketId not found" -ForegroundColor Red
            return $false
        }
        
        Write-Host "`n🗑️  Ticket #${TicketId}: $($ticket.Description)" -ForegroundColor Yellow
        
        if ($HardDelete) {
            # Hard delete - remove from array
            Write-Host "⚠️  HARD DELETE: This will permanently remove the ticket!" -ForegroundColor Red
            Write-Host "   Are you sure? (y/n): " -NoNewline
            $response = Read-Host
            
            if ($response -ne 'y') {
                Write-Host "❌ Deletion cancelled" -ForegroundColor Yellow
                return $false
            }
            
            $global:V9ConfigData.Tickets = $global:V9ConfigData.Tickets | Where-Object { [int]$_.ID -ne $TicketId }
            Write-Host "✅ Ticket #$TicketId permanently deleted" -ForegroundColor Green
            
        } else {
            # Soft delete - mark as Closed
            $ticket.Status = "Closed"
            Write-Host "✅ Ticket #$TicketId marked as Closed" -ForegroundColor Green
        }
        
        # Save changes
        return Save-V9Changes
        
    } else {
        # Legacy mode - manual operation required
        Write-Host "⚠️  Legacy mode: Manual CSV edit required" -ForegroundColor Yellow
        Write-Host "   Open task_progress_data.csv and remove the task row" -ForegroundColor Yellow
        return $false
    }
}

function Show-V9Summary {
    <#
    .SYNOPSIS
        Displays summary of V9 config or legacy CSV
    
    .DESCRIPTION
        Shows overview of current task tracking state:
        - Mode (V9 or legacy)
        - File location
        - Ticket counts by status
        - People and availability
        - Task size definitions
    
    .EXAMPLE
        Show-V9Summary
    #>
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  TASK TRACKING SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    if ($global:UseV9Format) {
        Write-Host "`n📊 Mode: V9 (Multi-section CSV)" -ForegroundColor Green
        Write-Host "📁 File: $(Split-Path $global:CurrentV9ConfigFile -Leaf)" -ForegroundColor White
        Write-Host "📅 Exported: $($global:V9ConfigData.Metadata['Export Date'])" -ForegroundColor White
        
        # Ticket stats by status
        Write-Host "`n📋 Tickets by Status:" -ForegroundColor Cyan
        $statusGroups = $global:V9ConfigData.Tickets | Group-Object Status | Sort-Object Count -Descending
        foreach ($group in $statusGroups) {
            $statusColor = switch ($group.Name) {
                "To Do" { "Yellow" }
                "In Progress" { "Cyan" }
                "Completed" { "Green" }
                "Closed" { "DarkGray" }
                "Blocked" { "Red" }
                default { "White" }
            }
            Write-Host "   $($group.Name): $($group.Count)" -ForegroundColor $statusColor
        }
        
        # People
        Write-Host "`n👥 People ($($global:V9ConfigData.People.Count)):" -ForegroundColor Cyan
        foreach ($person in $global:V9ConfigData.People) {
            $assignedTickets = ($global:V9ConfigData.Tickets | Where-Object { $_.AssignedTeam -contains $person.Name }).Count
            $readyStatus = if ($person.ProjectReady) { "✓" } else { "✗" }
            Write-Host "   $($person.Name): $assignedTickets tickets | Ready: $readyStatus" -ForegroundColor White
        }
        
        # Task sizes
        Write-Host "`n📏 Task Sizes:" -ForegroundColor Cyan
        foreach ($size in $global:V9ConfigData.TaskSizes) {
            Write-Host "   $($size.Key) - $($size.Name): $($size.Days) days" -ForegroundColor White
        }
        
        # Settings
        Write-Host "`n⚙️  Settings:" -ForegroundColor Cyan
        Write-Host "   Base Hours: $($global:V9ConfigData.Settings['Estimation Base Hours'])" -ForegroundColor White
        Write-Host "   Project Hours/Day: $($global:V9ConfigData.Settings['Project Hours Per Day'])" -ForegroundColor White
        Write-Host "   Next Ticket ID: $($global:V9ConfigData.Settings['Current Ticket ID'])" -ForegroundColor White
        
    } else {
        Write-Host "`n📊 Mode: Legacy (Flat CSV)" -ForegroundColor Yellow
        Write-Host "📁 File: task_progress_data.csv" -ForegroundColor White
        
        $taskFile = "./task_progress_data.csv"
        if (Test-Path $taskFile) {
            $tasks = Import-Csv $taskFile
            
            # Task stats by status
            Write-Host "`n📋 Tasks by Status:" -ForegroundColor Cyan
            $statusGroups = $tasks | Group-Object Status | Sort-Object Count -Descending
            foreach ($group in $statusGroups) {
                Write-Host "   $($group.Name): $($group.Count)" -ForegroundColor White
            }
            
            # People
            Write-Host "`n👥 People:" -ForegroundColor Cyan
            $peopleGroups = $tasks | Group-Object EmployeeName | Sort-Object Count -Descending
            foreach ($group in $peopleGroups) {
                Write-Host "   $($group.Name): $($group.Count) tasks" -ForegroundColor White
            }
        } else {
            Write-Host "⚠️  Task file not found" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
}

# Auto-initialize on module load (with suppressed output)
$initResult = Initialize-V9Environment
Write-Host ""  # Add spacing

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-V9Environment',
    'Save-V9Changes',
    'Get-V9Tickets',
    'Add-V9Ticket',
    'Update-V9Ticket',
    'Remove-V9Ticket',
    'Show-V9Summary'
)

Write-Host "✅ V9 Integration module loaded" -ForegroundColor Green
Write-Host "   Available functions: Get-V9Tickets, Add-V9Ticket, Update-V9Ticket, Remove-V9Ticket, Show-V9Summary" -ForegroundColor Cyan
Write-Host "   Run 'Show-V9Summary' to see current state" -ForegroundColor Cyan
