#!/usr/bin/env pwsh
# Quick diagnostic test for failing helper2 tests

Write-Host "`n🔍 Diagnosing Test Failures..." -ForegroundColor Cyan

# Load helper2.ps1
$helper2Path = Join-Path $PSScriptRoot "helper2.ps1"
if (Test-Path $helper2Path) {
    . $helper2Path
    Write-Host "✅ Loaded helper2.ps1" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot find helper2.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "`n📋 Checking Function Availability:" -ForegroundColor Yellow

# Check if functions exist
$functions = @(
    'Resolve-UserIntent',
    'Get-FuzzyMatches',
    'Add-Stakeholder',
    'Remove-Stakeholder',
    'Add-Initiative',
    'Remove-Initiative',
    'Add-QuickTask',
    'Test-ConfigChanged',
    'Ensure-ConfigCurrent',
    'Parse-DateAlias'
)

foreach ($func in $functions) {
    $exists = Get-Command -Name $func -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Host "  ✅ $func" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $func (missing)" -ForegroundColor Red
    }
}

Write-Host "`n📋 Testing Resolve-UserIntent:" -ForegroundColor Yellow
try {
    $intent = Resolve-UserIntent -InputText "sarah"
    Write-Host "  Input: 'sarah'" -ForegroundColor White
    Write-Host "  Action: $($intent.Action)" -ForegroundColor White
    Write-Host "  TargetType: $($intent.TargetType)" -ForegroundColor White
    Write-Host "  Entity: $($intent.Entity)" -ForegroundColor White
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Testing Get-FuzzyMatches:" -ForegroundColor Yellow
try {
    $global:V9Config = @{
        People = @(
            [PSCustomObject]@{ Name = 'TestPerson' }
        )
    }
    $matches = Get-FuzzyMatches -SearchName 'TestPerson' -Type 'Person'
    Write-Host "  Matches found: $($matches.Count)" -ForegroundColor White
    if ($matches.Count -gt 0) {
        Write-Host "  First match score: $($matches[0].Score)" -ForegroundColor White
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📋 Testing Quick Task Pattern:" -ForegroundColor Yellow
$patterns = @('qt', 'quick', 'quicktask')
foreach ($pattern in $patterns) {
    $result = $pattern -match '^q(uick)?t(ask)?$'
    if ($result) {
        Write-Host "  ✅ '$pattern' matches" -ForegroundColor Green
    } else {
        Write-Host "  ❌ '$pattern' does not match" -ForegroundColor Red
    }
}

Write-Host "`n✅ Diagnostic complete!`n" -ForegroundColor Cyan
