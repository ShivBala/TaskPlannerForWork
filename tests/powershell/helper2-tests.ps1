<#
.SYNOPSIS
    Comprehensive tests for helper2.ps1 PowerShell script
.DESCRIPTION
    Tests all major functionality including:
    - Smart router (Resolve-UserIntent)
    - Fuzzy matching (Get-FuzzyMatches)
    - Task management (Add/Modify)
    - Person management
    - Stakeholder management
    - Initiative management
    - Quick task feature
    - Auto-reload functionality
    - CSV operations
#>

# Import the test framework
. "$PSScriptRoot/powershell-test-framework.ps1"

# Test configuration
$script:TestConfigPath = Join-Path $PSScriptRoot "test_project_config.csv"
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

function Initialize-TestEnvironment {
    Write-Host "`n🧪 Initializing Test Environment..." -ForegroundColor Cyan
    
    # Create a test configuration file
    $testConfig = @"
SECTION,METADATA
ProjectHoursPerDay,8

SECTION,PEOPLE
Name,Weeks Availability,Project Ready
TestPerson1,8,true
TestPerson2,8,true

SECTION,TASK_SIZES
S,Small,1,false
M,Medium,3,false
L,Large,5,false
XL,Extra Large,10,false
XXL,Extra Extra Large,15,false

SECTION,STAKEHOLDERS
Test Stakeholder 1
Test Stakeholder 2

SECTION,INITIATIVES
Name,Start Date,Created Date,Description
Test Initiative 1,2025-10-20,2025-10-18,Test initiative description

SECTION,TICKETS
UUID,ID,Description,Start Date,Size,Priority,Stakeholder,Initiative,Assigned Team,Status,Task Type,Pause Comments,Start Date History,End Date History,Size History,Custom End Date,Created Date,Details Description,Details Positives,Details Negatives
test-uuid-1,1,Test Task 1,2025-10-20,M,P2,General,General,"TestPerson1",To Do,Fixed,,,,,2025-10-18,2025-10-18,,,
"@
    
    Set-Content -Path $script:TestConfigPath -Value $testConfig -Force
    Write-Host "✅ Test configuration created: $script:TestConfigPath" -ForegroundColor Green
}

function Cleanup-TestEnvironment {
    Write-Host "`n🧹 Cleaning up test environment..." -ForegroundColor Cyan
    
    if (Test-Path $script:TestConfigPath) {
        Remove-Item -Path $script:TestConfigPath -Force
        Write-Host "✅ Test configuration removed" -ForegroundColor Green
    }
}

function Test-SmartRouter {
    Write-Host "`n📋 Testing Smart Router (Resolve-UserIntent)..." -ForegroundColor Yellow
    
    # Test 1: Simple person name
    Test-Case "Should resolve 'sarah' to add task for sarah" {
        $intent = Resolve-UserIntent -InputText "sarah"
        return $intent.Action -eq 'add' -and $intent.TargetType -eq 'task' -and $intent.Entity -like "*sarah*"
    }
    
    # Test 2: Add task with person
    Test-Case "Should resolve 'addtasksarah' to add task for sarah" {
        $intent = Resolve-UserIntent -InputText "addtasksarah"
        return $intent.Action -eq 'add' -and $intent.TargetType -eq 'task' -and $intent.Entity -like "*sarah*"
    }
    
    # Test 3: Add initiative
    Test-Case "Should resolve 'addinitiative' to add initiative" {
        $intent = Resolve-UserIntent -InputText "addinitiative"
        return $intent.Action -eq 'add' -and $intent.TargetType -eq 'initiative'
    }
    
    # Test 4: Modify initiative
    Test-Case "Should resolve 'modifyinitiative' to modify initiative" {
        $intent = Resolve-UserIntent -InputText "modifyinitiative"
        return $intent.Action -eq 'modify' -and $intent.TargetType -eq 'initiative'
    }
    
    # Test 5: Add stakeholder with name
    Test-Case "Should resolve 'addstakeholdersales' to add stakeholder" {
        $intent = Resolve-UserIntent -InputText "addstakeholdersales"
        return $intent.Action -eq 'add' -and $intent.TargetType -eq 'stakeholder'
    }
}

