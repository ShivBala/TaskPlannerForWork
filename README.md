# 📊 HTML Task Tracker with Excel Export System

A comprehensive PowerShell-based task management system with intelligent priority conflict resolution, ETA tracking, HTML reporting capabilities, and advanced Excel VBA integration.

## Features

### 🎯 Priority Management
- **Intelligent Priority Conflict Resolution** with 4 resolution options:
  1. Keep current priorities (reject new priority)
  2. Move conflicting task to next available priority
  3. Cascade: Shift all tasks down from conflicting priority
  4. Manual reorder (user chooses new priorities)
- **Configurable Priority Range** (1-9) with effort allocation analysis
- **Comprehensive Audit Logging** with history snapshots

### � Excel Export System (NEW!)
- **Phase 1**: Complete data export to Excel-compatible formats (COMPLETE)
- **Phase 2**: VBA framework with interactive timeline navigation (COMPLETE)  
- **Timeline Navigation**: Step through 16 historical snapshots with keyboard shortcuts
- **Auto-Play Mode**: Automated progression through timeline data
- **Data Export**: 283 records ready for Excel VBA dashboards
- **Case Normalization**: Handles inconsistent employee name formatting

### �🕒 ETA Management
- **Flexible ETA Updates** with date validation (dd/mm/yyyy format)
- **ETA Clearing** capability
- **Dedicated ETA Change Logging**

### 📊 Reporting
- **HTML Progress Reports** with visual progress bars
- **One-Page Banking Reports** for executive summaries
- **Color-coded Priority Display** (P1=Red, P2=Yellow, P3=Cyan)

### 🔍 Flexible Command Interface
- **Progressive Regex Matching** for natural command input
- **Concatenated Commands** support (e.g., `updpriovipul`, `uetasiva`)
- **Fuzzy Name Matching** for employee lookup

## Quick Start

### Prerequisites
- PowerShell 7.0+
- CSV files for data storage
- Microsoft Excel (for VBA timeline features)

### Setup
1. Clone this repository
2. Copy `task_progress_data.csv.template` to `task_progress_data.csv`
3. Ensure `people_and_capacity.csv` exists with employee data
4. Run `./helper.ps1` to start the interactive shell

### Excel Export Quick Start
```powershell
# Start interactive system
./helper.ps1

# Export data for Excel (Phase 1)
excel     # or just 'e'

# Create Excel VBA template (Phase 2)  
template  # or just 't'

# Follow setup instructions in ExcelTaskTemplate/SETUP_INSTRUCTIONS.md
```

**Note**: Generated files (logs, reports, task data) are excluded from Git to keep the repository clean.

### Basic Usage

```powershell
# Start the system
./helper.ps1

# Add/modify tasks
task [name]                    # e.g., "task vipul"

# Update priorities
updatepriority [name]          # e.g., "updpriovipul"
updpri [name]                  # Short form

# Update ETAs  
updateeta [name]               # e.g., "uetavipul"
upeta [name]                   # Short form

# Generate reports
report                         # HTML progress report
onepage                        # One-page banking report

# Excel Export System (NEW!)
excel                          # Export data for Excel (or just 'e')
template                       # Create Excel VBA template (or just 't')
```

## File Structure

```
├── helper.ps1                      # Main system file
├── report-generator.ps1            # HTML report generator
├── one-page-report-generator.ps1   # Banking report generator
├── people_and_capacity.csv         # Employee database (source)
├── task_progress_data.csv.template # Task database template
├── task_progress_data.csv          # Main task database (generated)
├── priority-logs/                  # Priority change audit logs (generated)
├── eta-logs/                       # ETA change audit logs (generated)
├── history/                        # Historical snapshots (generated)
├── reports/                        # Generated HTML reports (generated)
└── ExcelExport/                    # Excel integration system
    ├── export_to_excel.ps1         # Data export engine
    ├── create_excel_template.ps1    # Template creator (cross-platform)
    ├── README.md                   # Complete Excel guide
    └── Data/                       # Generated Excel files (generated)
```

**Files marked as (generated) are excluded from Git and created during runtime.**

## 📊 Excel Export System

### Phase 1: Data Export (COMPLETE)
Converts your task tracking data into Excel-ready formats:

**Generated Files:**
- `current_tasks.csv` (~2KB) - Latest task snapshot
- `historical_snapshots.csv` (~45KB) - Complete historical progression  
- `combined_timeline_data.csv` (~47KB) - **RECOMMENDED** for Excel VBA
- `metadata.json` (~3KB) - Export statistics

### Phase 2: VBA Template System (COMPLETE)
Creates complete Excel framework with interactive timeline controls:

**VBA Features:**
- Timeline navigation through 16 snapshots
- Auto-play mode (2-second intervals)
- Keyboard shortcuts (Ctrl+Shift combinations)
- Employee filtering framework
- Progress tracking and visualization

**Keyboard Controls:**
- `Ctrl+Shift+I` - Initialize Timeline
- `Ctrl+Shift+S` - Step Forward
- `Ctrl+Shift+A` - Step Backward
- `Ctrl+Shift+P` - Play/Pause Auto-advance
- `Ctrl+Shift+G` - Go to Specific Snapshot
- `Ctrl+Shift+R` - Reset Timeline

### Excel Setup (5-15 minutes)
1. **Export Data**: Run `excel` command in helper.ps1
2. **Create Template**: Run `template` command
3. **Setup Excel**: Follow `ExcelTaskTemplate/SETUP_INSTRUCTIONS.md`
4. **Import Data**: Load CSV files into Excel
5. **Add VBA**: Import provided VBA modules
6. **Test**: Use keyboard shortcuts to navigate timeline

**📋 Complete documentation available in `ExcelExport/README.md`**

## Core Functions

### Priority Management
- `Calculate-Priority` - Intelligent priority conflict resolution
- `Update-TaskPriority` - Interactive priority updates
- `Write-Priority-ChangeLog` - Audit logging

### ETA Management  
- `Update-ETA` - Interactive ETA management
- `Write-ETA-ChangeLog` - ETA change logging

### Task Management
- `Add-TaskProgressEntry` - Add/modify tasks
- `Get-PersonActiveTasks` - Retrieve active tasks
- `Show-TaskList` - Display formatted task lists

### Reporting
- `Generate-HTMLReport` - Comprehensive HTML reports
- `Generate-OnePage-BankingReport` - Executive summaries

## Command Patterns

The system supports progressive regex matching for flexible input:

### Update Priority Commands
- `updatepriority` → `updpri` → `upri` → `up`
- Examples: `updpriovipul`, `uprivipul`, `updatepriorityVipul`

### Update ETA Commands  
- `updateeta` → `upeta` → `ueta` → `ue`
- Examples: `updetavipul`, `uetasiva`, `updateetapeter`

## Data Format

### Task Progress Data (CSV)
```csv
EmployeeName,Task Description,Priority,StartDate,ETA,Progress,Status,ProgressReportSent,FinalReportSent,Created_Date
```

### People and Capacity Data (CSV)
```csv
Name,Available Hours Week1,Available Hours Week2
```

## Audit and History

### Priority Change Logs
- Location: `priority-logs/priority-changes-YYYY-MM-DD.log`
- Format: Timestamped entries with employee, task, and change details

### ETA Change Logs  
- Location: `eta-logs/eta-changes-YYYY-MM-DD.log`
- Format: Timestamped entries with ETA modifications

### History Snapshots
- Location: `history/YYYY-MM-DD_HH-MM-SS_ACTION_Employee.csv`
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