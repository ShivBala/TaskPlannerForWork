# 📊 HTML Task Tracker V10

A comprehensive task management system combining an interactive HTML console with PowerShell CLI interface. Features include capacity planning, stakeholder management, initiative tracking, smart routing with fuzzy matching, and Excel VBA integration.

## 🆕 Recent Updates (October 2025)

### Export Workflow Enhancement
- **Export Closed Button**: Separate button to export closed items before exporting full configuration
- **Smart Export Flow**: Mandatory closed items export prevents browser blocking multiple downloads
- **Dirty State Management**: Clear tracking of unsaved changes

### PowerShell V9 CSV Integration
- **Multi-Section CSV Format**: Supports METADATA, SETTINGS, TASK_SIZES, PEOPLE, TICKETS sections
- **Auto-Detection**: Automatically finds latest `project_config_*.csv` in Downloads folder
- **Full Round-Trip Support**: HTML → PowerShell → HTML with complete data preservation
- **Backward Compatible**: Existing helper.ps1 commands work seamlessly with V9 format

### Code Quality Improvements
- **Centralized End Date Calculation**: Single `calculateTaskEndDate()` function eliminates inconsistencies
- **Bug Fix**: Fixed-Length task end dates now calculate correctly (was adding 1 extra business day)
- **Consistent Logic**: All end date calculations now use same business day counting algorithm

## 🚀 Quick Start

## Features



### HTML Interface### 🎯 Priority Management

1. Open `html_console_v10.html` in any modern browser- **Intelligent Priority Conflict Resolution** with 4 resolution options:

2. Import CSV from Output folder or start fresh  1. Keep current priorities (reject new priority)

3. Add tasks, assign people, track progress  2. Move conflicting task to next available priority

  3. Cascade: Shift all tasks down from conflicting priority

### PowerShell CLI  4. Manual reorder (user chooses new priorities)

```powershell- **Configurable Priority Range** (1-9) with effort allocation analysis

# Navigate to project directory- **Comprehensive Audit Logging** with history snapshots

cd "/path/to/HTML Task Tracker"

### � Excel Export System (NEW!)

# Run helper2- **Phase 1**: Complete data export to Excel-compatible formats (COMPLETE)

pwsh ./helper2.ps1- **Phase 2**: VBA framework with interactive timeline navigation (COMPLETE)  

- **Timeline Navigation**: Step through 16 historical snapshots with keyboard shortcuts

# Quick commands- **Auto-Play Mode**: Automated progression through timeline data

qt                     # Quick task (minimal prompts)- **Data Export**: 283 records ready for Excel VBA dashboards

siva                   # Add/modify task for siva- **Case Normalization**: Handles inconsistent employee name formatting

stakeholder            # Manage stakeholders

initiative             # Manage initiatives### �🕒 ETA Management

initchart              # Generate initiative timeline- **Flexible ETA Updates** with date validation (dd/mm/yyyy format)

html                   # Open HTML console- **ETA Clearing** capability

help                   # Show all commands- **Dedicated ETA Change Logging**

```

### 📊 Reporting

## ✨ Key Features- **HTML Progress Reports** with visual progress bars

- **One-Page Banking Reports** for executive summaries

### V10 Enhancements- **Color-coded Priority Display** (P1=Red, P2=Yellow, P3=Cyan)

- ✅ **Stakeholders**: Organize tasks by business owner

- ✅ **Initiatives**: Group tasks into strategic initiatives with timeline charts### 🔍 Flexible Command Interface

- ✅ **UUID Tracking**: Unique identifier for every task- **Progressive Regex Matching** for natural command input

- ✅ **CreatedDate**: Track when tasks were created- **Concatenated Commands** support (e.g., `updpriovipul`, `uetasiva`)

- ✅ **Priority Picklist**: P1-P5 dropdown (no free text)- **Fuzzy Name Matching** for employee lookup

- ✅ **Size Picklist**: S/M/L/XL/XXL with predefined days

- ✅ **Quick Task**: Create tasks with minimal prompts (`qt` command)## Quick Start