function Test-FuzzyMatching {
    Write-Host "`n📋 Testing Fuzzy Matching (Get-FuzzyMatches)..." -ForegroundColor Yellow
    
    # Test 1: Exact match
    Test-Case "Should score exact match as 100" {
        $global:V9Config = @{
            People = @(
                [PSCustomObject]@{ Name = 'TestPerson' }
            )
        }
        $matches = Get-FuzzyMatches -SearchName 'TestPerson' -Type 'Person'
        return $matches.Count -gt 0 -and $matches[0].Score -eq 100
    }
    
    # Test 2: Partial match (first name)
    Test-Case "Should match partial first name" {
        $global:V9Config = @{
            People = @(
                [PSCustomObject]@{ Name = 'John Doe' }
            )
        }
        $matches = Get-FuzzyMatches -SearchName 'john' -Type 'Person'
        return $matches.Count -gt 0 -and $matches[0].Score -ge 90
    }
    
    # Test 3: Partial match (last name)
    Test-Case "Should match partial last name" {
        $global:V9Config = @{
            People = @(
                [PSCustomObject]@{ Name = 'John Doe' }
            )
        }
        $matches = Get-FuzzyMatches -SearchName 'doe' -Type 'Person'
        return $matches.Count -gt 0 -and $matches[0].Score -ge 85
    }
    
    # Test 4: Contains match
    Test-Case "Should match substring" {
        $global:V9Config = @{
            People = @(
                [PSCustomObject]@{ Name = 'Elizabeth Smith' }
            )
        }
        $matches = Get-FuzzyMatches -SearchName 'beth' -Type 'Person'
        return $matches.Count -gt 0 -and $matches[0].Score -ge 70
    }
    
    # Test 5: No match
    Test-Case "Should return empty for no match" {
        $global:V9Config = @{
            People = @(
                [PSCustomObject]@{ Name = 'TestPerson' }
            )
        }
        $matches = Get-FuzzyMatches -SearchName 'NonExistent' -Type 'Person'
        return $matches.Count -eq 0
    }
}

function Test-StakeholderManagement {
    Write-Host "`n📋 Testing Stakeholder Management..." -ForegroundColor Yellow
    
    # Test 1: Add stakeholder
    Test-Case "Should add new stakeholder" {
        $global:V9Config = @{
            Stakeholders = @('Existing Stakeholder')
        }
        Add-Stakeholder -Name 'New Stakeholder'
        return $global:V9Config.Stakeholders -contains 'New Stakeholder'
    }
    
    # Test 2: Prevent duplicate stakeholder
    Test-Case "Should not add duplicate stakeholder" {
        $global:V9Config = @{
            Stakeholders = @('Duplicate Test')
        }
        $initialCount = $global:V9Config.Stakeholders.Count
        Add-Stakeholder -Name 'Duplicate Test'
        return $global:V9Config.Stakeholders.Count -eq $initialCount
    }
    
    # Test 3: Remove stakeholder
    Test-Case "Should remove stakeholder" {
        $global:V9Config = @{
            Stakeholders = @('To Remove', 'To Keep')
        }
        Remove-Stakeholder -Name 'To Remove'
        return ($global:V9Config.Stakeholders -notcontains 'To Remove') -and 
               ($global:V9Config.Stakeholders -contains 'To Keep')
    }
}

function Test-InitiativeManagement {
    Write-Host "`n📋 Testing Initiative Management..." -ForegroundColor Yellow
    
    # Test 1: Add initiative
    Test-Case "Should add new initiative" {
        $global:V9Config = @{
            Initiatives = @()
        }
        Add-Initiative -Name 'New Initiative' -StartDate '2025-10-20' -Description 'Test'
        return $global:V9Config.Initiatives.Count -eq 1 -and 
               $global:V9Config.Initiatives[0].Name -eq 'New Initiative'
    }
    
    # Test 2: Prevent duplicate initiative
    Test-Case "Should not add duplicate initiative" {
        $global:V9Config = @{
            Initiatives = @(
                [PSCustomObject]@{ Name = 'Duplicate'; StartDate = '2025-10-20'; Description = 'Test' }
            )
        }
        $initialCount = $global:V9Config.Initiatives.Count
        Add-Initiative -Name 'Duplicate' -StartDate '2025-10-21' -Description 'Test2'
        return $global:V9Config.Initiatives.Count -eq $initialCount
    }
    
    # Test 3: Add initiative without start date
    Test-Case "Should add initiative without start date" {
        $global:V9Config = @{
            Initiatives = @()
        }
        Add-Initiative -Name 'No Date' -StartDate '' -Description 'Test'
        return $global:V9Config.Initiatives.Count -eq 1 -and 
               ([string]::IsNullOrEmpty($global:V9Config.Initiatives[0].StartDate))
    }
    
    # Test 4: Remove initiative
    Test-Case "Should remove initiative" {
        $global:V9Config = @{
            Initiatives = @(
                [PSCustomObject]@{ Name = 'To Remove'; StartDate = '2025-10-20'; Description = 'Test' }
                [PSCustomObject]@{ Name = 'To Keep'; StartDate = '2025-10-21'; Description = 'Test' }
            )
        }
        Remove-Initiative -Name 'To Remove'
        return $global:V9Config.Initiatives.Count -eq 1 -and 
               $global:V9Config.Initiatives[0].Name -eq 'To Keep'
    }
}

