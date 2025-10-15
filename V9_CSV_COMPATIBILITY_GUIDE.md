# V9 CSV Compatibility - Quick Start Guide

## Overview

The V9 CSV adapter enables seamless integration between `helper.ps1` PowerShell task management and `html_console_v9.html` exports. This allows you to:

- Use PowerShell commands to manage tasks exported from the HTML console
- Automatically work with the latest config file from your Downloads folder
- Preserve all HTML console data (metadata, settings, people, task sizes)
- Maintain full round-trip compatibility (HTML → PowerShell → HTML)

## Installation

The integration is already set up! Just import the modules:

```powershell
# From the HTML Task Tracker directory
. ./v9_integration.ps1
```

This will automatically:
1. Load the V9 adapter module
2. Search for the latest `project_config_*.csv` in ~/Downloads
3. Initialize V9 mode if found, or fall back to legacy mode

## Quick Start

### 1. Export Config from HTML Console

1. Open `html_console_v9.html` in your browser
2. If you have closed items, click **Export Closed** button first
3. Click **Export Config** button
4. File is saved to Downloads as `project_config_YYYY-MM-DD_HH-MM-SS.csv`

### 2. Use PowerShell Commands

```powershell
# Show summary of current state
Show-V9Summary

# Get all tickets
$tickets = Get-V9Tickets

# Get tickets for specific person
$myTickets = Get-V9Tickets -EmployeeName "Peter"

# Get tickets by status
$activeTickets = Get-V9Tickets -Status "In Progress"

# Add a new ticket
Add-V9Ticket -Description "New Feature Implementation" `
             -AssignedTeam @("Peter", "Vipul") `
             -Size "M" `
             -Priority "P1" `
             -StartDate "2025-01-20"

# Update an existing ticket
Update-V9Ticket -TicketId 5 `
                -Status "In Progress" `
                -Priority "P2"

# Mark ticket as closed (soft delete)
Remove-V9Ticket -TicketId 10

# Permanently delete ticket (hard delete)
Remove-V9Ticket -TicketId 10 -HardDelete
```

### 3. Reload in HTML Console

After making changes in PowerShell:

1. Open `html_console_v9.html`
2. Click **Import Config** button
3. Select the updated `project_config_*.csv` file
4. Your changes appear in the console!

## Features

### Auto-Detection

The integration automatically finds the most recent `project_config_*.csv` file in your Downloads folder:

```powershell
# Manually check for latest file
$configFile = Get-LatestV9ConfigFile
Write-Host "Using: $configFile"

# Reload/refresh config
Initialize-V9Environment -Force
```

### Data Preservation

All sections are preserved when making changes:
- ✅ Metadata (export date, version)
- ✅ Settings (base hours, project hours, common start date, ticket ID)
- ✅ Task Sizes (S, M, L, XL definitions)
- ✅ People (team members with weekly availability)
- ✅ Tickets (your tasks with full history)

### Backup Protection

Every write operation creates a timestamped backup:

```
project_config_2025-01-15_10-30-00.csv
project_config_2025-01-15_10-30-00.csv.backup_20250115_103015
```

### Validation

Config files are validated on load:

```powershell
# Manually validate a config file
$validation = Test-V9ConfigFile -FilePath "~/Downloads/project_config_2025-01-15_10-30-00.csv"

if (!$validation.IsValid) {
    Write-Host "Errors found:"
    $validation.Errors | ForEach-Object { Write-Host "  - $_" }
}

if ($validation.Warnings.Count -gt 0) {
    Write-Host "Warnings:"
    $validation.Warnings | ForEach-Object { Write-Host "  - $_" }
}
```

## Compatibility Modes

### V9 Mode (Recommended)

When a V9 config file is found:
- ✅ Multi-section CSV format support
- ✅ Auto-detection from Downloads
- ✅ Full data preservation
- ✅ Backup on write
- ✅ Validation checks

### Legacy Mode (Fallback)

When no V9 config file exists:
- Uses `task_progress_data.csv` (flat CSV)
- Original helper.ps1 functions work as before
- No breaking changes to existing workflows

## CSV Format Details

The V9 export format has 5 sections:

### 1. METADATA
```csv
SECTION,METADATA
Key,Value
Export Date,2025-01-15T10:30:00.000Z
Version,2.0
Description,Enterprise Project Tracking Console Configuration Export
```

### 2. SETTINGS
```csv
SECTION,SETTINGS
Key,Value
Estimation Base Hours,5
Project Hours Per Day,8
Use Common Start Date,true
Common Start Date,2025-01-15
Current Ticket ID,42
```

### 3. TASK_SIZES
```csv
SECTION,TASK_SIZES
Size Key,Name,Days,Removable
S,"Small",1,false
M,"Medium",2,false
L,"Large",5,false
XL,"Extra Large",10,false
```

