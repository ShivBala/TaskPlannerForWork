# Changes Summary - Output Folder Integration & CSV Format Fixes

## Date: October 15, 2025

## Changes Made

### 1. Output Folder Integration

Both `v9_csv_adapter.ps1` and `helper2.ps1` now use an **Output** folder for managing config files instead of directly using the Downloads folder.

#### How it Works:
1. **Auto-Sync from Downloads**: At startup, helper2 checks the Downloads folder for new `project_config_*.csv` files
2. **Smart Copy**: If a newer file is found in Downloads (or Output is empty), it automatically copies it to the Output folder
3. **Work from Output**: All read/write operations now use files from the Output folder
4. **Easy Configuration**: Folder paths are defined as variables at the top of both files for easy customization

#### Benefits:
- **Cleaner Downloads folder**: Working files stay in the project Output folder
- **Better organization**: All working config files in one place
- **Persistent work**: Changes saved to Output folder, Downloads remains as export location
- **Easy to change**: Both folder paths defined as variables:
  ```powershell
  $script:OutputFolderPath = Join-Path $PSScriptRoot "Output"
  $script:DownloadsFolderPath = "$HOME/Downloads"
  ```

### 2. CSV Format Fixes

Fixed CSV formatting issues when adding new tasks via PowerShell:

#### Issues Fixed:
- **Null/Empty Field Handling**: Added proper null checks for all ticket fields
- **Task Type Column**: Fixed "Fixed" task type being written to wrong column
- **Empty String Handling**: All empty fields now properly output as empty strings

#### Technical Changes in `v9_csv_adapter.ps1` (Write-V9ConfigFile):
```powershell
# Before: Simple field assignment (could be null)
$desc = $ticket.Description -replace '"', '""'
$assignedTeam = ($ticket.AssignedTeam -join ';')

# After: Null-safe field handling
$desc = if ($ticket.Description) { $ticket.Description -replace '"', '""' } else { "" }
$assignedTeam = if ($ticket.AssignedTeam) { ($ticket.AssignedTeam -join ';') } else { "" }
$taskType = if ($ticket.TaskType) { $ticket.TaskType } else { "Fixed" }
```

All fields now have proper null checks:
- Description
- Assigned Team
- Pause Comments
- Start/End Date History
- Size History
- Custom End Date
- Details fields
- Task Type (defaults to "Fixed" if empty)

### 3. Files Modified

1. **v9_csv_adapter.ps1**:
   - Added Output/Downloads folder path variables
   - Updated `Get-LatestV9ConfigFile` function with auto-sync logic
   - Fixed null handling in `Write-V9ConfigFile` function

2. **helper2.ps1**:
   - Added Output/Downloads folder path variables
   - Updated comments to reflect new behavior

## Testing Results

✅ **Sync Test**: Files automatically copy from Downloads to Output
✅ **Read Test**: Config files read successfully from Output folder  
✅ **Write Test**: New tasks added with proper CSV formatting
✅ **Round-trip Test**: Written CSV can be read back correctly
✅ **Field Count Test**: All 16 columns properly aligned

## Sample Output

### Console Output When Starting helper2.ps1:
```
🔍 Looking for V9 config...
📥 No files in Output folder, copying from Downloads...
✅ Copied: project_config_2025-10-14_22-47-59.csv
   From: Downloads (modified: 10/15/2025 09:47:59)
   To: Output
✅ Using config from Output: project_config_2025-10-14_22-47-59.csv
```

### CSV Output Format (last task added):
```csv
99,"Test Task from PowerShell",2025-10-16,M,P2,"Vipul","To Do","Fixed","","","","","","","",""
```

All 16 fields properly quoted and aligned:
1. ID
2. Description
3. Start Date
4. Size
5. Priority  
6. Assigned Team
7. Status
8. Task Type
9. Pause Comments
10. Start Date History
11. End Date History
12. Size History
13. Custom End Date
14. Details: Description
15. Details: Positives
16. Details: Negatives

## Configuration Variables

### To change the Output folder location:

**In v9_csv_adapter.ps1** (line ~25):
```powershell
$script:OutputFolderPath = Join-Path $PSScriptRoot "Output"
```

**In helper2.ps1** (line ~22):
```powershell
$script:OutputFolderPath = Join-Path $PSScriptRoot "Output"
```

### To change the Downloads folder location:

**In v9_csv_adapter.ps1** (line ~26):
```powershell
$script:DownloadsFolderPath = "$HOME/Downloads"
```

**In helper2.ps1** (line ~23):
```powershell
$script:DownloadsFolderPath = "$HOME/Downloads"
```

## Next Steps

1. Test by exporting a new config from html_console_v9.html to Downloads
2. Run helper2.ps1 - it should automatically copy the file to Output
3. Add/modify tasks - changes will be saved to the Output folder
4. Export closed items will still go to Downloads (handled by HTML console)
5. Next time you run helper2, it will sync any newer files from Downloads

## Notes

- The Output folder is created automatically if it doesn't exist
- Sync happens only when a newer file is found in Downloads
- Files in Output are never deleted automatically
- You can manually delete old files from Output folder to clean up
- Both folders are configurable via variables at top of each file
