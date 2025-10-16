# PowerShell Scripts Updated for V10 Support

## Overview
Updated `v9_csv_adapter.ps1` and `helper2.ps1` to support both V9 and V10 configuration file formats with full backward compatibility.

## Files Modified

### 1. `v9_csv_adapter.ps1` (V9/V10 CSV Adapter Module)

#### Changes Made:

**Header & Documentation**
- Updated from "V9 CSV Adapter" to "V9/V10 CSV Adapter"
- Added documentation for V10-specific sections:
  - `SECTION,STAKEHOLDERS`: Stakeholder names
  - `SECTION,INITIATIVES`: Initiative names with creation and start dates
  - TICKETS section now includes: UUID, Stakeholder, Initiative fields

**Cache Structure**
- Added `Stakeholders` and `Initiatives` to cache hashtable

**Read-V9ConfigFile Function**
- Added initialization of `Stakeholders` and `Initiatives` arrays in result hashtable
- Added parsing for `STAKEHOLDERS` section:
  ```powershell
  'STAKEHOLDERS' {
      # Parse: "Stakeholder Name"
      $result.Stakeholders += $name
  }
  ```
- Added parsing for `INITIATIVES` section:
  ```powershell
  'INITIATIVES' {
      # Parse: "Initiative Name","Creation Date","Start Date"
      $result.Initiatives += @{
          Name, CreationDate, StartDate
      }
  }
  ```
- Enhanced `TICKETS` section parsing:
  - Now stores actual CSV header to detect V9 vs V10 format
  - Dynamically adds V10 fields (UUID, Stakeholder, Initiative) if present
  - Uses PowerShell's built-in ConvertFrom-Csv for robust CSV parsing

**Write-V9ConfigFile Function**
- Added writing of `STAKEHOLDERS` section (if present):
  ```csv
  SECTION,STAKEHOLDERS
  Name
  "Engineering"
  "General"
  ```
- Added writing of `INITIATIVES` section (if present):
  ```csv
  SECTION,INITIATIVES
  Name,Creation Date,Start Date
  "Q4 Migration","2025-10-16","2025-11-01"
  "General","2025-10-16",""
  ```
- Enhanced TICKETS section writing:
  - Auto-detects V10 format (checks if tickets have UUID field)
  - Writes V10 header format when V10 tickets detected:
    ```
    UUID,ID,Description,...,Stakeholder,Initiative,...
    ```
  - Writes V9 header format for V9 tickets (backward compatible)
  - Properly escapes and formats V10 fields in ticket rows

**Status Messages**
- Enhanced to show format version (V9 or V10)
- Displays stakeholder and initiative counts for V10 files
- Examples:
  - "✅ Parsed V10 config: 15 tickets, 5 people, 3 stakeholders, 4 initiatives"
  - "✅ Parsed V9 config: 15 tickets, 5 people"

### 2. `helper2.ps1` (PowerShell Task Management Interface)

#### Changes Made:

**Header & Documentation**
- Updated from "V9 Config Only" to "V9/V10 Config Support"
- Updated description to mention V10 features:
  - Stakeholders and Initiatives management
  - UUID-based task tracking
- Updated date to October 16, 2025
- Added note: "V9/V10 Support - Automatically detects format version"

**Imports**
- Still imports `v9_csv_adapter.ps1` (which now supports both V9 and V10)

## Backward Compatibility

### V9 Files
- ✅ Can still read V9 config files (without STAKEHOLDERS/INITIATIVES sections)
- ✅ `Stakeholders` and `Initiatives` arrays will be empty
- ✅ Tickets won't have UUID, Stakeholder, Initiative properties
- ✅ Writing V9 files works exactly as before

### V10 Files
- ✅ Reads STAKEHOLDERS and INITIATIVES sections
- ✅ Parses UUID, Stakeholder, Initiative from TICKETS
- ✅ Preserves all V10 data when writing back
- ✅ Auto-detects V10 format based on ticket structure

## New Capabilities

### Reading V10 Files
```powershell
$config = Read-V9ConfigFile -FilePath "project_config_V10.csv"

# Access V10-specific data
$config.Stakeholders         # Array of stakeholder names
$config.Initiatives          # Array of initiative objects (Name, CreationDate, StartDate)
$config.Tickets[0].UUID      # Task UUID
$config.Tickets[0].Stakeholder   # Task stakeholder
$config.Tickets[0].Initiative    # Task initiative
```

### Writing V10 Files
```powershell
# Modify config
$config.Stakeholders += "New Team"
$config.Initiatives += @{
    Name = "New Project"
    CreationDate = "2025-10-16"
    StartDate = "2025-11-01"
}

# Save (automatically writes in V10 format if UUID present)
Write-V9ConfigFile -FilePath $file -ConfigData $config -CreateBackup
```

### Auto-Detection
The adapter automatically detects whether to use V9 or V10 format based on:
1. **Reading**: Presence of STAKEHOLDERS/INITIATIVES sections
2. **Writing**: Presence of UUID field in first ticket

## Example Output

### V9 File Loaded
```
✅ Parsed V9 config: 15 tickets, 5 people
```

### V10 File Loaded
```
✅ Parsed V10 config: 15 tickets, 5 people, 3 stakeholders, 4 initiatives
```

### V10 File Saved
```
✅ V10 config saved successfully: 15 tickets, 3 stakeholders, 4 initiatives
```

## Testing Checklist

✅ Read V9 config file (no V10 sections)
✅ Read V10 config file (with STAKEHOLDERS and INITIATIVES)
✅ Write V9 config file (preserves V9 format)
✅ Write V10 config file (preserves V10 format)
✅ Stakeholder names parsed correctly
✅ Initiative objects with dates parsed correctly
✅ Ticket UUID field preserved
✅ Ticket Stakeholder field preserved
✅ Ticket Initiative field preserved
✅ Empty stakeholder/initiative lists handled
✅ Null initiative start dates handled
✅ CSV quoting and escaping works correctly
✅ Cache system updated with V10 fields
✅ Backward compatibility with existing V9 workflows

## Usage Example

```powershell
# Load V10 config
. .\helper2.ps1
Initialize-V9Config

# Access V10 data
$global:V9Config.Stakeholders
$global:V9Config.Initiatives

# Filter tickets by stakeholder
$engineeringTasks = $global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq "Engineering" }

# Filter tickets by initiative
$q4Tasks = $global:V9Config.Tickets | Where-Object { $_.Initiative -eq "Q4 Migration" }

# Find tickets by UUID
$task = $global:V9Config.Tickets | Where-Object { $_.UUID -eq "abc123..." }
```

## Impact

### Before
- ❌ Could only read/write V9 format
- ❌ No support for Stakeholders
- ❌ No support for Initiatives
- ❌ No support for UUID tracking
- ❌ Would lose V10 data if V10 file was loaded

### After
- ✅ Reads and writes both V9 and V10 formats
- ✅ Full support for Stakeholders section
- ✅ Full support for Initiatives section with dates
- ✅ Preserves UUID, Stakeholder, Initiative in tickets
- ✅ Maintains backward compatibility with V9
- ✅ Auto-detects format version
- ✅ Never loses data during round-trip operations

## Future Enhancements (Optional)

- Add PowerShell cmdlets for stakeholder management
- Add PowerShell cmdlets for initiative management
- Add filtering/querying by stakeholder and initiative
- Add reports by stakeholder and initiative
- Add duplicate detection using UUID
- Add initiative timeline visualization

---

**Status**: ✅ Complete and Tested
**Version**: V10 Support Added
**Date**: October 16, 2025
**Backward Compatibility**: 100% - V9 files still work perfectly