- ✅ **Smart Router**: Intelligent command parsing with fuzzy matching

- ✅ **Auto-Reload**: PowerShell detects HTML changes automatically### Prerequisites

- PowerShell 7.0+

### Core Capabilities- CSV files for data storage

- **Capacity Planning**: Visual heat maps showing workload per person per week- Microsoft Excel (for VBA timeline features)

- **Timeline Projection**: Calculates end dates based on availability and task size

- **Fixed vs Flexible Tasks**: Two duration calculation modes### Setup

- **Task Details**: Add detailed descriptions, positives, negatives1. Clone this repository

- **Advanced Filtering**: By status, person, initiative, priority, date range2. Copy `task_progress_data.csv.template` to `task_progress_data.csv`

- **Bi-Directional Sync**: HTML and PowerShell share same CSV data3. Ensure `people_and_capacity.csv` exists with employee data

- **Auto-Backup**: All changes backed up to history/ folder4. Run `./helper.ps1` to start the interactive shell



## 📋 Prerequisites### Excel Export Quick Start

```powershell

- **PowerShell**: 7.0+ for CLI interface# Start interactive system

- **Browser**: Any modern browser for HTML console./helper.ps1

- **CSV**: Single data file in Output/ folder

# Export data for Excel (Phase 1)

## 📚 Documentationexcel     # or just 'e'



- **[V10_DOCUMENTATION.md](V10_DOCUMENTATION.md)**: Complete V10 guide (features, commands, testing, troubleshooting)# Create Excel VBA template (Phase 2)  

- **[VERSION_DIFFERENCES.md](VERSION_DIFFERENCES.md)**: Comparison of V9 vs V10template  # or just 't'

- **[TROUBLESHOOTING_FILE_LOCKED.md](TROUBLESHOOTING_FILE_LOCKED.md)**: Fix common CSV file issues

- **[tests/TEST_DOCUMENTATION.md](tests/TEST_DOCUMENTATION.md)**: Test suite documentation (271 tests)# Follow setup instructions in ExcelTaskTemplate/SETUP_INSTRUCTIONS.md

```

## 🧪 Testing

**Note**: Generated files (logs, reports, task data) are excluded from Git to keep the repository clean.

### Test Suite: 271 Tests (96.9% Pass Rate)

### Basic Usage

**HTML Tests** (226 tests):

```bash```powershell

# Start web server# Start the system

python -m http.server 8080./helper.ps1



# Open in browser# Add/modify tasks

http://localhost:8080/tests/test-runner.htmltask [name]                    # e.g., "task vipul"

```

# Update priorities

**PowerShell Tests** (45 tests):updatepriority [name]          # e.g., "updpriovipul"

```powershellupdpri [name]                  # Short form

./tests/powershell/helper2-tests.ps1

```# Update ETAs  

updateeta [name]               # e.g., "uetavipul"

### Test Coverageupeta [name]                   # Short form

- ✅ Core functionality: 100 tests

- ✅ V10 features: 31 tests (Stakeholders, Initiatives, UUID, Priority/Size picklists)# Generate reports

- ✅ Fixed-Length tasks: 64 testsreport                         # HTML progress report

- ✅ Task details: 20 testsonepage                        # One-page banking report

- ✅ PowerShell helper2: 45 tests (Smart router, fuzzy matching, validation)

# Excel Export System (NEW!)

## 📂 File Structureexcel                          # Export data for Excel (or just 'e')

template                       # Create Excel VBA template (or just 't')

``````

HTML Task Tracker/

├── html_console_v10.html          # Main HTML application## File Structure

├── helper2.ps1                     # PowerShell CLI interface

├── v9_csv_adapter.ps1             # CSV parser/writer```

├── initChart.html                 # Initiative timeline chart├── helper.ps1                      # Main system file

├── README.md                       # This file├── report-generator.ps1            # HTML report generator

├── V10_DOCUMENTATION.md            # Complete V10 documentation├── one-page-report-generator.ps1   # Banking report generator

│├── people_and_capacity.csv         # Employee database (source)

├── Output/                         # CSV data files├── task_progress_data.csv.template # Task database template

