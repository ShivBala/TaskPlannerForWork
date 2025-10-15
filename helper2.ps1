# PowerShell Interface for html_console_v9.html - V9 Config Only
# Purpose: Simplified task management for V9 exported configs
# Author: GitHub Copilot
# Date: October 15, 2025

<#
.SYNOPSIS
    Clean PowerShell interface for V9 config file management

.DESCRIPTION
    This script provides a regex-based command interface for managing tasks
    in V9 config files exported from html_console_v9.html. It supports:
    - Quick task add/modify by person name
    - Capacity queries
    - Availability checks
    
.NOTES
    V9 Only - Does not support legacy CSV format
#>

# Import V9 adapter
. "$PSScriptRoot/v9_csv_adapter.ps1"

# Global state
$global:V9Config = $null
$global:V9ConfigPath = $null

#region Core Functions

function Initialize-V9Config {
    <#
    .SYNOPSIS
        Loads the latest V9 config from Downloads folder
    #>
    
    Write-Host "`n🔍 Looking for V9 config..." -ForegroundColor Cyan
    
    $configFile = Get-LatestV9ConfigFile
    if ($null -eq $configFile) {
        Write-Host "❌ No V9 config found in Downloads folder" -ForegroundColor Red
        Write-Host "   Please export config from html_console_v9.html first" -ForegroundColor Yellow
        return $false
    }
    
    $config = Read-V9ConfigFile -FilePath $configFile
    if ($null -eq $config) {
        Write-Host "❌ Failed to load config file" -ForegroundColor Red
        return $false
    }
    
    $global:V9Config = $config
    $global:V9ConfigPath = $configFile
    
    # Get projectHoursPerDay from settings (default 8)
    $global:ProjectHoursPerDay = 8
    $hoursPerDaySetting = $config.Settings | Where-Object { $_.Key -eq 'projectHoursPerDay' -or $_.Key -eq 'hoursPerDay' }
    if ($hoursPerDaySetting) {
        $global:ProjectHoursPerDay = [int]$hoursPerDaySetting.Value
    }
    
    # Initialize person availability arrays (8 weeks, default 25 hours/week)
    foreach ($person in $config.People) {
        if (-not $person.Availability) {
            $person.Availability = @(25, 25, 25, 25, 25, 25, 25, 25)
        } elseif ($person.Availability.Count -lt 8) {
            $lastValue = if ($person.Availability.Count -gt 0) { $person.Availability[-1] } else { 25 }
            while ($person.Availability.Count -lt 8) {
                $person.Availability += $lastValue
            }
        } elseif ($person.Availability.Count -gt 8) {
            $person.Availability = $person.Availability[0..7]
        }
    }
    
    Write-Host "✅ Loaded: $(Split-Path $configFile -Leaf)" -ForegroundColor Green
    Write-Host "   📊 $($config.Tickets.Count) tickets | $($config.People.Count) people" -ForegroundColor Cyan
    Write-Host "   ⏰ Project Hours/Day: $global:ProjectHoursPerDay" -ForegroundColor Cyan
    
    return $true
}

function Get-BusinessDays {
    <#
    .SYNOPSIS
        Calculates number of business days between two dates (excluding weekends)
    #>
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    
    $businessDays = 0
    $currentDate = $StartDate
    
    while ($currentDate -le $EndDate) {
        $dayOfWeek = [int]$currentDate.DayOfWeek
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) { # Monday to Friday
            $businessDays++
        }
        $currentDate = $currentDate.AddDays(1)
    }
    
    return $businessDays
}

function Add-BusinessDays {
    <#
    .SYNOPSIS
        Adds specified number of business days to a date
    #>
    param(
        [DateTime]$StartDate,
        [int]$Days
    )
    
    $currentDate = $StartDate
    $daysAdded = 0
    
    while ($daysAdded -lt $Days) {
        $currentDate = $currentDate.AddDays(1)
        $dayOfWeek = [int]$currentDate.DayOfWeek
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) { # Monday to Friday
            $daysAdded++
        }
    }
    
    return $currentDate
}

function Adjust-DateToWeekday {
    <#
    .SYNOPSIS
        Adjusts weekend dates to Monday
    #>
    param([DateTime]$Date)
    
    $dayOfWeek = [int]$Date.DayOfWeek
    if ($dayOfWeek -eq 0) { # Sunday
        return $Date.AddDays(1) # Move to Monday
    } elseif ($dayOfWeek -eq 6) { # Saturday
        return $Date.AddDays(2) # Move to Monday
    }
    return $Date
}

