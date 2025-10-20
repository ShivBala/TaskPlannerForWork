# Enhanced Config File Sync Feature

## Implementation Date
October 20, 2025

## Overview
Implemented enhanced file sync logic to detect PowerShell edits and prevent accidental overwrites of unsaved changes.

## Features Implemented

### 1. SHA1 Hash Validation (`Get-FileSHA1Hash`)
- Calculates SHA1 hash of files for content comparison
- Used to detect if Output file contains PS edits

### 2. Enhanced Sync Logic (`Sync-ConfigFiles`)
**Logic Flow:**
1. Compare timestamps of most recent files in Downloads vs Output
2. **If Output is newer:**
   - Get SHA1 of Downloads file
   - Get SHA1 of most recent History backup file
   - If hashes match → Output was edited by PS (backup was made before PS edit)
   - **Warning displayed:** "Output file has PowerShell edits!"
   - User prompted: "Continue anyway? (y/n)"
   - If 'n', sync cancelled - user must import to HTML first
3. **If Downloads is newer:**
   - Copy Downloads → Output (normal behavior)

### 3. PS Edit Marker (`Rename-ConfigFileAfterEdit`)
- After ANY PowerShell edit, file renamed to include `.psedited.csv` extension
- Example: `project_config_2025-10-20.csv` → `project_config_2025-10-20.psedited.csv`
- Marker helps identify files that need HTML import

### 4. Automatic Integration
- `Save-V9Config` now calls `Rename-ConfigFileAfterEdit` after successful save
- ALL add/modify operations use `Save-V9Config`, so marker is added automatically
- No changes needed to individual task functions

### 5. New `sync` Command
- Users can manually run sync logic anytime
- Usage: `helper2> sync`
- Shows detailed sync status and warnings

### 6. Auto-Sync on Launch
- `Initialize-V9Config` calls `Sync-ConfigFiles` at startup
- Ensures PS edits are detected before user starts working

## Modified Functions

### helper2.ps1
1. **New Functions:**
   - `Get-FileSHA1Hash` - Calculate file hashes
   - `Rename-ConfigFileAfterEdit` - Add psedited marker
   - `Sync-ConfigFiles` - Enhanced sync with SHA1 validation

2. **Updated Functions:**
   - `Save-V9Config` - Added rename call after save
   - `Initialize-V9Config` - Added sync call before loading
   - `Invoke-Command` - Added sync command handler
   - `Show-Help` - Added sync command documentation

### v9_csv_adapter.ps1
- No changes needed
- `Get-LatestV9ConfigFile` already handles `*.psedited.csv` files via wildcard pattern

## File Naming Examples

### Normal Flow
1. Export from HTML: `project_config_2025-10-20_14-30-00.csv` → Downloads
2. PS loads file: Copy to Output folder
3. PS edits task: Creates backup in History, renames to `project_config_2025-10-20_14-30-00.psedited.csv`

### SHA1 Validation Example
```
Downloads:  project_config_2025-10-20_14-30-00.csv (modified: Oct 20, 2:30 PM)
            SHA1: ABC123...

Output:     project_config_2025-10-20_14-30-00.psedited.csv (modified: Oct 20, 3:45 PM)
            (newer timestamp due to PS edit)

History:    project_config_2025-10-20_14-30-00.csv.backup_20251020_154500
            SHA1: ABC123... (matches Downloads!)

Result: Output has PS edits → Warning displayed
```

## User Workflow

### Scenario 1: Normal HTML → PS → HTML Round Trip
1. User exports from HTML → Downloads
2. PS launches, syncs Downloads → Output
3. PS edits task → File renamed to `.psedited.csv`
4. User imports `.psedited.csv` to HTML, tests changes
5. User exports from HTML → New file in Downloads
6. Next PS launch: Downloads newer → Copies to Output ✅

### Scenario 2: PS Edits Not Yet Imported
1. User exports from HTML → Downloads (Oct 20, 2:00 PM)
2. PS edits task → Output has `.psedited.csv` (Oct 20, 2:15 PM)
3. User tries to launch PS again or run `sync`:
   ```
   ⚠️  WARNING: Output file has PowerShell edits!
   The current Output file was last edited by this PowerShell script.
   You should import it to HTML console and test before making more edits.
   
   Continue anyway? (y/n):
   ```
4. User types 'n' → Sync cancelled
5. User imports Output file to HTML, tests
6. User exports from HTML → Downloads now newer
7. Next sync works normally ✅

## Testing Checklist

- [x] SHA1 hash calculation works
- [x] File rename adds `.psedited.csv` marker
- [x] Sync detects PS edits via hash comparison
- [x] Warning displayed when Output has PS edits
- [x] User can continue or cancel when warned
- [x] `sync` command accessible from prompt
- [x] Auto-sync runs on startup
- [x] Help text updated
- [x] Normal Downloads → Output copy still works
- [x] Handles missing files gracefully

## Benefits

1. **Prevents Data Loss:** Users warned before potentially overwriting PS changes
2. **Clear File State:** `.psedited.csv` marker shows which files need HTML import
3. **Automatic Detection:** No manual tracking needed - SHA1 comparison is reliable
4. **User Control:** Can choose to continue or cancel when warned
5. **Backward Compatible:** Works with existing workflow, just adds safety

## Edge Cases Handled

1. **No Downloads file:** Uses Output file without warning
2. **No Output file:** Copies from Downloads
3. **No backup files:** Skips SHA1 check, uses timestamp only
4. **Multiple PS edits:** Each edit creates new backup, most recent backup checked
5. **Manual file edits:** SHA1 won't match → No false positive warning

## Notes

- File rename is graceful - if rename fails, file keeps original name but changes are still saved
- SHA1 comparison only happens when Output is newer than Downloads
- History backups are created BEFORE PS edits, so their content matches the pre-edit state
- Wildcard pattern `project_config_*.csv` matches both regular and `.psedited.csv` files