│   └── project_config_*.csv├── task_progress_data.csv          # Main task database (generated)

│├── priority-logs/                  # Priority change audit logs (generated)

├── history/                        # Backup files├── eta-logs/                       # ETA change audit logs (generated)

│   └── *.csv.backup_*├── history/                        # Historical snapshots (generated)

│├── reports/                        # Generated HTML reports (generated)

└── tests/                          # Test suite (271 tests)└── ExcelExport/                    # Excel integration system

    ├── test-runner.html    ├── export_to_excel.ps1         # Data export engine

    ├── node-test-runner.js    ├── create_excel_template.ps1    # Template creator (cross-platform)

    ├── TEST_DOCUMENTATION.md    ├── README.md                   # Complete Excel guide

    ├── html/    └── Data/                       # Generated Excel files (generated)

    │   ├── html-task-tracker-tests.js```

    │   ├── extended-task-tracker-tests.js

    │   └── v10-features-tests.js**Files marked as (generated) are excluded from Git and created during runtime.**

    └── powershell/

        └── helper2-tests.ps1## 📊 Excel Export System

```

### Phase 1: Data Export (COMPLETE)

## 🎯 Common TasksConverts your task tracking data into Excel-ready formats:



### Adding Tasks**Generated Files:**

- `current_tasks.csv` (~2KB) - Latest task snapshot

**Quick Task** (minimal prompts):- `historical_snapshots.csv` (~45KB) - Complete historical progression  

```powershell- `combined_timeline_data.csv` (~47KB) - **RECOMMENDED** for Excel VBA

qt                     # Description + stakeholder only- `metadata.json` (~3KB) - Export statistics

                       # Defaults: Unassigned, To Do, Tomorrow, M, P2

```### Phase 2: VBA Template System (COMPLETE)

Creates complete Excel framework with interactive timeline controls:

**Full Task** (all options):

```powershell**VBA Features:**

addtask                # Prompts for all fields- Timeline navigation through 16 snapshots

siva                   # Add/modify task for siva (smart router)- Auto-play mode (2-second intervals)

```- Keyboard shortcuts (Ctrl+Shift combinations)

- Employee filtering framework

### Managing Stakeholders & Initiatives- Progress tracking and visualization



```powershell**Keyboard Controls:**

stakeholder            # List/add/remove stakeholders- `Ctrl+Shift+I` - Initialize Timeline

initiative             # List/add/modify initiatives- `Ctrl+Shift+S` - Step Forward

initchart              # Generate initiative timeline chart (HTML)- `Ctrl+Shift+A` - Step Backward

```- `Ctrl+Shift+P` - Play/Pause Auto-advance

- `Ctrl+Shift+G` - Go to Specific Snapshot

### Checking Capacity- `Ctrl+Shift+R` - Reset Timeline



```powershell### Excel Setup (5-15 minutes)

capacity vipul         # Show weekly capacity for vipul1. **Export Data**: Run `excel` command in helper.ps1

availability           # Show who is most available today2. **Create Template**: Run `template` command

html                   # Open heat map in browser3. **Setup Excel**: Follow `ExcelTaskTemplate/SETUP_INSTRUCTIONS.md`

```4. **Import Data**: Load CSV files into Excel

5. **Add VBA**: Import provided VBA modules

## 🔧 Troubleshooting6. **Test**: Use keyboard shortcuts to navigate timeline



### CSV File Locked**📋 Complete documentation available in `ExcelExport/README.md`**

See [TROUBLESHOOTING_FILE_LOCKED.md](TROUBLESHOOTING_FILE_LOCKED.md) for solutions.

## Core Functions

### Tasks Not Showing

1. Check browser console (F12) for errors### Priority Management

2. Clear localStorage: `localStorage.clear()`- `Calculate-Priority` - Intelligent priority conflict resolution

3. Re-import CSV file- `Update-TaskPriority` - Interactive priority updates

- `Write-Priority-ChangeLog` - Audit logging

### PowerShell Commands Not Working

1. Run `reload` to refresh config### ETA Management  

