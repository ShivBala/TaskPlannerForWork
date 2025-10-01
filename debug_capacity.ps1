# Debug script for capacity planning
. ./helper.ps1

Write-Host "Loading data..." -ForegroundColor Yellow
$Tasks = Import-Csv './task_progress_data.csv'
$People = Import-Csv './people_and_capacity.csv'

Write-Host "Tasks count: $($Tasks.Count)" -ForegroundColor Green
Write-Host "People count: $($People.Count)" -ForegroundColor Green

Write-Host "First person: $($People[0].Name)" -ForegroundColor Green

# Test week calculation
$CurrentDate = Get-Date
$DaysFromMonday = ([int]$CurrentDate.DayOfWeek + 6) % 7
$CurrentWeekStart = $CurrentDate.AddDays(-$DaysFromMonday).Date

$Week1Start = $CurrentWeekStart
$Week1End = $CurrentWeekStart.AddDays(6)
$Week5Start = $CurrentWeekStart.AddDays(28)
$Week5End = $CurrentWeekStart.AddDays(34)

Write-Host "Week 1: $($Week1Start.ToString('yyyy-MM-dd')) to $($Week1End.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
Write-Host "Week 5: $($Week5Start.ToString('yyyy-MM-dd')) to $($Week5End.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

# Test function call
Write-Host "Testing Calculate-PersonCapacity function..." -ForegroundColor Yellow
try {
    $PersonCapacity = Calculate-PersonCapacity -Person $People[0] -Tasks $Tasks `
        -Week1Start $Week1Start -Week1End $Week1End `
        -Week2Start $CurrentWeekStart.AddDays(7) -Week2End $CurrentWeekStart.AddDays(13) `
        -Week3Start $CurrentWeekStart.AddDays(14) -Week3End $CurrentWeekStart.AddDays(20) `
        -Week4Start $CurrentWeekStart.AddDays(21) -Week4End $CurrentWeekStart.AddDays(27) `
        -Week5Start $Week5Start -Week5End $Week5End
    
    Write-Host "Function succeeded!" -ForegroundColor Green
    Write-Host "Person: $($PersonCapacity.Name)" -ForegroundColor Green
    Write-Host "Week5 Available: $($PersonCapacity.Week5Available)" -ForegroundColor Green
} catch {
    Write-Host "Function failed: $($_.Exception.Message)" -ForegroundColor Red
}