function Get-TaskEffortHours {
    <#
    .SYNOPSIS
        Gets total effort hours for a task size (matches HTML effortMap)
    #>
    param([string]$Size)
    
    $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $Size }
    if ($sizeInfo) {
        return [int]$sizeInfo.Days * $global:ProjectHoursPerDay
    }
    return $global:ProjectHoursPerDay # Default to 1 day
}

function Save-V9Config {
    <#
    .SYNOPSIS
        Saves changes back to the V9 config file
    #>
    
    if ($null -eq $global:V9Config -or $null -eq $global:V9ConfigPath) {
        Write-Host "❌ No config loaded" -ForegroundColor Red
        return $false
    }
    
    $success = Write-V9ConfigFile -FilePath $global:V9ConfigPath -ConfigData $global:V9Config -CreateBackup
    
    if ($success) {
        Write-Host "✅ Changes saved!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Save failed" -ForegroundColor Red
        return $false
    }
}

function Get-PersonByName {
    <#
    .SYNOPSIS
        Finds a person in the config by name (case-insensitive)
    #>
    param([string]$Name)
    
    return $global:V9Config.People | Where-Object { $_.Name -ieq $Name }
}

function Parse-DateAlias {
    <#
    .SYNOPSIS
        Converts date aliases to YYYY-MM-DD format
    .DESCRIPTION
        Supports: today, tomorrow, yesterday, next/last [day of week]
    #>
    param([string]$DateInput)
    
    if ([string]::IsNullOrWhiteSpace($DateInput)) {
        return ""
    }
    
    $input = $DateInput.Trim().ToLower()
    $today = Get-Date
    
    # Simple aliases
    switch ($input) {
        "today" { return $today.ToString("yyyy-MM-dd") }
        "tomorrow" { return $today.AddDays(1).ToString("yyyy-MM-dd") }
        "yesterday" { return $today.AddDays(-1).ToString("yyyy-MM-dd") }
    }
    
    # Next/Last [day of week]
    if ($input -match "^(next|last)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$") {
        $direction = $matches[1]
        $dayName = $matches[2]
        
        # Map day names to DayOfWeek enum
        $dayMap = @{
            "monday" = [DayOfWeek]::Monday
            "tuesday" = [DayOfWeek]::Tuesday
            "wednesday" = [DayOfWeek]::Wednesday
            "thursday" = [DayOfWeek]::Thursday
            "friday" = [DayOfWeek]::Friday
            "saturday" = [DayOfWeek]::Saturday
            "sunday" = [DayOfWeek]::Sunday
        }
        
        $targetDay = $dayMap[$dayName]
        $currentDay = $today.DayOfWeek
        
        if ($direction -eq "next") {
            $daysAhead = ($targetDay - $currentDay + 7) % 7
            if ($daysAhead -eq 0) { $daysAhead = 7 }
            return $today.AddDays($daysAhead).ToString("yyyy-MM-dd")
        } else {
            $daysBehind = ($currentDay - $targetDay + 7) % 7
            if ($daysBehind -eq 0) { $daysBehind = 7 }
            return $today.AddDays(-$daysBehind).ToString("yyyy-MM-dd")
        }
    }
    
    # If it's already a date or unrecognized, return as-is
    return $DateInput
}

#endregion

#region Task Management Functions