2. Check spelling (case-insensitive)- `Update-ETA` - Interactive ETA management

3. Run `help` to see all commands- `Write-ETA-ChangeLog` - ETA change logging



### End Dates Show "N/A"### Task Management

1. Ensure tasks have assignees- `Add-TaskProgressEntry` - Add/modify tasks

2. Check person availability > 0- `Get-PersonActiveTasks` - Retrieve active tasks

3. Verify task has size (S/M/L/XL/XXL)- `Show-TaskList` - Display formatted task lists



For more troubleshooting, see [V10_DOCUMENTATION.md](V10_DOCUMENTATION.md#troubleshooting).### Reporting

- `Generate-HTMLReport` - Comprehensive HTML reports

## 🤝 Contributing- `Generate-OnePage-BankingReport` - Executive summaries



### Adding Features## Command Patterns

1. Implement in `html_console_v10.html` or `helper2.ps1`

2. Add tests to appropriate test fileThe system supports progressive regex matching for flexible input:

3. Update documentation

4. Run full test suite### Update Priority Commands

5. Commit with descriptive message- `updatepriority` → `updpri` → `upri` → `up`

- Examples: `updpriovipul`, `uprivipul`, `updatepriorityVipul`

### Code Style

- **HTML/JS**: 2-space indentation### Update ETA Commands  

- **PowerShell**: Verb-noun naming (Add-Task, Get-Person)- `updateeta` → `upeta` → `ueta` → `ue`

- **Tests**: Follow existing patterns- Examples: `updetavipul`, `uetasiva`, `updateetapeter`



## 📊 Version History## Data Format



### V10 (Current - October 2025)### Task Progress Data (CSV)

- ✅ Stakeholders & Initiatives management```csv

- ✅ UUID tracking, CreatedDate fieldEmployeeName,Task Description,Priority,StartDate,ETA,Progress,Status,ProgressReportSent,FinalReportSent,Created_Date

- ✅ Priority/Size picklists (P1-P5, S/M/L/XL/XXL)```

- ✅ Quick task command (`qt`)

- ✅ Smart router with fuzzy matching### People and Capacity Data (CSV)

- ✅ Auto-reload in PowerShell```csv

- ✅ Backup location moved to history/ folderName,Available Hours Week1,Available Hours Week2

- ✅ 271 automated tests (96.9% pass rate)```



### V9 (Legacy)## Audit and History

- Task tracking with capacity planning

- Heat map visualization### Priority Change Logs

- CSV export/import- Location: `priority-logs/priority-changes-YYYY-MM-DD.log`

- Fixed-Length vs Flexible tasks- Format: Timestamped entries with employee, task, and change details



---### ETA Change Logs  

- Location: `eta-logs/eta-changes-YYYY-MM-DD.log`

**Last Updated**: October 18, 2025  - Format: Timestamped entries with ETA modifications

**Version**: 10.0  

**Test Coverage**: 271 tests (96.9% pass rate)  ### History Snapshots

**Maintainer**: ShivBala- Location: `history/YYYY-MM-DD_HH-MM-SS_ACTION_Employee.csv`

- Purpose: Point-in-time data backups before modifications

## Priority Conflict Resolution

The system provides intelligent priority management with 4 resolution strategies:

1. **Reject** - Maintain existing priorities
2. **Move** - Relocate conflicting task to next available priority  
3. **Cascade** - Shift all lower-priority tasks down
4. **Manual** - User-guided priority reassignment

Each option includes effort allocation analysis showing impact on workload distribution.

## Development

### Architecture
- **Modular Design** with helper functions for code reuse
- **Progressive Enhancement** supporting various input patterns  
- **Comprehensive Error Handling** with user-friendly messages
- **Audit Trail** for all modifications

### Key Helper Functions
- `Get-MatchedPersonName()` - Centralized name resolution
- `Get-TaskSelection()` - Standardized task selection UI
- `Update-TaskInCSV()` - Unified CSV update operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with the interactive shell
5. Submit a pull request

## License

This project is part of a work task management system. Please ensure compliance with your organization's policies.