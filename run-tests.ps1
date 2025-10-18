#!/usr/bin/env pwsh
# Quick test runner to verify all tests can run

$ErrorActionPreference = "Continue"

Write-Host "`n🧪 Running PowerShell Test Suite..." -ForegroundColor Cyan

try {
    # Run the tests
    $result = & "$PSScriptRoot/tests/powershell/helper2-tests.ps1" 2>&1
    
    # Output results
    $result | Out-String | Write-Host
    
    # Check exit code
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Tests completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Tests completed with some failures (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`n❌ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
}