function Add-TaskForPerson {
    <#
    .SYNOPSIS
        Adds a new task for a person
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    Write-Host "`n➕ Adding task for $PersonName" -ForegroundColor Cyan
    
    # Description (required)
    Write-Host "`nDescription: " -NoNewline -ForegroundColor Yellow
    $description = Read-Host
    if ([string]::IsNullOrWhiteSpace($description)) {
        Write-Host "❌ Description is required" -ForegroundColor Red
        return
    }
    
    # Status (required)
    Write-Host "`nStatus:" -ForegroundColor Yellow
    Write-Host "  1. To Do" -ForegroundColor White
    Write-Host "  2. In Progress" -ForegroundColor White
    Write-Host "Choose (1/2): " -NoNewline -ForegroundColor Yellow
    $statusChoice = Read-Host
    
    $status = switch ($statusChoice) {
        "1" { "To Do" }
        "2" { "In Progress" }
        default { "To Do" }
    }
    
    # Start date (conditional default)
    $defaultStartDate = if ($status -eq "In Progress") { "today" } else { "tomorrow" }
    Write-Host "`nStart date (today/tomorrow/next wednesday, default: $defaultStartDate): " -NoNewline -ForegroundColor Yellow
    $startDateInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($startDateInput)) {
        $startDateInput = $defaultStartDate
    }
    $startDate = Parse-DateAlias -DateInput $startDateInput
    
    # Size (default M)
    Write-Host "`nAvailable sizes:" -ForegroundColor Yellow
    foreach ($size in $global:V9Config.TaskSizes) {
        Write-Host "  $($size.Key) - $($size.Name): $($size.Days) days" -ForegroundColor White
    }
    Write-Host "Size (default: M): " -NoNewline -ForegroundColor Yellow
    $sizeInput = Read-Host
    $size = if ([string]::IsNullOrWhiteSpace($sizeInput)) { "M" } else { $sizeInput }
    
    # Generate new ID
    $maxId = ($global:V9Config.Tickets | ForEach-Object { [int]$_.ID } | Measure-Object -Maximum).Maximum
    $newId = $maxId + 1
    
    # Create new ticket
    $newTicket = [PSCustomObject]@{
        ID = $newId
        Description = $description
        StartDate = $startDate
        Size = $size
        Priority = "P2"  # Default priority
        AssignedTeam = @($PersonName)
        Status = $status
        TaskType = "Fixed"  # Default task type
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
    $global:V9Config.Tickets += $newTicket
    
    # Save
    if (Save-V9Config) {
        Write-Host "`n✅ Task #$newId added successfully!" -ForegroundColor Green
        Write-Host "   $description" -ForegroundColor Cyan
        Write-Host "   Status: $status | Size: $size | Start: $startDate" -ForegroundColor Gray
    }
}

function Modify-TaskForPerson {
    <#
    .SYNOPSIS
        Modifies an existing task for a person
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    # Get active tasks for this person
    $tasks = $global:V9Config.Tickets | Where-Object {
        $_.AssignedTeam -contains $PersonName -and $_.Status -ne 'Closed'
    } | Sort-Object { [int]$_.Priority.Replace('P', '') }
    
    if ($tasks.Count -eq 0) {
        Write-Host "❌ No active tasks found for $PersonName" -ForegroundColor Yellow
        return
    }
    
    # Show tasks
    Write-Host "`n📋 Active tasks for $PersonName" -ForegroundColor Cyan
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $task = $tasks[$i]
        Write-Host "  $($i + 1). [$($task.Priority)] $($task.Description) - $($task.Status)" -ForegroundColor White
    }
    
    Write-Host "`nSelect task (1-$($tasks.Count)): " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host
    
    try {
        $index = [int]$selection - 1
        if ($index -lt 0 -or $index -ge $tasks.Count) {
            throw "Invalid selection"
        }
        
        $selectedTask = $tasks[$index]
        
        # Show modification menu
        Write-Host "`n📝 Modifying: $($selectedTask.Description)" -ForegroundColor Cyan
        Write-Host "`nWhat to update?" -ForegroundColor Yellow
        Write-Host "  1. Status" -ForegroundColor White
        Write-Host "  2. Priority" -ForegroundColor White
        Write-Host "  3. Size" -ForegroundColor White
        Write-Host "  4. Description" -ForegroundColor White
        Write-Host "Choose (1-4): " -NoNewline -ForegroundColor Yellow
        $updateChoice = Read-Host
        
        switch ($updateChoice) {
            "1" {
                Write-Host "`nNew Status:" -ForegroundColor Yellow
                Write-Host "  1. To Do" -ForegroundColor White
                Write-Host "  2. In Progress" -ForegroundColor White
                Write-Host "  3. Completed" -ForegroundColor White
                Write-Host "  4. Blocked" -ForegroundColor White
                Write-Host "  5. Closed" -ForegroundColor White
                Write-Host "Choose (1-5): " -NoNewline -ForegroundColor Yellow
                $statusChoice = Read-Host
                
                $newStatus = switch ($statusChoice) {
                    "1" { "To Do" }
                    "2" { "In Progress" }
                    "3" { "Completed" }
                    "4" { "Blocked" }
                    "5" { "Closed" }
                    default { $selectedTask.Status }
                }
                
                $selectedTask.Status = $newStatus
                Write-Host "✅ Status updated to: $newStatus" -ForegroundColor Green
            }
            "2" {
                Write-Host "`nNew priority (P1-P9, current: $($selectedTask.Priority)): " -NoNewline -ForegroundColor Yellow
                $newPriority = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($newPriority)) {
                    $selectedTask.Priority = $newPriority
                    Write-Host "✅ Priority updated to: $newPriority" -ForegroundColor Green
                }
            }
            "3" {
                Write-Host "`nAvailable sizes:" -ForegroundColor Yellow
                foreach ($size in $global:V9Config.TaskSizes) {
                    Write-Host "  $($size.Key) - $($size.Name): $($size.Days) days" -ForegroundColor White
                }
                Write-Host "New size (current: $($selectedTask.Size)): " -NoNewline -ForegroundColor Yellow
                $newSize = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($newSize)) {
                    $selectedTask.Size = $newSize
                    Write-Host "✅ Size updated to: $newSize" -ForegroundColor Green
                }
            }
            "4" {
                Write-Host "`nNew description: " -NoNewline -ForegroundColor Yellow
                $newDesc = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($newDesc)) {
                    $selectedTask.Description = $newDesc
                    Write-Host "✅ Description updated" -ForegroundColor Green
                }
            }
            default {
                Write-Host "❌ Invalid choice" -ForegroundColor Red
                return
            }
        }
        
        # Save changes
        Save-V9Config
        
    } catch {
        Write-Host "❌ Invalid selection" -ForegroundColor Red
    }
}

