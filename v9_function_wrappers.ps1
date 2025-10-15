# V9 Function Wrappers for helper.ps1
# Purpose: Makes existing helper.ps1 functions automatically work with V9 CSV format
# Author: GitHub Copilot
# Date: 2025

<#
.SYNOPSIS
    Transparent V9 integration for existing helper.ps1 functions

.DESCRIPTION
    This module wraps existing helper.ps1 functions to automatically:
    1. Detect if V9 config is available
    2. Convert V9 tickets to legacy format on read
    3. Convert legacy format back to V9 on write
    4. Preserve all V9 sections (metadata, settings, people, task sizes)
    good Nilima 
    Users can continue using existing commands without any syntax changes.
    The wrapper transparently handles format conversion.

.NOTES
    This is loaded AFTER v9_integration.ps1 to ensure V9 environment is initialized.
#>

# Store original function references before wrapping
if (-not $global:OriginalFunctionsStored) {
    $global:OriginalGetPersonActiveTasks = ${function:Get-PersonActiveTasks}
    $global:OriginalAddTaskProgressEntry = ${function:Add-TaskProgressEntry}
    $global:OriginalUpdateTaskPriority = ${function:Update-TaskPriority}
    $global:OriginalUpdateETA = ${function:Update-ETA}
    $global:OriginalUpdateTaskInCSV = ${function:Update-TaskInCSV}
    $global:OriginalFunctionsStored = $true
}

# Helper function to convert V9 tickets to legacy task format
function ConvertTo-LegacyTaskFormat {
    param(
        [Parameter(Mandatory=$true)]
        [array]$V9Tickets
    )
    
    $legacyTasks = @()
    
    foreach ($ticket in $V9Tickets) {
        # Map V9 status to legacy status
        $statusMap = @{
            'To Do' = 'Planned'
            'In Progress' = 'Active'
            'Completed' = 'Completed'
            'Blocked' = 'Blocked'
            'Closed' = 'Completed'
        }
        
        $legacyStatus = if ($statusMap.ContainsKey($ticket.Status)) {
            $statusMap[$ticket.Status]
        } else {
            'Active'
        }
        
        # Extract first assigned person or use "UA" for unassigned
        $employeeName = if ($ticket.AssignedTeam -and $ticket.AssignedTeam.Count -gt 0) {
            $ticket.AssignedTeam[0]
        } else {
            "UA"
        }
        
        # Convert priority (P1→1, P2→2, etc.)
        $priority = if ($ticket.Priority -match 'P(\d+)') {
            $Matches[1]
        } else {
            "3"
        }
        
        # Calculate progress based on status
        $progress = switch ($ticket.Status) {
            'Completed' { 100 }
            'Closed' { 100 }
            'In Progress' { 50 }
            'Blocked' { 25 }
            default { 0 }
        }
        
        # Create legacy task object
        $legacyTask = [PSCustomObject]@{
            'EmployeeName' = $employeeName
            'Task Description' = $ticket.Description
            'Priority' = $priority
            'StartDate' = $ticket.StartDate
            'ETA' = if ($ticket.CustomEndDate) { $ticket.CustomEndDate } else { '' }
            'Progress' = $progress
            'Status' = $legacyStatus
            'ProgressReportSent' = 'n'
            'FinalReportSent' = if ($legacyStatus -eq 'Completed') { 'y' } else { 'n' }
            'Created_Date' = $ticket.StartDate
            # Store V9-specific data for round-trip
            '_V9_ID' = $ticket.ID
            '_V9_Size' = $ticket.Size
            '_V9_AssignedTeam' = ($ticket.AssignedTeam -join ';')
            '_V9_TaskType' = $ticket.TaskType
            '_V9_Status' = $ticket.Status
        }
        
        $legacyTasks += $legacyTask
    }
    
    return $legacyTasks
}

