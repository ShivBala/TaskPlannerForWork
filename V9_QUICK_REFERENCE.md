# V9 CSV Compatibility - Quick Reference Card

## 🚀 Quick Start (3 Steps)

### Step 1: Export from HTML Console
```
1. Open html_console_v9.html in browser
2. Click "Export Closed" (if you have closed items)
3. Click "Export Config"
4. File saved to Downloads: project_config_YYYY-MM-DD_HH-MM-SS.csv
```

### Step 2: Load PowerShell
```powershell
cd "HTML Task Tracker"
. ./helper.ps1
```

Output:
```
✅ V9 CSV integration enabled
✅ V9 CSV Adapter module loaded
✅ Found latest config: project_config_2025-01-15_10-30-00.csv
✅ V9 mode initialized
```

### Step 3: Use Commands
```powershell
# Show overview
Show-V9Summary

# Get your tickets
Get-V9Tickets -EmployeeName "Peter"

# Add a ticket
Add-V9Ticket -Description "New Task" -Size "M" -AssignedTeam @("Peter")
```

## 📋 Common Commands

### View Commands

```powershell
# Show summary of everything
Show-V9Summary

# Get all tickets
Get-V9Tickets

# Get your tickets
Get-V9Tickets -EmployeeName "YourName"

# Get tickets by status
Get-V9Tickets -Status "In Progress"
Get-V9Tickets -Status "To Do"
Get-V9Tickets -Status "Completed"
```

### Add Command

```powershell
# Add a new ticket (minimal)
Add-V9Ticket -Description "Task description" -Size "M"

# Add with all options
Add-V9Ticket `
    -Description "Complete feature X" `
    -AssignedTeam @("Peter", "Vipul") `
    -Size "L" `
    -Priority "P1" `
    -StartDate "2025-01-20" `
    -Status "To Do"
```

### Update Commands

```powershell
# Update status
Update-V9Ticket -TicketId 5 -Status "In Progress"

# Update priority
Update-V9Ticket -TicketId 5 -Priority "P1"

# Update multiple fields
Update-V9Ticket -TicketId 5 -Status "In Progress" -Priority "P1" -Size "L"

# Reassign ticket
Update-V9Ticket -TicketId 5 -AssignedTeam @("Siva")
```

### Remove Commands

```powershell
# Soft delete (mark as Closed)
Remove-V9Ticket -TicketId 5

# Hard delete (permanently remove)
Remove-V9Ticket -TicketId 5 -HardDelete
```

## 🔧 Utility Commands

```powershell
# Find latest config file
Get-LatestV9ConfigFile

# Reload environment (after exporting new file from HTML)
Initialize-V9Environment -Force

# Validate current config
$validation = Test-V9ConfigFile -FilePath (Get-LatestV9ConfigFile)
$validation.IsValid
```

## 📊 Task Sizes

Valid size values:
- `S` - Small (1 day)
- `M` - Medium (2 days)
- `L` - Large (5 days)
- `XL` - Extra Large (10 days)

## 🎯 Task Priorities

Valid priority values:
- `P1` - Highest priority
- `P2` - High priority
- `P3` - Medium priority (default)
- `P4` - Low priority
- `P5-P9` - Lower priorities

## 📈 Task Statuses

Valid status values:
- `To Do` - Not started
- `In Progress` - Currently working on
- `Completed` - Finished
- `Blocked` - Cannot proceed
- `Closed` - Archived

## 🔄 HTML Round-Trip

After making changes in PowerShell:

```
1. Open html_console_v9.html
2. Click "Import Config" button
3. Select updated project_config_*.csv file
4. Your changes appear in the console!
```

## 💡 Pro Tips

### Filter and Process

```powershell
# Get high-priority tasks
$highPriority = Get-V9Tickets | Where-Object { $_.Priority -in @('P1', 'P2') }

# Get unassigned tasks
$unassigned = Get-V9Tickets | Where-Object { $_.AssignedTeam.Count -eq 0 }

# Count tickets by status
Get-V9Tickets | Group-Object Status | Select-Object Name, Count
```

### Bulk Operations