function Show-WeeklyCapacity {
    <#
    .SYNOPSIS
        Shows capacity for current week (matches HTML calculation exactly)
    .DESCRIPTION
        Uses hours-based calculation with business days and overlap detection
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    # Get current week bounds (Monday to Sunday)
    $today = Get-Date
    $daysFromMonday = ([int]$today.DayOfWeek + 6) % 7 # Distance from Monday
    $weekStart = $today.AddDays(-$daysFromMonday).Date
    $weekEnd = $weekStart.AddDays(6)
    
    Write-Host "`n📊 Weekly Capacity for $PersonName" -ForegroundColor Cyan
    Write-Host "   Week: $($weekStart.ToString('MMM dd')) - $($weekEnd.ToString('MMM dd, yyyy'))" -ForegroundColor Gray
    
    # Get person's availability for current week (week index 0)
    $weeklyAvailability = if ($person.Availability -and $person.Availability.Count -gt 0) {
        [double]$person.Availability[0]
    } else {
        $global:ProjectHoursPerDay * 5 # Default to 5 days
    }
    
    Write-Host "`n   Total Capacity: $weeklyAvailability hours/week" -ForegroundColor White
    
    # Calculate assigned hours for this week (matching HTML logic)
    $assignedHours = 0
    $activeTasksList = @()
    
    # Get active tickets
    $activeTickets = $global:V9Config.Tickets | Where-Object {
        $_.AssignedTeam -contains $PersonName -and 
        $_.Status -notin @('Closed', 'Completed') -and
        ![string]::IsNullOrWhiteSpace($_.StartDate)
    }
    
    foreach ($ticket in $activeTickets) {
        $taskStart = [DateTime]::ParseExact($ticket.StartDate, 'yyyy-MM-dd', $null)
        
        # Check if Fixed-Length or Flexible (default to Fixed)
        $isFixedLength = $ticket.TaskType -ne 'Flexible'
        
        # Get task size info
        $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $ticket.Size }
        $totalTaskDays = if ($sizeInfo) { [int]$sizeInfo.Days } else { 1 }
        $totalTaskEffort = Get-TaskEffortHours -Size $ticket.Size
        
        # Calculate task end date and daily hours per person
        $taskEnd = $null
        $dailyHoursForPerson = 0
        $numAssignees = [Math]::Max($ticket.AssignedTeam.Count, 1)
        
        if ($isFixedLength) {
            # Fixed-Length: Duration stays same, capacity scales
            $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($totalTaskDays - 1)
            $dailyHoursForPerson = $totalTaskEffort / ($totalTaskDays * $numAssignees)
        } else {
            # Flexible: Duration splits among assignees
            $daysPerPerson = [Math]::Ceiling($totalTaskDays / $numAssignees)
            $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($daysPerPerson - 1)
            $dailyHoursForPerson = $global:ProjectHoursPerDay
        }
        
        # Adjust start date if on weekend
        $taskStart = Adjust-DateToWeekday -Date $taskStart
        
        # Check if task overlaps with this week
        if ($taskStart -le $weekEnd -and $taskEnd -ge $weekStart) {
            # Calculate overlap period
            $overlapStart = if ($taskStart -gt $weekStart) { $taskStart } else { $weekStart }
            $overlapEnd = if ($taskEnd -lt $weekEnd) { $taskEnd } else { $weekEnd }
            
            # Calculate business days in overlap
            $businessDays = Get-BusinessDays -StartDate $overlapStart -EndDate $overlapEnd
            
            # Assign hours
            $taskHours = $dailyHoursForPerson * $businessDays
            $assignedHours += $taskHours
            
            $activeTasksList += [PSCustomObject]@{
                Description = $ticket.Description
                Priority = $ticket.Priority
                Size = $ticket.Size
                Status = $ticket.Status
                Hours = [Math]::Round($taskHours, 1)
                Days = $totalTaskDays
            }
        }
    }
    
    # Calculate utilization
    $availableHours = $weeklyAvailability - $assignedHours
    $utilizationPct = if ($weeklyAvailability -gt 0) {
        [Math]::Round(($assignedHours / $weeklyAvailability) * 100, 1)
    } elseif ($assignedHours -gt 0) {
        999 # Overload indicator
    } else {
        0
    }
    
    # Determine color
    $utilizationColor = if ($utilizationPct -ge 999 -or $utilizationPct -gt 90) {
        "Red"
    } elseif ($utilizationPct -gt 60) {
        "Yellow"
    } else {
        "Green"
    }
    
    Write-Host "   Assigned: $([Math]::Round($assignedHours, 1)) hours ($($activeTasksList.Count) tasks)" -ForegroundColor Yellow
    Write-Host "   Available: $([Math]::Round($availableHours, 1)) hours" -ForegroundColor $(if ($availableHours -gt 0) { "Green" } else { "Red" })
    Write-Host "   Utilization: $utilizationPct%" -ForegroundColor $utilizationColor
    
    # Show active tasks
    if ($activeTasksList.Count -gt 0) {
        Write-Host "`n   Active Tasks:" -ForegroundColor Cyan
        foreach ($task in $activeTasksList) {
            Write-Host "     [$($task.Priority)] $($task.Description) ($($task.Hours)h, $($task.Status))" -ForegroundColor White
        }
    }
}