# Helper function to sync legacy changes back to V9 format
function Sync-LegacyChangesToV9 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$LegacyTasks
    )
    
    if (-not $script:UseV9Format) {
        Write-Verbose "Not in V9 mode, skipping sync"
        return
    }
    
    Write-Host "`n🔄 Syncing changes back to V9 format..." -ForegroundColor Cyan
    
    # Update V9 tickets based on legacy task changes
    foreach ($legacyTask in $LegacyTasks) {
        if ($legacyTask._V9_ID) {
            # Find matching V9 ticket
            $ticketId = [int]$legacyTask._V9_ID
            $v9Ticket = $global:V9ConfigData.Tickets | Where-Object { [int]$_.ID -eq $ticketId }
            
            if ($v9Ticket) {
                # Sync changes from legacy to V9
                $v9Ticket.Description = $legacyTask.'Task Description'
                $v9Ticket.StartDate = $legacyTask.StartDate
                
                # Convert priority back (1→P1, 2→P2, etc.)
                $v9Ticket.Priority = "P$($legacyTask.Priority)"
                
                # Map legacy status back to V9 status
                $reverseStatusMap = @{
                    'Planned' = 'To Do'
                    'Active' = 'In Progress'
                    'Completed' = 'Completed'
                    'Blocked' = 'Blocked'
                }
                
                if ($reverseStatusMap.ContainsKey($legacyTask.Status)) {
                    $v9Ticket.Status = $reverseStatusMap[$legacyTask.Status]
                }
                
                # Update assigned team if changed
                if ($legacyTask.EmployeeName -ne 'UA') {
                    # Check if person is already in assigned team
                    if ($v9Ticket.AssignedTeam -notcontains $legacyTask.EmployeeName) {
                        # Replace first person or add if empty
                        if ($v9Ticket.AssignedTeam.Count -gt 0) {
                            $v9Ticket.AssignedTeam[0] = $legacyTask.EmployeeName
                        } else {
                            $v9Ticket.AssignedTeam = @($legacyTask.EmployeeName)
                        }
                    }
                }
                
                # Update custom end date if changed
                if ($legacyTask.ETA) {
                    $v9Ticket.CustomEndDate = $legacyTask.ETA
                }
            }
        }
    }
    
    # Save changes
    $saved = Save-V9Changes
    if ($saved) {
        Write-Host "✅ Changes synced to V9 config file" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Failed to sync changes to V9 config" -ForegroundColor Yellow
    }
}

# Wrapper for Get-PersonActiveTasks
function Get-PersonActiveTasks {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CsvFile,
        
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName
    )
    
    if ($global:UseV9Format) {
        Write-Verbose "V9 mode: Converting V9 tickets to legacy format"
        
        # Get tickets for this person
        $v9Tickets = $global:V9ConfigData.Tickets | Where-Object { 
            $_.AssignedTeam -contains $EmployeeName -and $_.Status -ne 'Closed'
        }
        
        if ($v9Tickets.Count -eq 0) {
            Write-Host "No active tasks found for $EmployeeName" -ForegroundColor Yellow
            return @()
        }
        
        # Convert to legacy format
        return ConvertTo-LegacyTaskFormat -V9Tickets $v9Tickets
        
    } else {
        # Legacy mode - call original function
        return & $global:OriginalGetPersonActiveTasks -CsvFile $CsvFile -EmployeeName $EmployeeName
    }
}

