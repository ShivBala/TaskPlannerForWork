# Simple test using helper2.ps1

. "$PSScriptRoot/helper2.ps1"

# Load config
Load-Config -FilePath "$PSScriptRoot/Output/project_config_2025-10-21_13-27-17.csv"

# Generate summary for Peter, Week 1
PersonSummary -PersonName "Peter" -BaselineDate ([datetime]"2025-10-20")

Write-Host ""
Write-Host "🔍 Check the generated HTML report"
Write-Host "Expected: ~32% capacity (8h / 25h)"
Write-Host "  Task 2 starts Oct 24 (Friday) = only 1 business day in Week 1"
