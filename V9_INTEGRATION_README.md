# V9 CSV Compatibility Integration

## Summary

The `helper.ps1` PowerShell script is now **fully compatible** with the V9 HTML console's multi-section CSV export format. This enables seamless task management across PowerShell and HTML environments.

## What Was Added

### New Files

1. **v9_csv_adapter.ps1** - Core CSV parsing/writing module
   - `Get-LatestV9ConfigFile` - Auto-finds latest config in Downloads
   - `Read-V9ConfigFile` - Parses multi-section CSV format
   - `Write-V9ConfigFile` - Writes config with all sections preserved
   - `Test-V9ConfigFile` - Validates config file integrity
   - `Convert-V9TicketToLegacyTask` - Converts between formats

2. **v9_integration.ps1** - Integration layer for helper.ps1
   - `Initialize-V9Environment` - Auto-setup on load
   - `Get-V9Tickets` - Unified ticket retrieval
   - `Add-V9Ticket` - Create new tickets
   - `Update-V9Ticket` - Modify existing tickets
   - `Remove-V9Ticket` - Delete/close tickets
   - `Show-V9Summary` - Display current state

3. **test_v9_integration.ps1** - Test suite
   - Validates all integration functions
   - Tests auto-detection
   - Verifies parsing/writing
   - Optional CRUD tests

4. **V9_CSV_COMPATIBILITY_GUIDE.md** - Complete documentation
   - Quick start guide
   - API reference
   - Examples and best practices
   - Troubleshooting

### Modified Files

- **helper.ps1** - Updated to auto-load V9 integration on startup

## What Changed

### ✅ Non-Breaking Changes (Additive Only)

- **No existing functionality removed**
- **No existing commands changed**
- **Legacy mode still works** with `task_progress_data.csv`
- **V9 mode auto-activates** when config file found in Downloads

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                      USER WORKFLOW                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌──────────────────────────────────────┐
        │  1. Export from html_console_v9.html │
        │     → project_config_*.csv           │
        └──────────────────┬───────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  2. Auto-saved to ~/Downloads        │
        └──────────────────┬───────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  3. Run PowerShell (helper.ps1)      │
        │     → Auto-detects latest file       │
        │     → Loads V9 integration           │
        └──────────────────┬───────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  4. Use PowerShell Commands          │
        │     → Get-V9Tickets                  │
        │     → Add-V9Ticket                   │
        │     → Update-V9Ticket                │
        │     → Remove-V9Ticket                │
        │     → Show-V9Summary                 │
        └──────────────────┬───────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  5. Changes Auto-Saved               │
        │     → Backup created                 │
        │     → All sections preserved         │
        └──────────────────┬───────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  6. Import in html_console_v9.html   │
        │     → Select updated CSV file        │
        │     → Changes appear in console      │
        └──────────────────────────────────────┘
```

## Quick Start

### 1. Export Config from HTML
```
1. Open html_console_v9.html
2. Click "Export Closed" (if you have closed items)
3. Click "Export Config"
4. File saved to Downloads/project_config_YYYY-MM-DD_HH-MM-SS.csv
```

### 2. Use PowerShell
```powershell
# Load helper.ps1 (V9 integration auto-loads)
cd "HTML Task Tracker"
. ./helper.ps1

# Show summary
Show-V9Summary

# Get tickets
$tickets = Get-V9Tickets

# Add a ticket
Add-V9Ticket -Description "New Task" -Size "M" -AssignedTeam @("Peter")

# Update a ticket
Update-V9Ticket -TicketId 5 -Status "In Progress"
```

### 3. Reload in HTML
```
1. Open html_console_v9.html
2. Click "Import Config"
3. Select updated project_config_*.csv
4. See your PowerShell changes!
```

## Data Preservation

All sections of the V9 CSV are preserved during PowerShell operations:

| Section | Description | Preserved? |
|---------|-------------|------------|
| **METADATA** | Export date, version, description | ✅ Yes |
| **SETTINGS** | Base hours, project hours, start date, ticket ID | ✅ Yes |
| **TASK_SIZES** | Size definitions (S, M, L, XL) | ✅ Yes |
| **PEOPLE** | Team members with weekly availability | ✅ Yes |
| **TICKETS** | Tasks with full history and details | ✅ Yes (modified) |

## Safety Features

### Automatic Backups
Every write operation creates a timestamped backup:
```
project_config_2025-01-15_10-30-00.csv
project_config_2025-01-15_10-30-00.csv.backup_20250115_103015
```

### Validation Checks
- Required sections present
- Valid task sizes referenced
- Valid people assignments
- No duplicate ticket IDs
- Data consistency

### Fallback Mode
If V9 config not found, automatically falls back to legacy mode:
- Uses `task_progress_data.csv`
- Original functions work unchanged
- No breaking changes

## Testing

Run the test suite to verify everything works:

```powershell
# Run integration tests
. ./test_v9_integration.ps1
```

Expected output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  V9 CSV ADAPTER - INTEGRATION TEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/8] Loading V9 integration module...
✅ Module loaded successfully

[2/8] Testing auto-detection of latest config file...
✅ Found config file: project_config_2025-01-15_10-30-00.csv

[3/8] Testing config file validation...
✅ Config file is valid

[4/8] Testing config file parsing...
✅ Config parsed successfully

[5/8] Testing V9 environment initialization...
✅ V9 environment initialized successfully

[6/8] Testing Get-V9Tickets...
✅ Retrieved 25 tickets

[7/8] Testing Show-V9Summary...
✅ Summary displayed successfully

[8/8] Testing Add/Update/Remove functions...
✅ All tests passed!
```

