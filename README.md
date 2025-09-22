# Task Planner for Work

A comprehensive PowerShell-based task management system with intelligent priority conflict resolution, ETA tracking, and HTML reporting capabilities.

## Features

### 🎯 Priority Management
- **Intelligent Priority Conflict Resolution** with 4 resolution options:
  1. Keep current priorities (reject new priority)
  2. Move conflicting task to next available priority
  3. Cascade: Shift all tasks down from conflicting priority
  4. Manual reorder (user chooses new priorities)
- **Configurable Priority Range** (1-9) with effort allocation analysis
- **Comprehensive Audit Logging** with history snapshots

### 🕒 ETA Management
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

### Setup
1. Clone this repository
2. Copy `task_progress_data.csv.template` to `task_progress_data.csv`
3. Ensure `people_and_capacity.csv` exists with employee data
4. Run `./helper.ps1` to start the interactive shell

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
└── reports/                        # Generated HTML reports (generated)
```

**Files marked as (generated) are excluded from Git and created during runtime.**

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