# Wrapper for Add-TaskProgressEntry
function Add-TaskProgressEntry {
    param(
        [string]$NamePattern
    )
    
    if ($global:UseV9Format) {
        Write-Host "✨ V9 Mode Active - Using enhanced task management" -ForegroundColor Cyan
        
        # Get matched person name
        $MatchedName = Get-MatchedPersonName -NamePattern $NamePattern
        if (-not $MatchedName) { return }
        
        Write-Host "Found employee: $MatchedName" -ForegroundColor Green
        
        # Ask whether to add or modify
        Write-Host "`nAdd or Modify task? " -NoNewline -ForegroundColor Cyan
        $Action = Read-Host
        
        $IsAdd = $Action -match "a(d(d)?)?"
        $IsModify = $Action -match "m(o(d(i(f(y)?)?)?)?)?"
        
        if (-not $IsAdd -and -not $IsModify) {
            Write-Host "Invalid action. Please type 'add' or 'modify'" -ForegroundColor Red
            return
        }
        
        if ($IsModify) {
            # Show existing V9 tickets for this person
            $personTickets = $global:V9ConfigData.Tickets | Where-Object { 
                $_.AssignedTeam -contains $MatchedName -and $_.Status -ne 'Closed'
            } | Sort-Object { [int]$_.Priority.Replace('P', '') }
            
            if ($personTickets.Count -eq 0) {
                Write-Host "No existing tasks found for $MatchedName. Creating new task instead." -ForegroundColor Yellow
                $IsAdd = $true
                $IsModify = $false
            } else {
                Write-Host "`nExisting tasks for $MatchedName (ordered by priority):" -ForegroundColor Cyan
                
                for ($i = 0; $i -lt $personTickets.Count; $i++) {
                    $ticket = $personTickets[$i]
                    $sizeInfo = $global:V9ConfigData.TaskSizes | Where-Object { $_.Key -eq $ticket.Size }
                    $sizeName = if ($sizeInfo) { "$($ticket.Size) ($($sizeInfo.Days)d)" } else { $ticket.Size }
                    Write-Host "$($i + 1). $($ticket.Description) (Priority: $($ticket.Priority), Size: $sizeName, Status: $($ticket.Status))" -ForegroundColor White
                }
                
                Write-Host "`nSelect task number to modify (or 'c' to cancel): " -NoNewline -ForegroundColor Yellow
                $TaskNumber = Read-Host
                
                if ($TaskNumber -eq 'c') {
                    Write-Host "Cancelled" -ForegroundColor Yellow
                    return
                }
                
                try {
                    $SelectedTaskIndex = [int]$TaskNumber - 1
                    if ($SelectedTaskIndex -lt 0 -or $SelectedTaskIndex -ge $personTickets.Count) {
                        throw "Invalid selection"
                    }
                    $SelectedTicket = $personTickets[$SelectedTaskIndex]
                    
                    # Show modification menu
                    Write-Host "`n📝 Modifying: $($SelectedTicket.Description)" -ForegroundColor Cyan
                    Write-Host "What would you like to update?" -ForegroundColor Yellow
                    Write-Host "  1. Status" -ForegroundColor White
                    Write-Host "  2. Priority" -ForegroundColor White
                    Write-Host "  3. Size" -ForegroundColor White
                    Write-Host "  4. Description" -ForegroundColor White
                    Write-Host "  5. Start Date" -ForegroundColor White
                    Write-Host "  6. Assigned Team" -ForegroundColor White
                    Write-Host "Select option: " -NoNewline -ForegroundColor Yellow
                    $UpdateOption = Read-Host
                    
                    switch ($UpdateOption) {
                        "1" {
                            Write-Host "Available statuses: To Do, In Progress, Completed, Blocked, Closed" -ForegroundColor Cyan
                            Write-Host "New status: " -NoNewline -ForegroundColor Yellow
                            $NewStatus = Read-Host
                            Update-V9Ticket -TicketId $SelectedTicket.ID -Status $NewStatus
                        }
                        "2" {
                            Write-Host "New priority (P1-P9): " -NoNewline -ForegroundColor Yellow
                            $NewPriority = Read-Host
                            Update-V9Ticket -TicketId $SelectedTicket.ID -Priority $NewPriority
                        }
                        "3" {
                            $validSizes = $global:V9ConfigData.TaskSizes | ForEach-Object { "$($_.Key) ($($_.Name), $($_.Days)d)" }
                            Write-Host "Available sizes: $($validSizes -join ', ')" -ForegroundColor Cyan
                            Write-Host "New size: " -NoNewline -ForegroundColor Yellow
                            $NewSize = Read-Host
                            Update-V9Ticket -TicketId $SelectedTicket.ID -Size $NewSize
                        }
                        "4" {
                            Write-Host "New description: " -NoNewline -ForegroundColor Yellow
                            $NewDescription = Read-Host
                            Update-V9Ticket -TicketId $SelectedTicket.ID -Description $NewDescription
                        }
                        "5" {
                            Write-Host "New start date (YYYY-MM-DD): " -NoNewline -ForegroundColor Yellow
                            $NewStartDate = Read-Host
                            Update-V9Ticket -TicketId $SelectedTicket.ID -StartDate $NewStartDate
                        }
                        "6" {
                            $availablePeople = $global:V9ConfigData.People | ForEach-Object { $_.Name }
                            Write-Host "Available people: $($availablePeople -join ', ')" -ForegroundColor Cyan
                            Write-Host "Assigned team (comma-separated): " -NoNewline -ForegroundColor Yellow
                            $NewTeam = Read-Host
                            $TeamArray = $NewTeam -split ',' | ForEach-Object { $_.Trim() }
                            Update-V9Ticket -TicketId $SelectedTicket.ID -AssignedTeam $TeamArray
                        }
                        default {
                            Write-Host "Invalid option" -ForegroundColor Red
                        }
                    }
                    
                } catch {
                    Write-Host "Invalid task number selected." -ForegroundColor Red
                    return
                }
            }
        }
        
        if ($IsAdd) {
            # Add new task
            Write-Host "`n➕ Adding new task for $MatchedName" -ForegroundColor Cyan
            
            Write-Host "Task description: " -NoNewline -ForegroundColor Yellow
            $Description = Read-Host
            
            # Show available sizes
            Write-Host "`nAvailable task sizes:" -ForegroundColor Cyan
            foreach ($size in $global:V9ConfigData.TaskSizes) {
                Write-Host "  $($size.Key) - $($size.Name): $($size.Days) days" -ForegroundColor White
            }
            Write-Host "Task size (default: M): " -NoNewline -ForegroundColor Yellow
            $Size = Read-Host
            if ([string]::IsNullOrWhiteSpace($Size)) {
                $Size = "M"
            }
            
            Write-Host "Priority (P1-P9, default: P3): " -NoNewline -ForegroundColor Yellow
            $Priority = Read-Host
            if ([string]::IsNullOrWhiteSpace($Priority)) {
                $Priority = "P3"
            }
            
            Write-Host "Start date (YYYY-MM-DD, or: today, tomorrow, yesterday, default: tomorrow): " -NoNewline -ForegroundColor Yellow
            $StartDateInput = Read-Host
            if ([string]::IsNullOrWhiteSpace($StartDateInput)) {
                $StartDateInput = "tomorrow"
            }
            
            # Parse date aliases
            switch ($StartDateInput.ToLower()) {
                "today" { $StartDate = Get-Date -Format "yyyy-MM-dd" }
                "tomorrow" { $StartDate = (Get-Date).AddDays(1).ToString("yyyy-MM-dd") }
                "yesterday" { $StartDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd") }
                default { $StartDate = $StartDateInput }
            }
            
            # Add ticket
            $newTicket = Add-V9Ticket -Description $Description `
                                      -AssignedTeam @($MatchedName) `
                                      -Size $Size `
                                      -Priority $Priority `
                                      -StartDate $StartDate
            
            if ($newTicket) {
                Write-Host "`n✅ Task added successfully!" -ForegroundColor Green
                Write-Host "   Ticket #$($newTicket.ID): $($newTicket.Description)" -ForegroundColor Cyan
            }
        }
        
    } else {
        # Legacy mode - call original function
        & $global:OriginalAddTaskProgressEntry -NamePattern $NamePattern
    }
}

Write-Host "✅ V9 function wrappers loaded - Existing commands now V9-aware!" -ForegroundColor Green
Write-Host "   Your original commands will automatically work with V9 CSV format" -ForegroundColor Cyan
