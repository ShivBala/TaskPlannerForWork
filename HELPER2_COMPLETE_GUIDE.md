# helper2.ps1 - Complete Feature Summary ✅

## Overview

`helper2.ps1` is a clean, V9-only PowerShell interface for `html_console_v9.html` with **exact HTML calculation matching** and **automatic HTML console opening** for unrecognized commands.

---

## Key Features

### 1. **Regex-Based Task Management**

**Person Names**: `siva`, `vipul`, `peter`, `sameet`, `sharanya`, `divya`

```powershell
helper2> vipul
→ Add or Modify task?
  1. Add
  2. Modify
```

#### Add Task Flow
- ✅ Description (required)
- ✅ Status: Numbered choice
  - 1 = To Do (default start: tomorrow)
  - 2 = In Progress (default start: today)
- ✅ **Smart Defaults**:
  - Size: M (Medium)
  - Priority: P2
  - TaskType: Fixed
  - Start Date: Conditional (tomorrow for To Do, today for In Progress)
- ✅ **Date Aliases**: today, tomorrow, yesterday, next/last [day of week]

#### Modify Task Flow
- Shows active tasks (numbered)
- Update: Status, Priority, Size, or Description

---

### 2. **Capacity Query** (HTML-Matching)

```powershell
helper2> capacity vipul
```

**Output:**
```
📊 Weekly Capacity for Vipul
   Week: Oct 14 - Oct 20, 2025
   
   Total Capacity: 25.0 hours/week
   Assigned: 12.5 hours (2 tasks)
   Available: 12.5 hours
   Utilization: 50%
   
   Active Tasks:
     [P1] Frontend Redesign (8.0h, In Progress)
     [P2] Bug fixes (4.5h, To Do)
```

**Uses:**
- Hours-based calculation
- Business days only (Mon-Fri)
- Overlap detection with current week
- Fixed vs Flexible task handling

---

### 3. **Availability Query** (HTML-Matching)

```powershell
helper2> availability
```

**Output:**
```
👥 Team Availability (Current Week)
   Tuesday, October 15, 2025
   
   Vipul         Available: 12.5h/25h (50% utilized, 2 tasks)
   Peter         Available: 10.0h/25h (60% utilized, 3 tasks)
   Sameet        Available: 5.0h/25h (80% utilized, 4 tasks)
   Siva          Available: 0.0h/25h (100% utilized, 5 tasks)
   
   🌟 Most Available: Vipul (12.5h free, 50% utilized)
```

---

### 4. **Automatic HTML Console Opening** 🆕

**Any unrecognized command opens the HTML console!**

```powershell
helper2> dashboard
→ 🌐 Opening HTML Console...

helper2> reports
→ 🌐 Opening HTML Console...

helper2> anything
→ 🌐 Opening HTML Console...
```

**Explicit commands:**
```powershell
helper2> html       # Opens HTML
helper2> console    # Opens HTML
helper2> open       # Opens HTML
```

This makes it super easy to access advanced features like:
- Visual dashboards
- Gantt charts
- Capacity heatmaps
- Detailed reports
- Export/import functions

---

### 5. **System Commands**

```powershell
helper2> reload     # Reload config from Downloads
helper2> help       # Show available commands
helper2> exit       # Exit helper
```

---

## HTML Calculation Matching

### Hours-Based System ✅
- **Not days** - Uses hours per week
- Default: 25 hours/week (5 days × 5 hours)
- Reads from `projectHoursPerDay` setting

### 8-Week Availability Arrays ✅
- Each person has 8-week forecast
- Example: `[25, 25, 25, 25, 25, 25, 25, 25]`
- Auto-initialized if missing

### Business Days Calculation ✅
- Only Monday-Friday counted
- Weekend dates adjusted to Monday
- Overlap detection with current week

### Fixed vs Flexible Tasks ✅
- **Fixed-Length**: Capacity scales, duration fixed
- **Flexible**: Duration splits, full capacity per person