function Show-MostAvailable {
    <#
    .SYNOPSIS
        Shows who is most available today to pick up a task (matches HTML calculation)
    #>
    
    Write-Host "`n👥 Team Availability (Current Week)" -ForegroundColor Cyan
    Write-Host "   $(Get-Date -Format 'dddd, MMMM dd, yyyy')" -ForegroundColor Gray
    
    # Get current week bounds
    $today = Get-Date
    $daysFromMonday = ([int]$today.DayOfWeek + 6) % 7
    $weekStart = $today.AddDays(-$daysFromMonday).Date
    $weekEnd = $weekStart.AddDays(6)
    
    $availability = @()
    
    foreach ($person in $global:V9Config.People) {
        # Get person's availability for current week (index 0)
        $weeklyAvailability = if ($person.Availability -and $person.Availability.Count -gt 0) {
            [double]$person.Availability[0]
        } else {
            $global:ProjectHoursPerDay * 5
        }
        
        # Calculate assigned hours using same logic as HTML
        $assignedHours = 0
        $activeTaskCount = 0
        
        $activeTickets = $global:V9Config.Tickets | Where-Object {
            $_.AssignedTeam -contains $person.Name -and 
            $_.Status -notin @('Closed', 'Completed') -and
            ![string]::IsNullOrWhiteSpace($_.StartDate)
        }
        
        foreach ($ticket in $activeTickets) {
            $taskStart = [DateTime]::ParseExact($ticket.StartDate, 'yyyy-MM-dd', $null)
            
            $isFixedLength = $ticket.TaskType -ne 'Flexible'
            $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $ticket.Size }
            $totalTaskDays = if ($sizeInfo) { [int]$sizeInfo.Days } else { 1 }
            $totalTaskEffort = Get-TaskEffortHours -Size $ticket.Size
            
            $taskEnd = $null
            $dailyHoursForPerson = 0
            $numAssignees = [Math]::Max($ticket.AssignedTeam.Count, 1)
            
            if ($isFixedLength) {
                $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($totalTaskDays - 1)
                $dailyHoursForPerson = $totalTaskEffort / ($totalTaskDays * $numAssignees)
            } else {
                $daysPerPerson = [Math]::Ceiling($totalTaskDays / $numAssignees)
                $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($daysPerPerson - 1)
                $dailyHoursForPerson = $global:ProjectHoursPerDay
            }
            
            $taskStart = Adjust-DateToWeekday -Date $taskStart
            
            # Check overlap with current week
            if ($taskStart -le $weekEnd -and $taskEnd -ge $weekStart) {
                $overlapStart = if ($taskStart -gt $weekStart) { $taskStart } else { $weekStart }
                $overlapEnd = if ($taskEnd -lt $weekEnd) { $taskEnd } else { $weekEnd }
                
                $businessDays = Get-BusinessDays -StartDate $overlapStart -EndDate $overlapEnd
                $assignedHours += $dailyHoursForPerson * $businessDays
                $activeTaskCount++
            }
        }
        
        # Calculate utilization
        $availableHours = $weeklyAvailability - $assignedHours
        $utilizationPct = if ($weeklyAvailability -gt 0) {
            [Math]::Round(($assignedHours / $weeklyAvailability) * 100, 1)
        } elseif ($assignedHours -gt 0) {
            999
        } else {
            0
        }
        
        $availability += [PSCustomObject]@{
            Name = $person.Name
            TotalCapacity = [Math]::Round($weeklyAvailability, 1)
            Assigned = [Math]::Round($assignedHours, 1)
            Available = [Math]::Round($availableHours, 1)
            Utilization = $utilizationPct
            ActiveTasks = $activeTaskCount
        }
    }
    
    # Sort by available hours (descending)
    $availability = $availability | Sort-Object Available -Descending
    
    Write-Host ""
    foreach ($person in $availability) {
        $availColor = if ($person.Available -gt 0) { "Green" } else { "Red" }
        $utilColor = if ($person.Utilization -ge 999 -or $person.Utilization -gt 90) {
            "Red"
        } elseif ($person.Utilization -gt 60) {
            "Yellow"
        } else {
            "Green"
        }
        
        Write-Host "   $($person.Name.PadRight(15)) " -NoNewline -ForegroundColor White
        Write-Host "Available: $($person.Available)h/$($person.TotalCapacity)h " -NoNewline -ForegroundColor $availColor
        Write-Host "($($person.Utilization)% utilized, $($person.ActiveTasks) tasks)" -ForegroundColor $utilColor
    }
    
    # Highlight most available
    $mostAvailable = $availability[0]
    $utilColor = if ($mostAvailable.Utilization -ge 999 -or $mostAvailable.Utilization -gt 90) {
        "Red"
    } elseif ($mostAvailable.Utilization -gt 60) {
        "Yellow"
    } else {
        "Cyan"
    }
    Write-Host "`n   🌟 Most Available: $($mostAvailable.Name) ($($mostAvailable.Available)h free, $($mostAvailable.Utilization)% utilized)" -ForegroundColor $utilColor
}