### 4. PEOPLE
```csv
SECTION,PEOPLE
Name,Week1,Week2,Week3,Week4,Week5,Week6,Week7,Week8,Project Ready
"Peter",25,25,25,25,25,25,25,25,Yes
"Vipul",25,25,25,25,25,25,25,25,Yes
"Siva",25,25,25,25,25,25,25,25,Yes
```

### 5. TICKETS
```csv
SECTION,TICKETS
ID,Description,Start Date,Size,Priority,Assigned Team,Status,Task Type,Pause Comments,Start Date History,End Date History,Size History,Custom End Date,Details: Description,Details: Positives,Details: Negatives
1,"Database Migration",2025-01-15,M,P1,"Peter;Vipul","In Progress","Fixed","","","","","","Migrate from MySQL to PostgreSQL","Better performance","Complex schema changes"
```

## API Reference

### Core Functions

#### Get-LatestV9ConfigFile
```powershell
# Find latest config file in Downloads
$file = Get-LatestV9ConfigFile

# Use custom Downloads path
$file = Get-LatestV9ConfigFile -DownloadsPath "C:\Custom\Path"
```

#### Read-V9ConfigFile
```powershell
# Read and parse V9 config file
$config = Read-V9ConfigFile -FilePath "~/Downloads/project_config_2025-01-15_10-30-00.csv"

# Access sections
$metadata = $config.Metadata
$settings = $config.Settings
$taskSizes = $config.TaskSizes
$people = $config.People
$tickets = $config.Tickets

# Use cached data
$config = Read-V9ConfigFile -FilePath $file -UseCache
```

#### Write-V9ConfigFile
```powershell
# Save modified config
$config = Read-V9ConfigFile -FilePath $file
# ... modify $config.Tickets ...
Write-V9ConfigFile -FilePath $file -ConfigData $config -CreateBackup
```

#### Test-V9ConfigFile
```powershell
# Validate config file
$validation = Test-V9ConfigFile -FilePath $file

if ($validation.IsValid) {
    Write-Host "✅ Config is valid"
} else {
    Write-Host "❌ Validation failed"
    $validation.Errors | ForEach-Object { Write-Host $_ }
}
```

### Integration Functions

#### Initialize-V9Environment
```powershell
# Auto-initialize (called automatically on module load)
Initialize-V9Environment

# Force reload
Initialize-V9Environment -Force
```

#### Get-V9Tickets
```powershell
# Get all tickets
$all = Get-V9Tickets

# Filter by person
$myTickets = Get-V9Tickets -EmployeeName "Peter"

# Filter by status
$active = Get-V9Tickets -Status "In Progress"
```

#### Add-V9Ticket
```powershell
# Add new ticket
Add-V9Ticket -Description "Task description" `
             -AssignedTeam @("Peter") `
             -Size "M" `
             -Priority "P1" `
             -StartDate "2025-01-20" `
             -Status "To Do"
```

#### Update-V9Ticket
```powershell
# Update specific fields
Update-V9Ticket -TicketId 5 -Status "In Progress"
Update-V9Ticket -TicketId 5 -Priority "P1" -Size "L"
Update-V9Ticket -TicketId 5 -AssignedTeam @("Peter", "Vipul")
```

#### Remove-V9Ticket
```powershell
# Soft delete (mark as Closed)
Remove-V9Ticket -TicketId 5

# Hard delete (permanently remove)
Remove-V9Ticket -TicketId 5 -HardDelete
```

#### Show-V9Summary
```powershell
# Display overview
Show-V9Summary
```

## Troubleshooting

### "No project_config_*.csv files found"

**Solution**: Export config from `html_console_v9.html` first.

```powershell
# Check Downloads folder
ls ~/Downloads/project_config_*.csv
```

### "V9 config file validation failed"

**Solution**: The config file may be corrupted or from an older version.

```powershell
# Check validation details
$validation = Test-V9ConfigFile -FilePath $file
$validation.Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
$validation.Warnings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
```

### "Failed to save ticket"

**Solution**: Check file permissions and ensure file isn't open in another program.

```powershell
# Verify file is writable
Test-Path "~/Downloads/project_config_*.csv" -PathType Leaf

# Check if file is locked
Get-Process | Where-Object { $_.MainWindowTitle -like "*project_config*" }
```

### Changes not appearing in HTML

**Solution**: Make sure to import the updated config file in the HTML console.

1. In PowerShell: Verify save was successful (look for "✅ Changes saved")
2. In HTML: Click "Import Config" (not "Load Config")
3. Select the updated CSV file from Downloads

### Legacy mode instead of V9 mode

**Solution**: Ensure V9 config file exists and is valid.

```powershell
# Force reload
Initialize-V9Environment -Force