### Utilization Colors ✅
- 🟢 Green: 0-60%
- 🟡 Yellow: 61-90%
- 🔴 Red: 91%+ or overload (999%)

---

## Usage Examples

### Quick Task Add (All Defaults)
```powershell
helper2> vipul
Choose: 1
Description: Fix login bug
Status: 2
Size: [Enter]       # Uses M
Start: [Enter]      # Uses today (In Progress)
→ ✅ Task added!
```

### Check Team Availability
```powershell
helper2> availability
→ Shows who's most available with exact hours
```

### Check Specific Person
```powershell
helper2> capacity peter
→ Shows Peter's weekly capacity breakdown
```

### Access Advanced Features
```powershell
helper2> gantt
→ Opens HTML console (has Gantt chart)

helper2> heatmap
→ Opens HTML console (has capacity heatmap)
```

---

## Command Summary Table

| Command | Action | Opens HTML? |
|---------|--------|-------------|
| `vipul`, `peter`, etc. | Add/modify task | No |
| `capacity <name>` | Show capacity | No |
| `availability` | Show availability | No |
| `html`, `console`, `open` | Open HTML explicitly | ✅ Yes |
| `reload` | Reload config | No |
| `help` | Show help | No |
| `exit` | Exit | No |
| **Any other input** | Default handler | ✅ Yes |

---

## Technical Details

### Calculation Functions
- `Get-BusinessDays`: Counts Mon-Fri between dates
- `Add-BusinessDays`: Adds N business days to date
- `Adjust-DateToWeekday`: Moves weekends to Monday
- `Get-TaskEffortHours`: Converts size to hours

### Date Parsing
Supports natural language:
- `today`, `tomorrow`, `yesterday`
- `next monday`, `next friday`
- `last tuesday`, `last wednesday`
- `YYYY-MM-DD` format

### Config Loading
- Auto-finds latest `project_config_*.csv` in Downloads
- Reads `projectHoursPerDay` from SETTINGS
- Initializes 8-week availability arrays
- Creates backups on save

---

## Files Structure

```
helper2.ps1                    # Main script
v9_csv_adapter.ps1            # CSV parser (imported)
html_console_v9.html          # Opened for advanced features
project_config_*.csv          # V9 config (in Downloads)
```

---

## Benefits

### ✅ **For Quick Tasks**
- Fast CLI interface
- Smart defaults
- No mouse needed
- Instant capacity checks

### ✅ **For Advanced Work**
- One word opens HTML console
- Full visual interface available
- Seamless transition
- No context switching needed

### ✅ **Calculation Accuracy**
- 100% matches HTML
- Same formulas
- Same thresholds
- Same business logic

---

## Getting Started

```powershell
# Start helper2
pwsh ./helper2.ps1

# Add a task quickly
helper2> vipul
[Follow prompts with Enter for defaults]

# Check availability
helper2> availability

# Open HTML for visuals
helper2> dashboard
```

**That's it!** Use the CLI for quick tasks, and any unrecognized command opens the HTML console for advanced features. 🎉

---

## Troubleshooting

### Config File Locked
If you see "file is being used by another process":
1. Close Excel if config is open
2. Close browser tabs with HTML console
3. Run `reload` in helper2

### HTML Not Opening
- Check `html_console_v9.html` exists in same folder
- On Mac: Uses `open` command
- On Linux: Uses `xdg-open`
- On Windows: Uses default file association

### Calculations Don't Match
- Ensure latest config is exported from HTML
- Check `projectHoursPerDay` setting
- Verify person availability arrays initialized
- Run `reload` to refresh data

---

## Summary

`helper2.ps1` is the **perfect companion** to `html_console_v9.html`:
- ✅ Quick CLI for common tasks
- ✅ HTML-accurate calculations
- ✅ Automatic HTML opening for everything else
- ✅ Clean, focused, V9-only design

**Best of both worlds!** 🚀