#endregion

#region Command Dispatcher

function Invoke-Command {
    <#
    .SYNOPSIS
        Matches user input to commands using regex patterns
    #>
    param([string]$UserInput)
    
    $inputText = $UserInput.Trim().ToLower()
    
    # Person name patterns (for add/modify tasks)
    if ($inputText -match "^(siva|vipul|peter|sameet|sharanya|divya)$") {
        $personName = (Get-Culture).TextInfo.ToTitleCase($matches[1])
        
        # Check if person exists in config
        $person = Get-PersonByName -Name $personName
        if ($null -eq $person) {
            Write-Host "❌ Person not found in config: $personName" -ForegroundColor Red
            return
        }
        
        Write-Host "`nAdd or Modify task for $personName?" -ForegroundColor Cyan
        Write-Host "  1. Add    (or type: a, ad, add)" -ForegroundColor White
        Write-Host "  2. Modify (or type: m, mo, mod, modi, modif, modify)" -ForegroundColor White
        Write-Host "Choose: " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        $choiceLower = $choice.Trim().ToLower()
        
        # Match add variants
        if ($choiceLower -match "^(1|a|ad|add)$") {
            Add-TaskForPerson -PersonName $personName
        }
        # Match modify variants
        elseif ($choiceLower -match "^(2|m|mo|mod|modi|modif|modify)$") {
            Modify-TaskForPerson -PersonName $personName
        }
        else {
            Write-Host "❌ Invalid choice" -ForegroundColor Red
        }
        return
    }
    
    # Capacity query
    if ($inputText -match "^capacity\s+(.+)$") {
        $personName = (Get-Culture).TextInfo.ToTitleCase($matches[1].Trim())
        Show-WeeklyCapacity -PersonName $personName
        return
    }
    
    if ($inputText -match "^capacity$") {
        Write-Host "Usage: capacity <person name>" -ForegroundColor Yellow
        Write-Host "Example: capacity vipul" -ForegroundColor Gray
        return
    }
    
    # Availability query
    if ($inputText -match "^availability$") {
        Show-MostAvailable
        return
    }
    
    # Help
    if ($inputText -match "^help$") {
        Show-Help
        return
    }
    
    # Reload config
    if ($inputText -match "^reload$") {
        Initialize-V9Config
        return
    }
    
    # Open HTML console
    if ($inputText -match "^html$|^console$|^open$") {
        Open-HTMLConsole
        return
    }
    
    # Default: Open HTML console for any unrecognized command
    Write-Host "🌐 Unknown command: $UserInput" -ForegroundColor Yellow
    Write-Host "   Opening HTML console for advanced features..." -ForegroundColor Cyan
    Open-HTMLConsole
}