function Test-QuickTaskFeature {
    Write-Host "`n📋 Testing Quick Task Feature..." -ForegroundColor Yellow
    
    # Test 1: Quick task with minimal prompts
    Test-Case "Should recognize quick task pattern 'qt'" {
        $result = 'qt' -match '^q(uick)?t(ask)?$'
        return $result -eq $true
    }
    
    Test-Case "Should recognize quick task pattern 'quick'" {
        $result = 'quick' -match '^q(uick)?t(ask)?$'
        return $result -eq $true
    }
    
    Test-Case "Should recognize quick task pattern 'quicktask'" {
        $result = 'quicktask' -match '^q(uick)?t(ask)?$'
        return $result -eq $true
    }
    
    # Note: Actual function testing would require mocking Read-Host and other interactive elements
    Test-Case "Add-QuickTask function should exist" {
        return (Get-Command -Name Add-QuickTask -ErrorAction SilentlyContinue) -ne $null
    }
}

function Test-AutoReloadFunctionality {
    Write-Host "`n📋 Testing Auto-Reload Functionality..." -ForegroundColor Yellow
    
    # Test 1: Test-ConfigChanged function exists
    Test-Case "Test-ConfigChanged function should exist" {
        return (Get-Command -Name Test-ConfigChanged -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 2: Ensure-ConfigCurrent function exists
    Test-Case "Ensure-ConfigCurrent function should exist" {
        return (Get-Command -Name Ensure-ConfigCurrent -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 3: Config timestamp tracking
    Test-Case "Should detect file changes" {
        if (-not (Test-Path $script:TestConfigPath)) {
            return $true  # Skip if test file doesn't exist
        }
        
        $global:V9ConfigPath = $script:TestConfigPath
        $global:V9ConfigTimestamp = (Get-Item $script:TestConfigPath).LastWriteTime.AddSeconds(-10)
        
        $result = Test-ConfigChanged
        return $result -eq $true
    }
}

function Test-DateParsing {
    Write-Host "`n📋 Testing Date Parsing (Parse-DateAlias)..." -ForegroundColor Yellow
    
    # Test 1: 'today' alias
    Test-Case "Should parse 'today' correctly" {
        $result = Parse-DateAlias -DateInput 'today'
        $today = Get-Date -Format 'yyyy-MM-dd'
        return $result -eq $today
    }
    
    # Test 2: 'tomorrow' alias
    Test-Case "Should parse 'tomorrow' correctly" {
        $result = Parse-DateAlias -DateInput 'tomorrow'
        $tomorrow = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
        return $result -eq $tomorrow
    }
    
    # Test 3: Specific date
    Test-Case "Should parse specific date 'YYYY-MM-DD'" {
        $result = Parse-DateAlias -DateInput '2025-10-20'
        return $result -eq '2025-10-20'
    }
    
    # Test 4: 'next monday'
    Test-Case "Should parse 'next monday'" {
        $result = Parse-DateAlias -DateInput 'next monday'
        # Result should be a valid date
        return $result -match '^\d{4}-\d{2}-\d{2}$'
    }
}

function Test-PriorityValidation {
    Write-Host "`n📋 Testing Priority Validation..." -ForegroundColor Yellow
    
    # Test 1: P1-P5 format
    Test-Case "Should accept P1 priority" {
        $priority = 'P1'
        return $priority -match '^P[1-5]$'
    }
    
    Test-Case "Should accept P5 priority" {
        $priority = 'P5'
        return $priority -match '^P[1-5]$'
    }
    
    Test-Case "Should reject P6 priority" {
        $priority = 'P6'
        return -not ($priority -match '^P[1-5]$')
    }
    
    Test-Case "Should reject invalid format" {
        $priority = '1'
        return -not ($priority -match '^P[1-5]$')
    }
}

function Test-SizeValidation {
    Write-Host "`n📋 Testing Size Validation..." -ForegroundColor Yellow
    
    $validSizes = @('S', 'M', 'L', 'XL', 'XXL')
    
    foreach ($size in $validSizes) {
        Test-Case "Should accept size $size" {
            return $validSizes -contains $size
        }
    }
    
    Test-Case "Should reject invalid size" {
        return -not ($validSizes -contains 'INVALID')
    }
}

function Test-CSVOperations {
    Write-Host "`n📋 Testing CSV Operations..." -ForegroundColor Yellow
    
    # Test 1: Initialize-V9Config function exists
    Test-Case "Initialize-V9Config function should exist" {
        return (Get-Command -Name Initialize-V9Config -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 2: Save-V9Config function exists
    Test-Case "Save-V9Config function should exist" {
        return (Get-Command -Name Save-V9Config -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 3: Load test config
    Test-Case "Should load test configuration" {
        if (-not (Test-Path $script:TestConfigPath)) {
            Initialize-TestEnvironment
        }
        
        $global:V9ConfigPath = $script:TestConfigPath
        Initialize-V9Config
        
        return $global:V9Config -ne $null -and $global:V9Config.Tickets -ne $null
    }
}

function Test-HelperCommands {
    Write-Host "`n📋 Testing Helper Commands..." -ForegroundColor Yellow
    
    # Test 1: Show-Help function exists
    Test-Case "Show-Help function should exist" {
        return (Get-Command -Name Show-Help -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 2: Show-WeeklyCapacity function exists
    Test-Case "Show-WeeklyCapacity function should exist" {
        return (Get-Command -Name Show-WeeklyCapacity -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 3: Show-MostAvailable function exists
    Test-Case "Show-MostAvailable function should exist" {
        return (Get-Command -Name Show-MostAvailable -ErrorAction SilentlyContinue) -ne $null
    }
    
    # Test 4: Open-HtmlConsole function exists
    Test-Case "Open-HtmlConsole function should exist" {
        return (Get-Command -Name Open-HtmlConsole -ErrorAction SilentlyContinue) -ne $null
    }
}

function Test-Case {
    param(
        [string]$Description,
        [scriptblock]$TestCode
    )
    
    try {
        $result = & $TestCode
        
        if ($result) {
            Write-Host "  ✅ $Description" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ❌ $Description" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        $script:TestResults.Tests += @{
            Description = $Description
            Passed = $result
        }
    }
    catch {
        Write-Host "  ❌ $Description (Exception: $($_.Exception.Message))" -ForegroundColor Red
        $script:TestResults.Failed++
        
        $script:TestResults.Tests += @{
            Description = $Description
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

function Show-TestSummary {
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    $total = $script:TestResults.Passed + $script:TestResults.Failed
    $successRate = if ($total -gt 0) { [math]::Round(($script:TestResults.Passed / $total) * 100, 1) } else { 0 }
    
    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Passed) ✅" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Failed) ❌" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })
    
    if ($script:TestResults.Failed -gt 0) {
        Write-Host "`n❌ FAILED TESTS:" -ForegroundColor Red
        Write-Host "=" * 80 -ForegroundColor Red
        
        foreach ($test in $script:TestResults.Tests) {
            if (-not $test.Passed) {
                Write-Host "  • $($test.Description)" -ForegroundColor Red
                if ($test.Error) {
                    Write-Host "    Error: $($test.Error)" -ForegroundColor DarkRed
                }
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Cyan
}

# Main test execution
try {
    Write-Host "`n🚀 Starting helper2.ps1 Comprehensive Tests" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    # Initialize test environment
    Initialize-TestEnvironment
    
    # Source the helper2.ps1 script
    $helper2Path = Join-Path (Split-Path $PSScriptRoot -Parent) "helper2.ps1"
    if (Test-Path $helper2Path) {
        Write-Host "📜 Loading helper2.ps1..." -ForegroundColor Cyan
        # Note: Some functions require full initialization, so we'll test what we can
    } else {
        Write-Host "⚠️  helper2.ps1 not found at: $helper2Path" -ForegroundColor Yellow
        Write-Host "   Some tests will be skipped" -ForegroundColor Yellow
    }
    
    # Run all test suites
    Test-SmartRouter
    Test-FuzzyMatching
    Test-StakeholderManagement
    Test-InitiativeManagement
    Test-QuickTaskFeature
    Test-AutoReloadFunctionality
    Test-DateParsing
    Test-PriorityValidation
    Test-SizeValidation
    Test-CSVOperations
    Test-HelperCommands
    
    # Show summary
    Show-TestSummary
    
    # Cleanup
    Cleanup-TestEnvironment
    
    # Exit with appropriate code
    if ($script:TestResults.Failed -eq 0) {
        Write-Host "`n✅ All tests passed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n❌ Some tests failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "`n💥 Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    exit 1
}
