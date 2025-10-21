# Person Summary Module
# Generates HTML reports with person's weekly task summary

function Get-NextBusinessDay {
    param([DateTime]$Date)
    
    $result = $Date.Date
    $dayOfWeek = [int]$result.DayOfWeek
    
    if ($dayOfWeek -eq 0) {  # Sunday
        $result = $result.AddDays(1)  # Move to Monday
    } elseif ($dayOfWeek -eq 6) {  # Saturday
        $result = $result.AddDays(2)  # Move to Monday
    }
    
    return $result
}

function Add-BusinessDays {
    param(
        [DateTime]$StartDate,
        [int]$BusinessDaysToAdd
    )
    
    if ($BusinessDaysToAdd -eq 7) {
        Add-Content -Path "debug_filter.txt" -Value "  >>> Add-BusinessDays START: $($StartDate.ToString('yyyy-MM-dd')), ToAdd: $BusinessDaysToAdd"
    }
    
    $result = $StartDate.Date
    $daysAdded = 0
    
    while ($daysAdded -lt $BusinessDaysToAdd) {
        $result = $result.AddDays(1)
        $dayOfWeek = [int]$result.DayOfWeek
        if ($BusinessDaysToAdd -eq 7) {
            Add-Content -Path "debug_filter.txt" -Value "  >>> Loop: result=$($result.ToString('yyyy-MM-dd')), dayOfWeek=$dayOfWeek, daysAdded=$daysAdded"
        }
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) {  # Monday to Friday
            $daysAdded++
        }
    }
    
    if ($BusinessDaysToAdd -eq 7) {
        Add-Content -Path "debug_filter.txt" -Value "  >>> Add-BusinessDays END: $($result.ToString('yyyy-MM-dd'))"
    }
    
    return $result
}

function Calculate-TaskEndDate {
    param(
        [DateTime]$StartDate,
        [double]$TaskDurationDays,
        [bool]$IsFixedLength = $true,
        [int]$AssigneeCount = 1
    )
    
    Add-Content -Path "debug_filter.txt" -Value "  >> Calculate-TaskEndDate called: Start=$($StartDate.ToString('yyyy-MM-dd')), Duration=$TaskDurationDays"
    
    # Move start date to next business day if it falls on a weekend
    $taskStartDate = Get-NextBusinessDay -Date $StartDate
    
    # Calculate business days needed
    if ($IsFixedLength) {
        # Fixed-Length: Duration stays constant regardless of assignees
        $businessDaysNeeded = [Math]::Ceiling($TaskDurationDays)
    } else {
        # Flexible: Duration splits among assignees
        $daysPerPerson = $TaskDurationDays / [Math]::Max($AssigneeCount, 1)
        $businessDaysNeeded = [Math]::Ceiling($daysPerPerson)
    }
    
    # DEBUG
    $global:DebugLastCalc = @{
        StartDate = $StartDate
        TaskStartDate = $taskStartDate
        TaskDurationDays = $TaskDurationDays
        BusinessDaysNeeded = $businessDaysNeeded
        IsFixedLength = $IsFixedLength
        AssigneeCount = $AssigneeCount
    }
    
    # Calculate end date
    # Subtract 1 because the start date counts as day 1 of the task
    $daysToAdd = $businessDaysNeeded - 1
    Add-Content -Path "debug_filter.txt" -Value "  >> About to call Add-BusinessDays: taskStartDate=$($taskStartDate.ToString('yyyy-MM-dd')), daysToAdd=$daysToAdd"
    $endDate = Add-BusinessDays -StartDate $taskStartDate -Days $daysToAdd
    Add-Content -Path "debug_filter.txt" -Value "  >> Add-BusinessDays returned: $($endDate.ToString('yyyy-MM-dd'))"
    
    $global:DebugLastCalc.EndDate = $endDate
    
    return $endDate
}