```powershell
# Mark all "To Do" as "In Progress"
Get-V9Tickets -Status "To Do" | ForEach-Object {
    Update-V9Ticket -TicketId $_.ID -Status "In Progress"
}

# Add multiple tasks
$tasks = @(
    @{Desc="Feature A"; Size="M"},
    @{Desc="Feature B"; Size="L"},
    @{Desc="Feature C"; Size="S"}
)
$tasks | ForEach-Object {
    Add-V9Ticket -Description $_.Desc -Size $_.Size
}
```

### Custom Functions

```powershell
# Start working on a task
function Start-Task {
    param([int]$Id)
    Update-V9Ticket -TicketId $Id -Status "In Progress" -StartDate (Get-Date -Format "yyyy-MM-dd")
}

# Complete a task
function Complete-Task {
    param([int]$Id)
    Update-V9Ticket -TicketId $Id -Status "Completed"
}

# Use them
Start-Task -Id 5
Complete-Task -Id 10
```

## 🛟 Troubleshooting

### Problem: "No project_config_*.csv files found"
**Solution**: Export config from html_console_v9.html first

### Problem: "V9 mode not initialized"
**Solution**: 
```powershell
# Force reload
Initialize-V9Environment -Force
```

### Problem: Changes not appearing in HTML
**Solution**: 
1. Verify save succeeded (look for "✅ Changes saved")
2. In HTML: Click "Import Config" (not "Load Config")
3. Select the updated CSV file

### Problem: "Invalid size" or "Unknown people"
**Solution**: 
```powershell
# Check valid sizes
Show-V9Summary  # Shows task sizes section

# Check valid people
Show-V9Summary  # Shows people section
```

## 📁 File Locations

- **Exports**: `~/Downloads/project_config_*.csv`
- **Backups**: `~/Downloads/project_config_*.csv.backup_*`
- **Code**: Current directory (HTML Task Tracker)

## 🧪 Testing

```powershell
# Run full test suite
. ./test_v9_integration.ps1
```

## 📚 Documentation

- **Complete Guide**: `V9_CSV_COMPATIBILITY_GUIDE.md`
- **Integration README**: `V9_INTEGRATION_README.md`
- **Implementation Summary**: `V9_IMPLEMENTATION_SUMMARY.md`

## ⚡ One-Liners

```powershell
# Quick status update
Get-V9Tickets -Status "To Do" | Select-Object -First 1 | ForEach-Object { Update-V9Ticket -TicketId $_.ID -Status "In Progress" }

# Today's tasks
Get-V9Tickets -EmployeeName "Peter" -Status "In Progress"

# Add and start
$ticket = Add-V9Ticket -Description "New task" -Size "M"; Update-V9Ticket -TicketId $ticket.ID -Status "In Progress"

# Quick summary
Get-V9Tickets | Group-Object Status | Sort-Object Count -Descending | Format-Table Name, Count
```

## 🎓 Learning Path

1. **Beginner**: Use `Show-V9Summary` and `Get-V9Tickets`
2. **Intermediate**: Add/update tickets with `Add-V9Ticket` and `Update-V9Ticket`
3. **Advanced**: Create custom functions and bulk operations
4. **Expert**: Read full documentation and extend functionality

## ✅ Checklist

Before starting work:
- [ ] Export config from HTML console
- [ ] Load helper.ps1
- [ ] Run `Show-V9Summary` to verify

When adding tickets:
- [ ] Use valid size (S, M, L, XL)
- [ ] Use valid priority (P1-P9)
- [ ] Assign to valid people
- [ ] Set appropriate status

After making changes:
- [ ] Verify "✅ Changes saved" message
- [ ] Check backup file created
- [ ] Import in HTML console to verify

## 🔐 Safety Features

- ✅ **Automatic Backups**: Every write creates backup
- ✅ **Validation**: All changes validated before saving
- ✅ **Soft Delete**: Default to mark as Closed (not permanent delete)
- ✅ **Confirmation**: Hard delete requires explicit confirmation
- ✅ **Data Preservation**: All sections (metadata, settings, people) preserved

---

**Need help?** Read the full guide: `V9_CSV_COMPATIBILITY_GUIDE.md`