function Open-HTMLConsole {
    <#
    .SYNOPSIS
        Opens html_console_v9.html in the default browser
    #>
    
    $htmlPath = Join-Path $PSScriptRoot "html_console_v9.html"
    
    if (-not (Test-Path $htmlPath)) {
        Write-Host "❌ HTML console not found: $htmlPath" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🌐 Opening HTML Console..." -ForegroundColor Cyan
    
    try {
        if ($IsMacOS) {
            # Use open with quoted path to handle spaces
            Start-Process "open" -ArgumentList "`"$htmlPath`""
        } elseif ($IsLinux) {
            Start-Process "xdg-open" -ArgumentList "`"$htmlPath`""
        } else {
            # Windows
            Start-Process "`"$htmlPath`""
        }
        Write-Host "✅ HTML console opened in browser" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to open HTML console: $_" -ForegroundColor Red
        Write-Host "   Path: $htmlPath" -ForegroundColor Yellow
    }
}

function Show-Help {
    Write-Host "`n📚 Available Commands" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Task Management:" -ForegroundColor Yellow
    Write-Host "  siva|vipul|peter|sameet|sharanya|divya" -ForegroundColor White
    Write-Host "    → Add or modify tasks for a person" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Capacity & Availability:" -ForegroundColor Yellow
    Write-Host "  capacity <name>" -ForegroundColor White
    Write-Host "    → Show weekly capacity for a person" -ForegroundColor Gray
    Write-Host "    Example: capacity vipul" -ForegroundColor DarkGray
    Write-Host "  availability" -ForegroundColor White
    Write-Host "    → Show who is most available today" -ForegroundColor Gray
    Write-Host ""
    Write-Host "System:" -ForegroundColor Yellow
    Write-Host "  html | console | open" -ForegroundColor White
    Write-Host "    → Open html_console_v9.html in browser" -ForegroundColor Gray
    Write-Host "  reload" -ForegroundColor White
    Write-Host "    → Reload config from Downloads" -ForegroundColor Gray
    Write-Host "  help" -ForegroundColor White
    Write-Host "    → Show this help" -ForegroundColor Gray
    Write-Host "  exit" -ForegroundColor White
    Write-Host "    → Exit helper" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Tip: Any unrecognized command will open the HTML console" -ForegroundColor DarkGray
    Write-Host ""
}

function Start-InteractiveMode {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  PowerShell Helper for html_console_v9.html  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize V9 config
    if (-not (Initialize-V9Config)) {
        Write-Host "`nCannot start without V9 config. Exiting." -ForegroundColor Red
        return
    }
    
    Write-Host "`nType 'help' for available commands or 'exit' to quit`n" -ForegroundColor Gray
    
    do {
        Write-Host "helper2> " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host
        
        if ($userInput -eq "exit") {
            Write-Host "Goodbye! 👋" -ForegroundColor Cyan
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            continue
        }
        
        try {
            Invoke-Command -UserInput $userInput
        } catch {
            Write-Host "❌ Error: $_" -ForegroundColor Red
        }
        
        Write-Host ""
    } while ($true)
}

#endregion

# Start the interactive mode
Start-InteractiveMode
