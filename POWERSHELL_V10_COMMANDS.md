# PowerShell V10 Commands - Complete Reference

## Overview
The PowerShell scripts now fully support V10 features including UUID generation, Stakeholder management, and Initiative management.

## Updated Functions

### ✅ `Add-TaskForPerson` - Now V10-Aware

When adding a task, the function now:
1. **Generates UUID automatically** using `[guid]::NewGuid()`
2. **Prompts for Stakeholder** (if V10 config detected)
3. **Prompts for Initiative** (if V10 config detected)
4. **Adds V10 fields** (UUID, Stakeholder, Initiative) to the ticket object

#### Usage Example:
```powershell
. .\helper2.ps1
Initialize-V9Config

# Add task (will prompt for all fields including V10 fields)
Add-TaskForPerson -PersonName "John"
```

#### Interactive Prompts:
```
➕ Adding task for John

Description: Implement new feature

Status:
  1. To Do
  2. In Progress
Choose (1/2): 2

Start date (today/tomorrow/next wednesday, default: today): today

Available sizes:
  S - Small: 1 days
  M - Medium: 3 days
  L - Large: 5 days
  XL - Extra Large: 10 days
Size (default: M): M

Available Stakeholders:
  1. General
  2. Engineering
  3. Product Team
Choose stakeholder (1-3, default: 1 for General): 2

Available Initiatives:
  1. General
  2. Q4 Migration (starts: 2025-11-01)
  3. Fix priyanka's Scripts (no start date yet)
Choose initiative (1-3, default: 1 for General): 2

✅ Task #15 added successfully!
   Implement new feature
   Status: In Progress | Size: M | Start: 2025-10-16
   Stakeholder: Engineering | Initiative: Q4 Migration
   UUID: abc12345-6789-abcd-ef01-234567890abc
```

### New V10 Management Functions

## 1. `Add-Stakeholder`
Adds a new stakeholder to the V10 configuration.

**Syntax:**
```powershell
Add-Stakeholder -Name "Team Name"
```

**Example:**
```powershell
Add-Stakeholder -Name "Engineering"
Add-Stakeholder -Name "Product Team"
Add-Stakeholder -Name "Marketing"
```

**Output:**
```
✅ Stakeholder 'Engineering' added successfully!
```

## 2. `Add-Initiative`
Adds a new initiative to the V10 configuration with automatic creation date.

**Syntax:**
```powershell
Add-Initiative -Name "Initiative Name"
```

**Example:**
```powershell
Add-Initiative -Name "Q4 Migration"
Add-Initiative -Name "Fix priyanka's Scripts"
Add-Initiative -Name "BaNCS November Release"
```

**Output:**
```
✅ Initiative 'Q4 Migration' added successfully!
```

**Note:** 
- Creation date is set automatically to current date
- Start date is initially `null` and will be calculated from task dates in the HTML console

## 3. `List-Stakeholders`
Lists all stakeholders with task counts.

**Syntax:**
```powershell
List-Stakeholders
```

**Example Output:**
```
📊 Stakeholders (3):
  👥 General (2 tasks)
  👥 Engineering (5 tasks)
  👥 Product Team (3 tasks)
```

## 4. `List-Initiatives`
Lists all initiatives with task counts and dates.

**Syntax:**
```powershell
List-Initiatives
```

**Example Output:**
```
📊 Initiatives (4):
  📈 General (2 tasks, created: 2025-10-16, no start date)
  📈 Q4 Migration (5 tasks, created: 2025-10-16, starts: 2025-11-01)
  📈 Fix priyanka's Scripts (3 tasks, created: 2025-10-16, starts: 2025-10-17)
  📈 BaNCS November Release (4 tasks, created: 2025-10-16, starts: 2025-10-20)
```

## Querying V10 Data

### Filter Tasks by Stakeholder
```powershell
# Get all Engineering tasks
$engTasks = $global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq "Engineering" }
$engTasks | Format-Table ID, Description, Status, StartDate

# Count tasks per stakeholder
$global:V9Config.Tickets | Group-Object Stakeholder | Select-Object Name, Count
```

### Filter Tasks by Initiative
```powershell
# Get all Q4 Migration tasks
$q4Tasks = $global:V9Config.Tickets | Where-Object { $_.Initiative -eq "Q4 Migration" }
$q4Tasks | Format-Table ID, Description, Status, StartDate

# Count tasks per initiative
$global:V9Config.Tickets | Group-Object Initiative | Select-Object Name, Count
```

