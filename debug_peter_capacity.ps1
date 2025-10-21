# Debug Peter's capacity calculation

# Load the adapter
. "$PSScriptRoot/v9_csv_adapter_v2.ps1"

# Read config
$config = Read-V9ConfigFile -FilePath "$PSScriptRoot/Output/project_config_2025-10-21_13-27-17.csv"

# Get Peter's tasks
$peterTasks = $config.Tickets | Where-Object { $_.AssignedTeam -eq 'Peter' }

Write-Host "🔍 Peter's Tasks in Config:"
Write-Host ""
foreach ($task in $peterTasks) {
    Write-Host "Task $($task.ID): $($task.Description)"
    Write-Host "  Size: $($task.Size) | Priority: $($task.Priority) | Type: $($task.TaskType)"
    Write-Host "  Start: $($task.StartDate) | End: $($task.EndDate)"
    Write-Host ""
}

# Calculate size in hours
$hoursPerDay = 8
$sizeMap = @{
    'XS' = 0.5 * $hoursPerDay
    'S' = 1 * $hoursPerDay
    'M' = 3 * $hoursPerDay
    'L' = 5 * $hoursPerDay
    'XL' = 8 * $hoursPerDay
}

Write-Host "📊 Task Hours Breakdown:"
Write-Host ""
$totalFixed = 0
$totalFlexible = 0

foreach ($task in $peterTasks) {
    $hours = $sizeMap[$task.Size]
    $type = $task.TaskType
    
    Write-Host "Task $($task.ID): $hours hours ($type)"
    
    if ($type -eq 'Fixed') {
        $totalFixed += $hours
    } else {
        $totalFlexible += $hours
    }
}

Write-Host ""
Write-Host "💡 Summary:"
Write-Host "  Fixed tasks: $totalFixed hours"
Write-Host "  Flexible tasks: $totalFlexible hours (excluded from capacity)"
Write-Host "  Total for capacity: $totalFixed hours"
Write-Host ""
Write-Host "📅 Week 1 (Oct 20-24, 2025):"
Write-Host "  Available: 25 hours/week"
Write-Host "  Allocated (Fixed only): $totalFixed hours"
Write-Host "  Utilization: $([Math]::Round(($totalFixed / 25) * 100))%"
Write-Host ""
Write-Host "🤔 Question: Is PowerShell counting the FULL task size or just Week 1's portion?"