function Show-PersonSummary {
    <#
    .SYNOPSIS
        Generates an HTML report showing a person's weekly work summary
    
    .DESCRIPTION
        Creates a detailed HTML page with:
        - Person's weekly capacity and utilization
        - All tasks assigned for the current week
        - Task details (priority, size, dates, stakeholder, initiative)
        - Quick summary text that can be copied to clipboard
    
    .PARAMETER PersonName
        Name of the person to generate summary for
    
    .EXAMPLE
        Show-PersonSummary -PersonName "Sarah"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PersonName
    )
    
    if ($null -eq $global:V9Config) {
        Write-Host "❌ Config not loaded" -ForegroundColor Red
        return
    }
    
    # Find person (case-insensitive)
    $person = $global:V9Config.People | Where-Object { 
        $_.Name -like "*$PersonName*" 
    } | Select-Object -First 1
    
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    Write-Host "`n📊 Generating summary for $($person.Name)..." -ForegroundColor Cyan
    
    # Check if we have tickets data
    if ($null -eq $global:V9Config.Tickets -or $global:V9Config.Tickets.Count -eq 0) {
        Write-Host "⚠️  No tasks found in configuration" -ForegroundColor Yellow
        Write-Host "   Please ensure you have loaded a project configuration file with tasks." -ForegroundColor Gray
        return
    }
    
    # Calculate heat map baseline date (Monday of earliest task) - matches HTML logic
    $earliestTaskDate = $null
    foreach ($task in $global:V9Config.Tickets) {
        if ($task.StartDate) {
            $taskDate = [datetime]$task.StartDate
            # Adjust weekend starts to next Monday
            $adjustedDate = Get-NextBusinessDay -Date $taskDate
            if ($null -eq $earliestTaskDate -or $adjustedDate -lt $earliestTaskDate) {
                $earliestTaskDate = $adjustedDate
            }
        }
    }
    
    # Find the Monday of the week containing the earliest task
    $baselineDate = if ($earliestTaskDate) {
        $dayOfWeek = [int]$earliestTaskDate.DayOfWeek
        $daysFromMonday = if ($dayOfWeek -eq 0) { 6 } else { $dayOfWeek - 1 }
        $earliestTaskDate.AddDays(-$daysFromMonday).Date
    } else {
        # Fallback to current Monday
        $today = Get-Date
        $dayOfWeek = [int]$today.DayOfWeek
        $daysFromMonday = if ($dayOfWeek -eq 0) { 6 } else { $dayOfWeek - 1 }
        $today.AddDays(-$daysFromMonday).Date
    }
    
    # Calculate current week index from baseline
    $today = Get-Date
    $daysSinceBaseline = ($today.Date - $baselineDate).Days
    $currentWeekIndex = [Math]::Floor($daysSinceBaseline / 7)
    
    # Calculate current week range (Monday to Friday only - matches HTML)
    $startOfWeek = $baselineDate.AddDays($currentWeekIndex * 7)  # Monday
    $endOfWeek = $startOfWeek.AddDays(4).AddHours(23).AddMinutes(59).AddSeconds(59)  # Friday 23:59
    
    # Get tasks for this person in current week
    # Note: AssignedTeam can be either a string (semicolon-separated) or an array
    $currentWeekTasks = $global:V9Config.Tickets | Where-Object {
        # Check if person is assigned to this task
        $isAssigned = if ($_.AssignedTeam -is [array]) {
            # V10 format: array of names
            $_.AssignedTeam -contains $person.Name
        } else {
            # V9 format: semicolon-separated string
            $_.AssignedTeam -eq $person.Name -or $_.AssignedTeam -like "*$($person.Name)*"
        }
        
        if (-not $isAssigned) {
            return $false
        }
        if ($_.Status -eq 'Done') {
            return $false
        }
        if (-not $_.StartDate) {
            return $false
        }
        
        $taskStart = [datetime]$_.StartDate
        
        # Calculate end date using HTML's logic (business days)
        if ($_.ID -eq 21) {
            $endDateType = if ($_.EndDate) { $_.EndDate.GetType().Name } else { "null" }
            $global:DebugTask21EndDate = "EndDate field: [$($_.EndDate)] Type: $endDateType Empty: $([string]::IsNullOrEmpty($_.EndDate)) Whitespace: $([string]::IsNullOrWhiteSpace($_.EndDate))"
        }
        
        $hasValidEndDate = $false
        if ($_.EndDate) {
            $trimmed = "$($_.EndDate)".Trim()
            if ($trimmed -ne "") {
                $hasValidEndDate = $true
            }
        }
        
        if ($_.ID -eq 21) {
            Add-Content -Path "debug_filter.txt" -Value "  hasValidEndDate: $hasValidEndDate"
        }
        
        $taskEnd = if ($hasValidEndDate) {
            if ($_.ID -eq 21) { Add-Content -Path "debug_filter.txt" -Value "  Taking EndDate branch" }
            [datetime]$_.EndDate
        } else {
            if ($_.ID -eq 21) { Add-Content -Path "debug_filter.txt" -Value "  Taking Calculate branch" }
            # Get task duration in business days based on size
            $durationDays = switch ($_.Size) {
                'XS' { 0.5 }
                'S' { 1 }
                'M' { 3 }
                'L' { 5 }
                'XL' { 8 }
                'XXL' { 15 }
                default { 3 }
            }
            
            # Get number of assignees for this task
            $assignees = if ($_.AssignedTeam) {
                if ($_.AssignedTeam -is [array]) {
                    # V10 format: already an array
                    @($_.AssignedTeam | Where-Object { $_ -and $_.Trim() })
                } else {
                    # V9 format: semicolon-separated string
                    @($_.AssignedTeam -split ';' | Where-Object { $_ -and $_.Trim() })
                }
            } else {
                @()
            }
            $assigneeCount = [Math]::Max($assignees.Count, 1)
            
            # Use HTML's calculation logic (fixed-length = true)
            Calculate-TaskEndDate -StartDate $taskStart -TaskDurationDays $durationDays -IsFixedLength $true -AssigneeCount $assigneeCount
        }
        
        # Check if task overlaps with current week
        $overlaps = ($taskStart -le $endOfWeek) -and ($taskEnd -ge $startOfWeek)
        
        # DEBUG
        if ($_.ID -eq 21) {
            $calc = $global:DebugLastCalc
            $debugLog = @"
🔍 FILTER Task 21:
  $($global:DebugTask21EndDate)
  Size: $($_.Size)
  DurationDays: $durationDays
  Assignees: $assigneeCount
  BusinessDaysNeeded: $($calc.BusinessDaysNeeded)
  Start: $($taskStart.ToString('yyyy-MM-dd'))
  TaskStartDate (after weekend check): $($calc.TaskStartDate.ToString('yyyy-MM-dd'))
  Add-BusinessDays: $($global:DebugAddBizDays)
  End: $($taskEnd.ToString('yyyy-MM-dd'))
  Week: $($startOfWeek.ToString('yyyy-MM-dd')) to $($endOfWeek.ToString('yyyy-MM-dd'))
  Overlaps: $overlaps
"@
            Add-Content -Path "debug_filter.txt" -Value $debugLog
        }
        
        return $overlaps
    }
    
    # Calculate effort and capacity
    $hoursPerDay = if ($global:ProjectHoursPerDay) { $global:ProjectHoursPerDay } else { 8 }
    $availability = if ($person.Availability) { 
        # Handle if Availability is an array (use current week index) or scalar
        $avail = if ($person.Availability -is [array]) { 
            # Use the week index calculated earlier to get the correct week's availability
            $weekIdx = [Math]::Max(0, [Math]::Min($currentWeekIndex, $person.Availability.Count - 1))
            $person.Availability[$weekIdx] 
        } else { 
            $person.Availability 
        }
        [double]$avail
    } else { 
        40.0 
    }
    
    $totalEffort = 0
    $taskDetails = @()
    
    foreach ($task in $currentWeekTasks) {
        # Calculate size in hours
        $sizeDays = switch ($task.Size) {
            'XS' { 0.5 }
            'S' { 1 }
            'M' { 3 }
            'L' { 5 }
            'XL' { 8 }
            default { 3 }
        }
        
        $sizeHours = $sizeDays * $hoursPerDay
        
        # Get team size for this task (AssignedTeam can have multiple people separated by semicolons)
        $assignedPeople = if ($task.AssignedTeam) { 
            ($task.AssignedTeam -split ';').Count 
        } else { 
            1 
        }
        $teamSize = $assignedPeople
        
        # Calculate task end date and duration
        $taskStart = [datetime]$task.StartDate
        # Adjust start date to next business day if it's a weekend
        $taskStartAdjusted = Get-NextBusinessDay -Date $taskStart
        $taskEnd = if ($task.EndDate) {
            [datetime]$task.EndDate
        } else {
            Calculate-TaskEndDate -StartDate $taskStart -TaskDurationDays $sizeDays
        }
        
        # Count total business days task spans (task duration)
        # Use adjusted start date for counting business days
        $taskDurationDays = 0
        $currentDay = $taskStartAdjusted
        while ($currentDay -le $taskEnd) {
            if ($currentDay.DayOfWeek -ne [System.DayOfWeek]::Saturday -and 
                $currentDay.DayOfWeek -ne [System.DayOfWeek]::Sunday) {
                $taskDurationDays++
            }
            $currentDay = $currentDay.AddDays(1)
        }
        
        # HTML's heat map formula for FIXED-LENGTH tasks:
        # Capacity per Person = (Task Size × Base Hours) ÷ Number of Assignees ÷ Task Duration
        # This gives us the daily rate for this person
        $dailyRate = if ($taskDurationDays -gt 0 -and $teamSize -gt 0) {
            ($sizeDays * $hoursPerDay) / $teamSize / $taskDurationDays
        } else {
            0
        }
        
        # Total effort for this person on this task
        $personTotalEffort = ($sizeDays * $hoursPerDay) / $teamSize
        
        # Track effort remaining across weeks (like HTML does)
        # Calculate how much effort was already allocated to previous weeks
        $effortRemaining = $personTotalEffort
        
        # DEBUG
        if ($task.ID -in @(6, 21)) {
            $debugLog = @"
🔍 DEBUG Task $($task.ID): $($task.Description)
  Total effort: $personTotalEffort, Daily rate: $dailyRate
  Task (raw): $($taskStart.ToString('yyyy-MM-dd')) to $($taskEnd.ToString('yyyy-MM-dd'))
  Task (adjusted): $($taskStartAdjusted.ToString('yyyy-MM-dd')) to $($taskEnd.ToString('yyyy-MM-dd'))
  Current week: $($startOfWeek.ToString('yyyy-MM-dd')) to $($endOfWeek.ToString('yyyy-MM-dd'))
  Baseline: $($baselineDate.ToString('yyyy-MM-dd'))
"@
            Add-Content -Path "debug_task21.txt" -Value $debugLog
        }
        
        # Go through each baseline week before the current week
        # Start from the baseline Monday (Week 1 start)
        $checkWeekStart = $baselineDate
        while ($checkWeekStart -lt $startOfWeek) {
            $checkWeekEnd = $checkWeekStart.AddDays(6)  # Sunday of that week
            
            # Check if task overlaps with this previous week
            # Use adjusted start date (not raw start date from CSV)
            if ($taskStartAdjusted -le $checkWeekEnd -and $taskEnd -ge $checkWeekStart) {
                # HTML always uses 5 business days (full work week) regardless of overlap
                # Subtract the effort allocated to that previous week
                $prevWeekEffort = [math]::Min($effortRemaining, $dailyRate * 5)
                $effortRemaining -= $prevWeekEffort
                
                # DEBUG
                if ($task.ID -in @(6, 21)) {
                    Add-Content -Path "debug_task21.txt" -Value "  Week $($checkWeekStart.ToString('yyyy-MM-dd')): Allocated $prevWeekEffort, Remaining: $effortRemaining"
                }
            }
            
            $checkWeekStart = $checkWeekStart.AddDays(7)
        }
        
        # HTML's weekly allocation logic: Always use 5 business days (full work week)
        # regardless of when the task starts or ends within the week
        # Weekly effort = Min(effortRemaining, daily rate × 5)
        # This matches HTML's logic: hoursThisWeek = Math.min(effortRemaining, dailyHours × 5)
        $calculatedEffort = $dailyRate * 5  # Always 5 business days per week
        $personEffort = [math]::Round([math]::Min($effortRemaining, $calculatedEffort), 1)
        
        # DEBUG
        if ($task.ID -in @(6, 21)) {
            Add-Content -Path "debug_task21.txt" -Value "  This week effort: $personEffort`n"
        }
        
        $totalEffort += $personEffort
        
        $taskDetails += [PSCustomObject]@{
            Description = $task.Description
            Priority = $task.Priority
            Size = $task.Size
            Status = $task.Status
            StartDate = $task.StartDate
            EndDate = $task.EndDate
            Initiative = if ($task.Initiative) { $task.Initiative } else { "General" }
            Stakeholder = if ($task.Stakeholder) { $task.Stakeholder } else { "N/A" }
            SizeDays = $sizeDays
            TotalEffort = $sizeHours
            PersonEffort = $personEffort
            TeamSize = $teamSize
        }
    }
    
    $utilization = if ($availability -gt 0) { 
        [math]::Round(($totalEffort / $availability) * 100, 0) 
    } else { 
        0 
    }
    
    # Generate quick summary for clipboard
    $quickSummary = if ($currentWeekTasks.Count -eq 0) {
        "$($person.Name) - No active tasks this week. Available: $availability hours."
    } else {
        $p1Count = ($taskDetails | Where-Object { $_.Priority -eq 'P1' }).Count
        $priorityText = if ($p1Count -gt 0) { " ($p1Count high priority)" } else { "" }
        
        # Get unique initiatives and stakeholders
        $initiatives = ($taskDetails | Select-Object -ExpandProperty Initiative -Unique | Where-Object { $_ -and $_ -ne 'General' }) -join ', '
        $stakeholders = ($taskDetails | Select-Object -ExpandProperty Stakeholder -Unique | Where-Object { $_ -and $_ -ne 'N/A' }) -join ', '
        
        # Build detailed summary
        $summaryParts = @()
        $summaryParts += "$($person.Name) has $($currentWeekTasks.Count) task(s)$priorityText for week of $($startOfWeek.ToString('MMM dd, yyyy'))"
        $summaryParts += "Workload: $totalEffort/$availability hours ($utilization% capacity)"
        
        if ($initiatives) {
            $summaryParts += "Initiatives: $initiatives"
        }
        
        if ($stakeholders) {
            $summaryParts += "Stakeholders: $stakeholders"
        }
        
        # Add task breakdown
        $summaryParts += "`nTasks:"
        foreach ($task in $taskDetails) {
            $summaryParts += "  • $($task.Priority) - $($task.Description) ($([math]::Round($task.PersonEffort, 1))h)"
        }
        
        $summaryParts -join "`n"
    }
    
    # Pre-process clipboard text for JavaScript (avoid backtick-dollar syntax issues)
    $clipboardText = $quickSummary.Replace("`n", "\n").Replace("`r", "").Replace('"', '\"').Replace("'", "\'")
    
    # Create "html reports" directory if it doesn't exist
    $reportsDir = Join-Path $PSScriptRoot "html reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    # Generate HTML
    $htmlPath = Join-Path $reportsDir "person_summary_$($person.Name -replace '\s+', '_').html"
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Work Summary - $($person.Name)</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #2d3748;
            background: #f7fafc;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #1e3a5f 0%, #2c5282 100%);
            color: white;
            padding: 30px;
            border-bottom: 3px solid #1a365d;
        }
        .header h1 {
            font-size: 1.8em;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .header h2 {
            font-size: 1.3em;
            font-weight: 400;
            opacity: 0.95;
        }
        .header .date {
            font-size: 0.9em;
            opacity: 0.85;
            margin-top: 10px;
        }
        .content {
            padding: 30px;
        }
        .section {
            margin-bottom: 30px;
        }
        .section-title {
            font-size: 1.1em;
            font-weight: 600;
            color: #1e3a5f;
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 2px solid #e2e8f0;
        }
        .summary-text {
            line-height: 1.8;
            color: #4a5568;
            font-size: 0.95em;
            text-align: justify;
        }
        .capacity-section {
            background: #f8fafc;
            padding: 20px;
            border-radius: 4px;
            border: 1px solid #e2e8f0;
        }
        .capacity-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 0.95em;
        }
        .capacity-label {
            font-weight: 600;
            color: #2d3748;
        }
        .capacity-value {
            color: #4a5568;
        }
        .meter {
            margin-top: 15px;
        }
        .meter-label {
            font-size: 0.85em;
            color: #718096;
            margin-bottom: 5px;
        }
        .meter-bar {
            height: 30px;
            background: #e2e8f0;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }
        .meter-fill {
            height: 100%;
            background: linear-gradient(90deg, #48bb78 0%, #38a169 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 0.9em;
            transition: width 0.3s ease;
        }
        .meter-fill.medium {
            background: linear-gradient(90deg, #ed8936 0%, #dd6b20 100%);
        }
        .meter-fill.high {
            background: linear-gradient(90deg, #f56565 0%, #e53e3e 100%);
        }
        .task-list {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        .task-card {
            border: 1px solid #e2e8f0;
            border-radius: 4px;
            padding: 15px;
            background: #ffffff;
            transition: all 0.2s ease;
        }
        .task-card:hover {
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }
        .task-header {
            display: flex;
            justify-content: space-between;
            align-items: start;
            margin-bottom: 12px;
        }
        .task-title {
            font-weight: 600;
            color: #2d3748;
            flex: 1;
            margin-right: 15px;
            font-size: 1em;
        }
        .task-badges {
            display: flex;
            gap: 6px;
            flex-shrink: 0;
        }
        .badge {
            padding: 3px 10px;
            border-radius: 3px;
            font-size: 0.75em;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-p1 { background: #feb2b2; color: #742a2a; }
        .badge-p2 { background: #fbd38d; color: #744210; }
        .badge-p3 { background: #9ae6b4; color: #22543d; }
        .badge-size { background: #cbd5e0; color: #2d3748; }
        .badge-status-todo { background: #bee3f8; color: #2c5282; }
        .badge-status-inprogress { background: #fbd38d; color: #744210; }
        .badge-status-done { background: #9ae6b4; color: #22543d; }
        .task-details {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            font-size: 0.9em;
            color: #4a5568;
        }
        .detail-row {
            display: flex;
            align-items: start;
        }
        .detail-label {
            font-weight: 600;
            margin-right: 8px;
            min-width: 100px;
            color: #2d3748;
        }
        .detail-value {
            color: #4a5568;
        }
        .effort-breakdown {
            margin-top: 10px;
            padding: 10px;
            background: white;
            border-radius: 3px;
            border-left: 3px solid #4299e1;
            font-size: 0.85em;
        }
        .no-tasks {
            text-align: center;
            padding: 60px 20px;
            color: #718096;
            background: #f8fafc;
            border-radius: 4px;
            border: 1px dashed #cbd5e0;
        }
        .no-tasks p:first-child {
            font-size: 1.2em;
            margin-bottom: 10px;
            color: #4a5568;
        }
        .copy-section {
            margin-top: 30px;
            padding: 20px;
            background: #f8fafc;
            border-radius: 4px;
            text-align: center;
        }
        .copy-button {
            background: #2c5282;
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 4px;
            font-size: 0.95em;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.2s ease;
        }
        .copy-button:hover {
            background: #1e3a5f;
        }
        .copy-button:active {
            transform: scale(0.98);
        }
        .copy-feedback {
            margin-top: 10px;
            color: #38a169;
            font-weight: 600;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .copy-feedback.show {
            opacity: 1;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #718096;
            font-size: 0.85em;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Weekly Work Summary</h1>
            <h2>$($person.Name)</h2>
            <div class="date">Week of $($startOfWeek.ToString('MMM dd')) - $($endOfWeek.ToString('MMM dd, yyyy'))</div>
        </div>
        
        <div class="content">
            <div class="section">
                <div class="section-title">Quick Summary</div>
                <div class="summary-text">
                    $quickSummary
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">Weekly Capacity</div>
                <div class="capacity-section">
                    <div class="capacity-row">
                        <span class="capacity-label">Available Hours:</span>
                        <span class="capacity-value">$availability hours/week</span>
                    </div>
                    <div class="capacity-row">
                        <span class="capacity-label">Allocated Hours:</span>
                        <span class="capacity-value">$totalEffort hours</span>
                    </div>
                    <div class="capacity-row">
                        <span class="capacity-label">Utilization:</span>
                        <span class="capacity-value">$utilization%</span>
                    </div>
                    <div class="meter">
                        <div class="meter-label">Capacity Utilization</div>
                        <div class="meter-bar">
                            <div class="meter-fill $(if ($utilization -gt 100) { 'high' } elseif ($utilization -gt 80) { 'medium' } else { '' })" style="width: $(if ($utilization -gt 100) { 100 } else { $utilization })%">
                                $utilization% ($totalEffort / $availability hours)
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">Task Assignments ($($currentWeekTasks.Count))</div>
"@
    
    if ($currentWeekTasks.Count -eq 0) {
        $html += @"
                <div class="no-tasks">
                    <p>No active tasks scheduled for this week</p>
                    <p>This resource is available for new assignments</p>
                </div>
"@
    } else {
        $html += @"
                <div class="task-list">
"@
        foreach ($task in $taskDetails) {
            $priorityClass = "badge-" + $task.Priority.ToLower()
            $statusClass = "badge-status-" + ($task.Status -replace '\s+', '').ToLower()
            $teamInfo = if ($task.TeamSize -gt 1) { " (shared with $($task.TeamSize - 1) other team member(s))" } else { "" }
            
            $html += @"
                    <div class="task-card">
                        <div class="task-header">
                            <div class="task-title">$($task.Description)</div>
                            <div class="task-badges">
                                <span class="badge $priorityClass">$($task.Priority)</span>
                                <span class="badge badge-size">$($task.Size)</span>
                                <span class="badge $statusClass">$($task.Status)</span>
                            </div>
                        </div>
                        <div class="task-details">
                            <div class="detail-row">
                                <span class="detail-label">Start Date:</span>
                                <span class="detail-value">$($task.StartDate)</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">End Date:</span>
                                <span class="detail-value">$($task.EndDate)</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">Initiative:</span>
                                <span class="detail-value">$($task.Initiative)</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">Stakeholder:</span>
                                <span class="detail-value">$($task.Stakeholder)</span>
                            </div>
                        </div>
                        <div class="effort-breakdown">
                            <strong>Effort Breakdown:</strong> Task size: $($task.Size) ($($task.SizeDays) days) = $($task.TotalEffort) hours total effort$teamInfo. 
                            <strong>This person's allocation: $($task.PersonEffort) hours</strong>
                        </div>
                    </div>
"@
        }
        $html += @"
                </div>
"@
    }
    
    $html += @"
            </div>
            
            <div class="copy-section">
                <button class="copy-button" onclick="copyToClipboard()">Copy Quick Summary to Clipboard</button>
                <div id="copy-feedback" class="copy-feedback">Summary copied to clipboard</div>
            </div>
        </div>
        
        <div class="footer">
            Generated by PowerShell Helper | html_console_v10.html
        </div>
    </div>
    
    <script>
        function copyToClipboard() {
            const summary = '$clipboardText';
            navigator.clipboard.writeText(summary).then(() => {
                const feedback = document.getElementById('copy-feedback');
                feedback.classList.add('show');
                setTimeout(() => {
                    feedback.classList.remove('show');
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy text: ', err);
                alert('Failed to copy to clipboard. Please copy manually.');
            });
        }
    </script>
</body>
</html>
"@
    
    # Write HTML file
    try {
        $html | Out-File -FilePath $htmlPath -Encoding UTF8 -Force
        Write-Host "✅ Summary generated: $htmlPath" -ForegroundColor Green
        
        # Open in browser - use Invoke-Item which handles spaces properly
        try {
            Invoke-Item $htmlPath
            Write-Host "🌐 Opening in browser..." -ForegroundColor Cyan
        } catch {
            Write-Host "⚠️  Could not auto-open browser. Please open manually:" -ForegroundColor Yellow
            Write-Host "   $htmlPath" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Failed to generate summary: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Note: Export-ModuleMember not needed when using dot-sourcing (. script.ps1)