### Find Task by UUID
```powershell
# Find specific task by UUID
$task = $global:V9Config.Tickets | Where-Object { $_.UUID -eq "abc12345-6789-abcd-ef01-234567890abc" }
$task | Format-List *
```

### V10 Reports
```powershell
# Stakeholder workload report
$global:V9Config.Stakeholders | ForEach-Object {
    $sh = $_
    $tasks = $global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq $sh }
    [PSCustomObject]@{
        Stakeholder = $sh
        TotalTasks = $tasks.Count
        ToDo = ($tasks | Where-Object { $_.Status -eq "To Do" }).Count
        InProgress = ($tasks | Where-Object { $_.Status -eq "In Progress" }).Count
        Done = ($tasks | Where-Object { $_.Status -eq "Done" }).Count
    }
} | Format-Table

# Initiative timeline
$global:V9Config.Initiatives | ForEach-Object {
    $init = $_
    $tasks = $global:V9Config.Tickets | Where-Object { $_.Initiative -eq $init.Name }
    [PSCustomObject]@{
        Initiative = $init.Name
        CreationDate = $init.CreationDate
        StartDate = if ($init.StartDate) { $init.StartDate } else { "TBD" }
        TotalTasks = $tasks.Count
        Status = if ($tasks.Count -eq 0) { "No tasks" } else { "Active" }
    }
} | Format-Table
```

## Complete Workflow Example

### Setup
```powershell
# Import and initialize
. .\helper2.ps1
Initialize-V9Config
```

### Add Stakeholders
```powershell
Add-Stakeholder -Name "Engineering"
Add-Stakeholder -Name "Product Team"
Add-Stakeholder -Name "QA Team"
List-Stakeholders
```

### Add Initiatives
```powershell
Add-Initiative -Name "Q4 Migration"
Add-Initiative -Name "Performance Improvements"
Add-Initiative -Name "Security Audit"
List-Initiatives
```

### Add Tasks
```powershell
# Add task for John (will prompt for all fields including stakeholder/initiative)
Add-TaskForPerson -PersonName "John"

# Add task for Sarah
Add-TaskForPerson -PersonName "Sarah"
```

### Query and Report
```powershell
# View all tasks for Engineering stakeholder
$global:V9Config.Tickets | 
    Where-Object { $_.Stakeholder -eq "Engineering" } |
    Format-Table ID, Description, Status, AssignedTeam, StartDate

# View all tasks in Q4 Migration initiative
$global:V9Config.Tickets | 
    Where-Object { $_.Initiative -eq "Q4 Migration" } |
    Format-Table ID, Description, Status, AssignedTeam, StartDate

# Get stakeholder summary
List-Stakeholders

# Get initiative summary
List-Initiatives
```

## Backward Compatibility

### V9 Files
When working with V9 config files (no V10 sections):
- UUID is still generated for new tasks
- Stakeholder/Initiative prompts are **skipped**
- V10 fields are **not added** to tickets
- Everything works as before

### V10 Files
When working with V10 config files (has STAKEHOLDERS/INITIATIVES sections):
- UUID is generated for new tasks
- Stakeholder/Initiative prompts are **shown**
- V10 fields are **added** to tickets
- Full V10 functionality available

## Detection Logic

The script automatically detects V10 format by checking:
1. **Existing tickets have UUID field**: `$global:V9Config.Tickets[0].UUID`
2. **Stakeholders array exists and has items**: `$global:V9Config.Stakeholders.Count -gt 0`
3. **Initiatives array exists and has items**: `$global:V9Config.Initiatives.Count -gt 0`

If **any** of these conditions are true, V10 features are enabled.

## UUID Format

UUIDs are generated using PowerShell's built-in GUID generator:
```powershell
$uuid = [guid]::NewGuid().ToString()
# Example: "abc12345-6789-abcd-ef01-234567890abc"
```

This matches the format used by the HTML console (JavaScript `crypto.randomUUID()`).

## Tips

### Bulk Add Stakeholders
```powershell
@("Engineering", "Product", "QA", "Marketing") | ForEach-Object {
    Add-Stakeholder -Name $_
}
```

### Bulk Add Initiatives
```powershell
@("Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025") | ForEach-Object {
    Add-Initiative -Name $_
}
```

### Export Task List with V10 Fields
```powershell
$global:V9Config.Tickets | 
    Select-Object ID, UUID, Description, Stakeholder, Initiative, Status, StartDate |
    Export-Csv -Path "tasks_v10.csv" -NoTypeInformation
```

---

**Status**: ✅ Fully Implemented
**Version**: V10 Support Complete
**Date**: October 16, 2025
**Compatibility**: 100% backward compatible with V9
