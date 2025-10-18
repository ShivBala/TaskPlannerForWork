# Task Tracker V10 - Complete Documentation

## 📚 Table of Contents
1. [Quick Start](#quick-start)
2. [PowerShell Helper2](#powershell-helper2)
3. [HTML Console](#html-console)
4. [V10 Features](#v10-features)
5. [Configuration](#configuration)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### For Users
1. **HTML Interface**: Open `html_console_v10.html` in any modern browser
2. **PowerShell CLI**: Run `pwsh helper2.ps1` for command-line interface
3. **Load Data**: Import CSV from Output folder or start fresh

### Key V10 Improvements
- ✅ **Stakeholders**: Organize tasks by business stakeholder
- ✅ **Initiatives**: Group tasks into strategic initiatives
- ✅ **UUID Tracking**: Unique identifier for every task
- ✅ **CreatedDate**: Track when tasks were created
- ✅ **Priority Picklist**: P1-P5 dropdown (no more free text)
- ✅ **Size Picklist**: S/M/L/XL/XXL dropdown with predefined days
- ✅ **Quick Task**: Create tasks with minimal prompts (`qt` command)
- ✅ **Smart Router**: Intelligent command parsing with fuzzy matching
- ✅ **Auto-Reload**: PowerShell detects HTML changes automatically

---

## PowerShell Helper2

### Installation
```powershell
# Navigate to project directory
cd "/path/to/HTML Task Tracker"

# Run helper2
pwsh ./helper2.ps1
```

### Core Commands

#### Task Management
```powershell
# Smart router: detects add or modify based on context
siva                    # Add/modify task for siva
sarah                   # Add/modify task for sarah

# Explicit commands
addtasksarah           # Add task for sarah
modifytaskjohn         # Modify task for john
addtask                # Add task (prompts for person)
modifytask             # Modify task (prompts for person)

# Quick task (minimal prompts)
qt                     # Quick task: description + stakeholder only
quick                  # Same as qt
quicktask              # Same as qt
```

**Quick Task Defaults**:
- Assigned: Unassigned (empty array)
- Initiative: General
- Status: To Do
- Start: Tomorrow
- Size: M (3 days)
- Priority: P2

#### V10 Management

**Stakeholders**:
```powershell
stakeholder            # List/add/remove stakeholders
addstakeholdersales    # Add "sales" stakeholder
removestakeholder      # Remove stakeholder
owners                 # Same as stakeholder
```

**Initiatives**:
```powershell
initiative             # List/add/modify initiatives
addinitiative          # Add new initiative
modifyinitiative       # Modify existing initiative
initiatives            # List all initiatives
```

**Initiative Chart**:
```powershell
initchart              # Generate timeline chart (HTML)
```

#### Capacity & Availability
```powershell
capacity vipul         # Show weekly capacity for vipul
availability           # Show who is most available today
```

#### System Commands
```powershell
html                   # Open HTML console in browser
console                # Same as html
reload                 # Reload config from CSV
help                   # Show all commands
exit                   # Exit helper
```

### Smart Router Features

The helper uses intelligent pattern matching to route commands.

**Pattern Recognition**:
- Detects person name → routes to task management
- Detects stakeholder keyword → routes to stakeholder management
- Detects initiative keyword → routes to initiative management
- Fuzzy matches names with scoring (70-100)

**Fuzzy Matching Algorithm**:
- **Exact match**: 100 points
- **First name match**: 90 points
- **Last name match**: 85 points
- **Contains substring**: 70 points
- **Threshold**: ≥70 to match

**Examples**:
```powershell
# These all work:
sarah                  # Matches "Sarah Thompson"
thompson               # Matches "Sarah Thompson"
sar                    # Matches "Sarah Thompson" (contains)
addtasksarah          # Explicit: add task for Sarah
modifystakeholdersales # Explicit: modify sales stakeholder
```

### Auto-Reload Feature

PowerShell automatically detects when HTML modifies the CSV:
- Checks file timestamp before showing dropdowns
- Reloads config if CSV was modified externally
- Seamless sync between HTML and PowerShell
- No manual `reload` needed (but still available)

### HTML Integration

**Opening HTML from PowerShell**:
```powershell
html                   # Opens html_console_v10.html in default browser
console                # Same as html
```

**Bi-Directional Sync**:
- PowerShell changes → HTML sees on next reload
- HTML changes → PowerShell auto-reloads
- Both use same CSV as single source of truth

---

## HTML Console

### Task Management

**Adding Tasks**:
1. Click "+ Add Task"
2. Fill in description (required)
3. Select size from picklist (S/M/L/XL/XXL)
4. Choose priority from picklist (P1-P5)
5. Assign people (multi-select with checkboxes)
6. Set stakeholder (dropdown)
7. Choose initiative (dropdown)
8. Set start date (calendar or text)
9. Toggle Fixed/Flexible task type

**Task Types**:
- **Fixed-Length** 🔒: Duration stays constant regardless of assignees
  - Example: 5-day task with 1 person = 5 days
  - Example: 5-day task with 5 people = 5 days (each works 20%)
- **Flexible** ⚡: Duration divides by number of assignees
  - Example: 5-day task with 1 person = 5 days
  - Example: 5-day task with 5 people = 1 day (each works 100%)

**Task Details**:
- Click ℹ️ icon to add detailed information
- **Fields**: Description, Positives, Negatives
- Useful for task planning and retrospectives
- Stored in CSV, survives reload

**Modifying Tasks**:
- Click on any task to edit inline
- Changes save automatically to CSV
- History preserved (Start Date, End Date, Size changes)

**Task Status**:
- To Do (default)
- In Progress
- Paused (with comments)
- Done
- Closed

### Capacity Planning

**Heat Map View**:
- Visual color coding:
  - 🟢 Green: <50% capacity
  - 🟡 Yellow: 50-100% capacity
  - 🔴 Red: >100% capacity (overallocated)
- Shows workload per person per week
- Identifies bottlenecks and overallocation
- Filters by status, person, initiative

**Timeline Projection**:
- Calculates end dates based on:
  - Person availability (hours/day)
  - Task size (days)
  - Number of assignees
  - Fixed vs Flexible task type
- Accounts for weekends (skips Saturday/Sunday)
- Handles multiple assignees correctly

### Filtering

**Filter Options**:
- **Status**: To Do, In Progress, Paused, Done, Closed
- **Person**: Any assigned person (includes unassigned)
- **Initiative**: Any initiative
- **Priority**: P1-P5
- **Date Range**: Custom start/end dates
- **Unassigned**: Show only tasks with no assignees

**Quick Filters**:
- Click person name → filter to that person
- Click initiative → filter to that initiative
- Click priority badge → filter to that priority
- Click "Clear Filters" to reset

### CSV Export/Import

**Export**:
1. Click "Export Data" → "Export to CSV"
2. All task details, history, metadata included
3. Compatible with PowerShell helper2
4. Backup automatically created

**Import**:
1. Automatically prompts on first load
2. Or click "Import from CSV"
3. Validates format and data integrity
4. Creates backup before overwriting in history/ folder

**Backup Location**:
- All backups saved to `history/` folder
- Format: `project_config_*.csv.backup_yyyyMMdd_HHmmss`
- Old location (Output/) no longer used

---

## V10 Features

### Stakeholders

**Purpose**: Organize tasks by business stakeholder or owner.

**Management** (HTML):
1. Click "Manage Stakeholders"
2. Add: Enter name, click "Add"
3. Remove: Click trash icon

**Management** (PowerShell):
```powershell
stakeholder            # List/add/remove
addstakeholdersales    # Add "sales"
```

**Usage**:
- Assign stakeholder when creating task
- Filter tasks by stakeholder
- See stakeholder workload in heat map

### Initiatives

**Purpose**: Group related tasks into strategic initiatives.

**Fields**:
- **Name**: Initiative name (required)
- **Start Date**: When initiative begins
- **Description**: Optional details

**Management** (HTML):
1. Click "Manage Initiatives"
2. Add: Fill in name, start date, description
3. Modify: Click edit icon, update fields
4. Delete: Click trash icon (only if no tasks assigned)

**Management** (PowerShell):
```powershell
initiative             # List all
addinitiative          # Add new
modifyinitiative       # Modify existing
```

**Initiative Chart**:
```powershell
initchart              # Generates HTML timeline chart
```

Shows:
- All initiatives on one page
- Visual timeline (Gantt-like)
- Duration and task count per initiative
- Color-coded progress

### UUID Tracking

Every task has a unique identifier (UUID):
- Generated automatically on creation
- Persists across modifications
- Useful for tracking task history
- Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`

**Backward Compatibility**:
- Old tasks without UUID get one on first load
- UUID never changes for same task

### CreatedDate

Tracks when task was originally created:
- Format: `yyyy-MM-dd`
- Set automatically on task creation
- Never changes (even when modified)
- Useful for sorting and reporting

**Backward Compatibility**:
- Old tasks without CreatedDate default to today

### Priority & Size Picklists

**Priority** (P1-P5):
- **P1**: Critical (highest)
- **P2**: High
- **P3**: Medium
- **P4**: Low
- **P5**: Lowest

**Size** (S/M/L/XL/XXL):
- **S**: Small (1 day)
- **M**: Medium (3 days)
- **L**: Large (5 days)
- **XL**: Extra Large (10 days)
- **XXL**: Extra Extra Large (15 days)

**Configuration**:
- Sizes defined in CSV TASK_SIZES section
- Can be customized per project
- PowerShell validates against config

---

## Configuration

### CSV Structure (V10)

The project uses a single CSV file with 6 sections:

#### 1. METADATA
```csv
METADATA
HoursPerDay,8
```

#### 2. PEOPLE
```csv
PEOPLE
Name,Availability
Siva,8
Sarah,8
Vipul,6
```

#### 3. TASK_SIZES
```csv
TASK_SIZES
Key,Days,Description
S,1,Small
M,3,Medium
L,5,Large
XL,10,Extra Large
XXL,15,Extra Extra Large
```

#### 4. STAKEHOLDERS
```csv
STAKEHOLDERS
Name
Sales
Marketing
Engineering
```

#### 5. INITIATIVES
```csv
INITIATIVES
Name,StartDate,Description
Q4 Revenue,2025-10-01,Quarterly revenue initiative
Platform Upgrade,2025-11-01,Technical infrastructure upgrade
```

#### 6. TICKETS
```csv
TICKETS
UUID,ID,Description,StartDate,Size,Priority,Stakeholder,Initiative,AssignedTeam,Status,TaskType,PauseComments,StartDateHistory,EndDateHistory,SizeHistory,CustomEndDate,CreatedDate,DetailsDescription,DetailsPositives,DetailsNegatives
...
```

**Ticket Fields** (20 columns):
- **UUID**: Unique identifier (v4 UUID)
- **ID**: Sequential number (e.g., "TASK-1")
- **Description**: Task description
- **StartDate**: When task starts (yyyy-MM-dd)
- **Size**: S/M/L/XL/XXL
- **Priority**: P1-P5
- **Stakeholder**: Business owner
- **Initiative**: Strategic initiative
- **AssignedTeam**: JSON array of assignees `["Person1","Person2"]`
- **Status**: To Do / In Progress / Paused / Done / Closed
- **TaskType**: Fixed-Length / Flexible
- **PauseComments**: Why task is paused
- **StartDateHistory**: Array of past start dates
- **EndDateHistory**: Array of past end dates
- **SizeHistory**: Array of past sizes
- **CustomEndDate**: Override calculated end date
- **CreatedDate**: When task was created (yyyy-MM-dd)
- **DetailsDescription**: Detailed task description
- **DetailsPositives**: Positive aspects/learnings
- **DetailsNegatives**: Challenges/risks

### Backward Compatibility

V10 automatically upgrades older formats:
- V9 configs load successfully
- Missing fields use smart defaults:
  - UUID: Generated on load
  - CreatedDate: Today's date
  - Stakeholder: "General"
  - Initiative: "General"
  - Priority: "P2"
  - Size: "M"

---

## Testing

### Test Suite Overview

**Total Tests**: 271 automated tests
- **HTML Tests**: 226 tests (96.9% pass rate)
- **PowerShell Tests**: 45 tests (100% expected)

### Running HTML Tests

```bash
# Start web server
python -m http.server 8080

# Open in browser
http://localhost:8080/tests/test-runner.html
```

**Test Files**:
- `html-task-tracker-tests.js`: Core functionality (100 tests)
- `extended-task-tracker-tests.js`: Advanced features (95 tests)
- `v10-features-tests.js`: V10 features (31 tests)

**V10 Test Coverage**:
- ✅ Stakeholder Management (6 tests)
- ✅ Initiative Management (8 tests)
- ✅ UUID Tracking (4 tests)
- ✅ CreatedDate Tracking (4 tests)
- ✅ Initiative Chart (3 tests)
- ✅ Priority Picklist (3 tests)
- ✅ Size Picklist (3 tests)

### Running PowerShell Tests

```powershell
./tests/powershell/helper2-tests.ps1
```

**Test Coverage**:
- ✅ Smart Router (5 tests)
- ✅ Fuzzy Matching (5 tests)
- ✅ Stakeholder Management (3 tests)
- ✅ Initiative Management (4 tests)
- ✅ Quick Task Feature (4 tests)
- ✅ Auto-Reload (3 tests)
- ✅ Date Parsing (4 tests)
- ✅ Priority/Size Validation (10 tests)
- ✅ CSV Operations (3 tests)
- ✅ Helper Commands (4 tests)

**Known Test Failures**:
- 3 localStorage tests (HTML feature not PowerShell concern)
- 3 heat map edge cases (acceptable behavior)

### Test Documentation

See `tests/TEST_DOCUMENTATION.md` for:
- Detailed test descriptions
- How to add new tests
- Test patterns and conventions
- Debugging failed tests

---

## Troubleshooting

### CSV File Issues

**Problem**: "File is locked" error when saving
**Solution**:
1. Close Excel/CSV editor
2. Check file permissions
3. Run PowerShell as administrator (Windows)
4. Verify no other process has file open

**Problem**: CSV format corrupted
**Solution**:
1. Check for missing section headers (METADATA, PEOPLE, etc.)
2. Verify no commas in description fields (escape with quotes)
3. Restore from backup in history/ folder
4. Use CSV validation in HTML ("Validate CSV")

### HTML Console Issues

**Problem**: Blank page or no tasks showing
**Solution**:
1. Open browser console (F12) for errors
2. Clear localStorage: `localStorage.clear()`
3. Re-import CSV file
4. Check CSV format (use text editor to inspect)

**Problem**: Tasks not saving
**Solution**:
1. Verify CSV file path is correct
2. Check write permissions on Output/ folder
3. Look for JavaScript errors in console
4. Try exporting to new CSV file

**Problem**: Heat map not updating
**Solution**:
1. Refresh page (F5)
2. Check if tasks have valid start dates
3. Verify people have availability > 0
4. Clear filters (might be hiding tasks)

### PowerShell Helper Issues

**Problem**: "Config file not found"
**Solution**:
1. Check `Output/` folder exists
2. Verify CSV file is present in Output/
3. Run `reload` command
4. Check file path in error message

**Problem**: Commands not recognized
**Solution**:
1. Run `help` to see available commands
2. Check spelling (case-insensitive)
3. Try full command (e.g., `addtask` instead of just name)
4. Restart helper: `exit` then `pwsh helper2.ps1`

**Problem**: Fuzzy matching not working
**Solution**:
1. Use full name (first or last)
2. Check person exists in CSV
3. Try explicit command (`addtasksarah`)
4. Run `reload` to refresh config

### Task Calculation Issues

**Problem**: End dates show as "N/A"
**Solution**:
1. Ensure tasks have assignees (or mark as unassigned)
2. Check person availability > 0 in CSV
3. Verify start date is valid (not in past)
4. Check task size is set (S/M/L/XL/XXL)

**Problem**: Wrong end date calculation
**Solution**:
1. Check task type (Fixed vs Flexible)
2. Verify number of assignees
3. Check person availability (hours/day)
4. Use Custom End Date to override if needed

**Problem**: Initiatives not showing in dropdown
**Solution**:
- **In HTML**: Wait for auto-save (2 seconds), then reload page
- **In PowerShell**: Run `reload` or wait for auto-reload (checks file timestamp)

### Performance Issues

**Problem**: HTML console slow with many tasks
**Solution**:
1. Use filters to reduce visible tasks
2. Close old/done tasks
3. Archive completed tasks to separate CSV
4. Split large projects into multiple CSVs

**Problem**: Heat map rendering slow
**Solution**:
1. Filter by person or date range
2. Hide closed tasks
3. Reduce number of weeks displayed
4. Use simpler view (list instead of heat map)

---

## File Structure

```
HTML Task Tracker/
├── html_console_v10.html          # Main HTML application
├── helper2.ps1                     # PowerShell CLI interface
├── v9_csv_adapter.ps1             # CSV parser/writer
├── initChart.html                 # Initiative timeline chart
├── README.md                       # Project README
├── V10_DOCUMENTATION.md            # This file
│
├── Output/                         # CSV data files
│   └── project_config_*.csv
│
├── history/                        # Backup files
│   └── *.csv.backup_*
│
└── tests/                          # Test suite
    ├── test-runner.html            # HTML test runner
    ├── node-test-runner.js         # Node test runner
    ├── TEST_DOCUMENTATION.md       # Test documentation
    ├── html/
    │   ├── html-task-tracker-tests.js
    │   ├── extended-task-tracker-tests.js
    │   └── v10-features-tests.js
    └── powershell/
        └── helper2-tests.ps1
```

---

## Version History

### V10 (Current - October 2025)
- ✅ **Stakeholders**: Business owner tracking
- ✅ **Initiatives**: Strategic initiative grouping
- ✅ **UUID Tracking**: Unique identifier for every task
- ✅ **CreatedDate**: Task creation timestamp
- ✅ **Priority Picklist**: P1-P5 dropdown (no free text)
- ✅ **Size Picklist**: S/M/L/XL/XXL dropdown with days
- ✅ **Quick Task**: Minimal prompt task creation (`qt`)
- ✅ **Smart Router**: Intelligent command parsing
- ✅ **Fuzzy Matching**: Name matching with scoring
- ✅ **Auto-Reload**: PowerShell detects HTML changes
- ✅ **Backup Location**: Moved to history/ folder
- ✅ **Test Suite**: 271 automated tests (96.9% pass rate)

### V9 (Legacy)
- Task tracking with capacity planning
- Heat map visualization
- CSV export/import
- Person management
- Fixed-Length vs Flexible tasks
- Task Details feature

---

## Advanced Tips

### Batch Operations

**PowerShell**:
```powershell
# Add multiple tasks quickly using qt
qt  # Task 1
qt  # Task 2
qt  # Task 3
```

**HTML**:
- Use Ctrl+Enter to save task and immediately add another
- Use Tab key to navigate between fields
- Use arrow keys in dropdowns

### Keyboard Shortcuts

**HTML Console**:
- `Ctrl+F`: Focus filter box
- `Esc`: Clear current selection
- `Enter`: Save inline edit
- `Tab`: Next field

**PowerShell**:
- `Ctrl+C`: Cancel current operation
- `Ctrl+L`: Clear screen
- Up/Down arrows: Command history

### Custom Workflows

**Example: Sprint Planning**:
1. Create initiative for sprint
2. Use `qt` to quickly add all sprint tasks
3. Assign stakeholders and priorities
4. Run `initchart` to visualize timeline
5. Check capacity with heat map
6. Adjust assignments to balance workload

**Example: Weekly Review**:
1. Filter to "In Progress" tasks
2. Update task status
3. Add pause comments for blocked tasks
4. Check who is most available: `availability`
5. Assign new tasks to available people

---

## Contributing

### Adding New Features
1. Implement in `html_console_v10.html` or `helper2.ps1`
2. Add tests to appropriate test file
3. Update this documentation
4. Run full test suite
5. Commit with descriptive message

### Code Style
- **HTML/JS**: Use consistent indentation (2 spaces)
- **PowerShell**: Use verb-noun naming (Add-Task, Get-Person)
- **Comments**: Document complex logic thoroughly
- **Tests**: Follow existing test patterns

---

**Last Updated**: October 18, 2025  
**Version**: 10.0  
**Maintainer**: ShivBala  
**Test Coverage**: 271 tests (96.9% pass rate)
