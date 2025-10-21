# v9_csv_adapter_v2.ps1 - Multi-line CSV Support

## What's New

This version (`v9_csv_adapter_v2.ps1`) adds proper support for multi-line text fields in CSV exports, specifically for the "Details Description", "Details Positives", and "Details Negatives" fields.

## Problem Solved

The original `v9_csv_adapter.ps1` parsed CSV files line-by-line, which caused issues when ticket details contained multi-line text with newlines. PowerShell's `ConvertFrom-Csv` can handle multi-line quoted fields correctly, but the line-by-line parsing approach broke these fields apart.

## Changes Made

1. **Pre-parse TICKETS section**: The entire TICKETS section is now extracted and parsed using `ConvertFrom-Csv` BEFORE the line-by-line loop
2. **Skip TICKETS in main loop**: The main parsing loop now skips the TICKETS section entirely
3. **Post-process tickets**: After the main loop, the pre-parsed tickets are processed and added to the result
4. **Handle both column name formats**: Supports both "Details Description" (V10) and "Details: Description" (V9)

## How to Use

### Option 1: Temporary Test
To test without changing your workflow:
```powershell
# In PowerShell
. ./v9_csv_adapter_v2.ps1
$config = Read-V9ConfigFile -FilePath "./Output/project_config_2025-10-21_13-07-55.csv"
```

### Option 2: Update helper2.ps1 to use v2
Edit `helper2.ps1` line 1 to change:
```powershell
# OLD:
. "$PSScriptRoot/v9_csv_adapter.ps1"

# NEW:
. "$PSScriptRoot/v9_csv_adapter_v2.ps1"
```

### Option 3: Replace the original (after testing)
Once you're confident it works:
```powershell
# Backup original
cp v9_csv_adapter.ps1 v9_csv_adapter.ps1.old

# Replace with v2
cp v9_csv_adapter_v2.ps1 v9_csv_adapter.ps1
```

## Testing

Run the test script:
```powershell
pwsh ./test_csv_adapter_v2.ps1
```

This will:
- Load the v2 adapter
- Find the latest config file
- Parse it
- Display the first ticket with multi-line details
- Show line counts for multi-line fields

## Compatibility

- ✅ Fully backward compatible with existing CSV files
- ✅ Supports both V9 and V10 formats
- ✅ Handles both column name formats ("Details Description" and "Details: Description")
- ✅ All existing functionality preserved

## Files

- `v9_csv_adapter.ps1` - Original version (unchanged)
- `v9_csv_adapter_v2.ps1` - New version with multi-line support
- `v9_csv_adapter.ps1.backup` - Backup of original (if you made changes)
- `test_csv_adapter_v2.ps1` - Test script
- `README_v9_csv_adapter_v2.md` - This file