## API Reference

### Core Functions (v9_csv_adapter.ps1)

```powershell
# Find latest config file
$file = Get-LatestV9ConfigFile

# Read config
$config = Read-V9ConfigFile -FilePath $file

# Write config (with backup)
Write-V9ConfigFile -FilePath $file -ConfigData $config -CreateBackup

# Validate config
$validation = Test-V9ConfigFile -FilePath $file
```

### Integration Functions (v9_integration.ps1)

```powershell
# Initialize environment
Initialize-V9Environment -Force

# Get tickets
$all = Get-V9Tickets
$myTickets = Get-V9Tickets -EmployeeName "Peter"
$activeTickets = Get-V9Tickets -Status "In Progress"

# Add ticket
Add-V9Ticket -Description "Task" -Size "M" -AssignedTeam @("Peter")

# Update ticket
Update-V9Ticket -TicketId 5 -Status "Completed"

# Remove ticket
Remove-V9Ticket -TicketId 5          # Soft delete (mark as Closed)
Remove-V9Ticket -TicketId 5 -HardDelete  # Permanent delete

# Show summary
Show-V9Summary
```

## Examples

### Example 1: Get Your Tasks
```powershell
$myTasks = Get-V9Tickets -EmployeeName "Peter"
Write-Host "I have $($myTasks.Count) tasks"
```

### Example 2: Add Sprint Tasks
```powershell
$tasks = @(
    @{ Desc="Feature A"; Size="M"; Priority="P1" },
    @{ Desc="Feature B"; Size="L"; Priority="P2" }
)

foreach ($task in $tasks) {
    Add-V9Ticket -Description $task.Desc `
                 -Size $task.Size `
                 -Priority $task.Priority `
                 -AssignedTeam @("Peter")
}
```

### Example 3: Update Task Status
```powershell
# Mark ticket as in progress
Update-V9Ticket -TicketId 5 -Status "In Progress" -StartDate (Get-Date -Format "yyyy-MM-dd")
```

### Example 4: Close Completed Tasks
```powershell
$completed = Get-V9Tickets -Status "Completed"
foreach ($ticket in $completed) {
    Remove-V9Ticket -TicketId $ticket.ID  # Soft delete (mark as Closed)
}
```

## Troubleshooting

### Issue: "No project_config_*.csv files found"

**Cause**: No V9 config exported from HTML console yet.

**Solution**:
1. Open `html_console_v9.html`
2. Click "Export Config"
3. File will be saved to Downloads
4. Reload PowerShell

### Issue: "V9 config file validation failed"

**Cause**: Config file corrupted or wrong format.

**Solution**:
```powershell
# Check validation details
$validation = Test-V9ConfigFile -FilePath (Get-LatestV9ConfigFile)
$validation.Errors | ForEach-Object { Write-Host $_ }
```

### Issue: Changes not appearing in HTML

**Cause**: Forgot to import updated config in HTML.

**Solution**:
1. In PowerShell: Verify "✅ Changes saved" message
2. In HTML: Click "Import Config" button
3. Select the updated CSV file

### Issue: Using legacy mode instead of V9

**Cause**: V9 config file not detected.

**Solution**:
```powershell
# Force reload
Initialize-V9Environment -Force

# Check what was found
Get-LatestV9ConfigFile
```

## Complete Documentation

See **V9_CSV_COMPATIBILITY_GUIDE.md** for:
- Detailed API reference
- Advanced usage examples
- Best practices
- CSV format specification
- Migration guide

## Version

**Version**: 1.0  
**Date**: 2025-01-15  
**Status**: Production Ready ✅

---

## Summary

✅ **Fully compatible** with html_console_v9.html export format  
✅ **Auto-detects** latest config file from Downloads  
✅ **Preserves all data** (metadata, settings, people, task sizes)  
✅ **Non-breaking** - existing helper.ps1 functions still work  
✅ **Automatic backups** on every write  
✅ **Full validation** before operations  
✅ **Round-trip tested** HTML → PowerShell → HTML  

**You can now manage tasks seamlessly across HTML and PowerShell!** 🎉
