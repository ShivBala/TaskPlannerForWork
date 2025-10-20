. ./helper2.ps1
Initialize-V9Config

# Get Task 21
$task21 = $global:V9Config.Tickets | Where-Object { $_.ID -eq 21 }
Write-Host '=== Task 21 Details ===' -ForegroundColor Cyan
Write-Host "Description: $($task21.Description)"
Write-Host "Start: $($task21.StartDate)"
Write-Host "Size: $($task21.Size)"
Write-Host "Team: $($task21.AssignedTeam -join ';')"

# Calculate baseline
$earliestTaskDate = ($global:V9Config.Tickets | Sort-Object { [datetime]$_.StartDate } | Select-Object -First 1).StartDate
$earliestTaskDate = [datetime]$earliestTaskDate
$dayOfWeek = [int]$earliestTaskDate.DayOfWeek
$daysFromMonday = if ($dayOfWeek -eq 0) { 6 } else { $dayOfWeek - 1 }
$baselineDate = $earliestTaskDate.AddDays(-$daysFromMonday).Date

Write-Host "`n=== Week Boundaries ===" -ForegroundColor Cyan
Write-Host "Baseline (Week 1 start): $($baselineDate.ToString('yyyy-MM-dd'))"
$week2Start = $baselineDate.AddDays(7)
$week2End = $week2Start.AddDays(6)
Write-Host "Week 2: $($week2Start.ToString('yyyy-MM-dd')) to $($week2End.ToString('yyyy-MM-dd'))"
$week3Start = $baselineDate.AddDays(14)
$week3End = $week3Start.AddDays(6)
Write-Host "Week 3: $($week3Start.ToString('yyyy-MM-dd')) to $($week3End.ToString('yyyy-MM-dd'))"

# Calculate task effort
$sizeDays = 8  # XL
$hoursPerDay = 8
$teamSize = 2
$personTotalEffort = ($sizeDays * $hoursPerDay) / $teamSize
$taskStart = [datetime]$task21.StartDate
$taskEnd = $taskStart.AddDays(10)  # Rough estimate
$taskDurationDays = 8  # business days
$dailyRate = $personTotalEffort / $taskDurationDays

Write-Host "`n=== Task 21 Effort ===" -ForegroundColor Cyan
Write-Host "Total effort per person: $personTotalEffort hours"
Write-Host "Daily rate: $dailyRate hours/day"
Write-Host "Task starts: $($taskStart.ToString('yyyy-MM-dd'))"
Write-Host "Task ends (approx): $($taskEnd.ToString('yyyy-MM-dd'))"

# Check Week 2 overlap
Write-Host "`n=== Week 2 Overlap ===" -ForegroundColor Yellow
if ($taskStart -le $week2End -and $taskEnd -ge $week2Start) {
    Write-Host "✓ Task overlaps with Week 2"
    $overlapStart = if ($taskStart -gt $week2Start) { $taskStart } else { $week2Start }
    $overlapEnd = if ($taskEnd -lt $week2End) { $taskEnd } else { $week2End }
    Write-Host "Overlap range: $($overlapStart.ToString('yyyy-MM-dd')) to $($overlapEnd.ToString('yyyy-MM-dd'))"
    
    # Count business days
    $businessDays = 0
    $currentDay = $overlapStart
    while ($currentDay -le $overlapEnd) {
        if ($currentDay.DayOfWeek -ne [System.DayOfWeek]::Saturday -and 
            $currentDay.DayOfWeek -ne [System.DayOfWeek]::Sunday) {
            $businessDays++
            Write-Host "  $($currentDay.ToString('yyyy-MM-dd ddd'))"
        }
        $currentDay = $currentDay.AddDays(1)
    }
    Write-Host "Business days in Week 2: $businessDays"
    $week2Effort = $dailyRate * $businessDays
    Write-Host "Week 2 effort: $week2Effort hours"
}

# Check Week 3 overlap
Write-Host "`n=== Week 3 Overlap ===" -ForegroundColor Yellow
if ($taskStart -le $week3End -and $taskEnd -ge $week3Start) {
    Write-Host "✓ Task overlaps with Week 3"
    $overlapStart = if ($taskStart -gt $week3Start) { $taskStart } else { $week3Start }
    $overlapEnd = if ($taskEnd -lt $week3End) { $taskEnd } else { $week3End }
    Write-Host "Overlap range: $($overlapStart.ToString('yyyy-MM-dd')) to $($overlapEnd.ToString('yyyy-MM-dd'))"
    
    # Count business days
    $businessDays = 0
    $currentDay = $overlapStart
    while ($currentDay -le $overlapEnd) {
        if ($currentDay.DayOfWeek -ne [System.DayOfWeek]::Saturday -and 
            $currentDay.DayOfWeek -ne [System.DayOfWeek]::Sunday) {
            $businessDays++
            Write-Host "  $($currentDay.ToString('yyyy-MM-dd ddd'))"
        }
        $currentDay = $currentDay.AddDays(1)
    }
    Write-Host "Business days in Week 3: $businessDays"
    $week3Effort = $dailyRate * $businessDays
    Write-Host "Week 3 effort: $week3Effort hours"
}