# Check if file exists
Get-LatestV9ConfigFile
```

## Best Practices

### 1. Always Export from HTML First

Before using PowerShell commands for the first time:
```
HTML Console → Export Config → Downloads folder → PowerShell commands
```

### 2. Use Show-V9Summary

Check current state before making changes:
```powershell
Show-V9Summary
```

### 3. Test Validations

Validate before major operations:
```powershell
$validation = Test-V9ConfigFile -FilePath (Get-LatestV9ConfigFile)
if (!$validation.IsValid) {
    Write-Host "Fix errors first!"
    return
}
```

### 4. Backup Regularly

Backups are created automatically, but you can also create manual backups:
```powershell
$file = Get-LatestV9ConfigFile
Copy-Item $file "$file.manual_backup_$(Get-Date -Format 'yyyyMMdd')"
```

### 5. Round-Trip Testing

After making changes, verify in HTML console:
```
PowerShell → Save → HTML Import → Verify → Export → PowerShell
```

## Examples

### Example 1: Daily Standup Report

```powershell
# Get your in-progress tickets
$myTickets = Get-V9Tickets -EmployeeName "Peter" -Status "In Progress"

Write-Host "`n📋 My Active Tickets:" -ForegroundColor Cyan
foreach ($ticket in $myTickets) {
    Write-Host "  #$($ticket.ID): $($ticket.Description) [$($ticket.Size), $($ticket.Priority)]" -ForegroundColor White
}
```

### Example 2: Bulk Status Update

```powershell
# Mark all "To Do" tickets as "In Progress"
$todoTickets = Get-V9Tickets -Status "To Do"
foreach ($ticket in $todoTickets) {
    Update-V9Ticket -TicketId $ticket.ID -Status "In Progress"
}
```

### Example 3: Sprint Planning

```powershell
# Add sprint tasks
$sprintTasks = @(
    @{ Description="Feature A"; Size="M"; Priority="P1"; Assigned=@("Peter") },
    @{ Description="Feature B"; Size="L"; Priority="P2"; Assigned=@("Vipul") },
    @{ Description="Feature C"; Size="S"; Priority="P3"; Assigned=@("Siva") }
)

foreach ($task in $sprintTasks) {
    Add-V9Ticket -Description $task.Description `
                 -Size $task.Size `
                 -Priority $task.Priority `
                 -AssignedTeam $task.Assigned `
                 -StartDate (Get-Date -Format "yyyy-MM-dd")
}
```

### Example 4: Cleanup Closed Items

```powershell
# Find all closed tickets
$closedTickets = Get-V9Tickets -Status "Closed"

Write-Host "Found $($closedTickets.Count) closed tickets"

# Hard delete after confirmation
foreach ($ticket in $closedTickets) {
    Write-Host "Delete #$($ticket.ID): $($ticket.Description)?"
    Remove-V9Ticket -TicketId $ticket.ID -HardDelete
}
```

## Advanced Usage

### Custom Workflows

Create your own wrapper functions:

```powershell
function Start-MyTask {
    param([int]$TicketId)
    
    Update-V9Ticket -TicketId $TicketId `
                    -Status "In Progress" `
                    -StartDate (Get-Date -Format "yyyy-MM-dd")
    
    Write-Host "✅ Started working on ticket #$TicketId" -ForegroundColor Green
}

function Complete-MyTask {
    param([int]$TicketId)
    
    Update-V9Ticket -TicketId $TicketId -Status "Completed"
    
    Write-Host "✅ Completed ticket #$TicketId" -ForegroundColor Green
}
```

### Automation Scripts

```powershell
# Auto-update status based on time
$tickets = Get-V9Tickets -Status "To Do"
foreach ($ticket in $tickets) {
    if ($ticket.StartDate -le (Get-Date -Format "yyyy-MM-dd")) {
        Update-V9Ticket -TicketId $ticket.ID -Status "In Progress"
        Write-Host "Auto-started ticket #$($ticket.ID)"
    }
}
```

## Migration from Legacy Format

If you're currently using `task_progress_data.csv`:

### Step 1: Keep Both Files

The integration supports both formats simultaneously. No immediate migration needed.

### Step 2: Export from HTML

When ready, export from V9 HTML console to get multi-section format.

### Step 3: Use New Commands

Switch to `Get-V9Tickets`, `Add-V9Ticket`, etc. for new workflows.

### Step 4: Gradual Migration

Move tasks from legacy to V9 format over time. Both work in parallel.

## Support

For issues or questions:

1. Check this documentation
2. Run `Show-V9Summary` to see current state
3. Run `Test-V9ConfigFile` to validate files
4. Check backup files in Downloads folder
5. Review error messages in PowerShell output

## Version History

- **v1.0** (2025-01-15): Initial V9 CSV adapter release
  - Multi-section CSV parser
  - Auto-detection of latest config file
  - Full round-trip compatibility
  - Backup protection
  - Validation framework
  - Integration functions

---

**Happy Task Tracking! 🚀**
