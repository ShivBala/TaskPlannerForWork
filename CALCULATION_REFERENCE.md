# Task Planner Calculation Logic Reference
## Single Source of Truth for JavaScript & PowerShell Implementations

**Version:** 1.0  
**Last Updated:** 2025-10-19  
**Purpose:** Reference document for maintaining calculation consistency across JavaScript and PowerShell

---

## 📋 Core Principles

1. **Single Source of Truth**: All calculations in this document represent the definitive logic
2. **No Duplication**: Logic should NOT be duplicated - use these functions/formulas everywhere
3. **Cross-Platform**: These formulas must work identically in JavaScript and PowerShell
4. **Business Days Only**: All calculations use Monday-Friday (skip weekends)

---

## 🔧 Core Calculation Functions

### 1. Calculate Business Days Between Dates

**Purpose:** Count the number of business days (Mon-Fri) between two dates (inclusive)

**Formula:**
```
FOR each day FROM startDate TO endDate:
    IF dayOfWeek is Monday (1) through Friday (5):
        businessDays++
RETURN businessDays
```

**JavaScript Reference:** `calculateBusinessDays(startDate, endDate)`
- Location: `html_console_v10.html` line ~6495
- Returns: Integer (number of business days)

**PowerShell Implementation:**
```powershell
function Get-BusinessDaysBetween {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    
    $businessDays = 0
    $currentDate = $StartDate
    
    while ($currentDate -le $EndDate) {
        $dayOfWeek = $currentDate.DayOfWeek.value__
        # Monday=1, Friday=5
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) {
            $businessDays++
        }
        $currentDate = $currentDate.AddDays(1)
    }
    
    return $businessDays
}
```

---

### 2. Add Business Days to a Date

**Purpose:** Add N business days to a date, skipping weekends

**Formula:**
```
result = startDate
daysAdded = 0

WHILE daysAdded < businessDaysToAdd:
    result = result + 1 day
    IF dayOfWeek(result) is Monday-Friday:
        daysAdded++

RETURN result
```

**JavaScript Reference:** `addBusinessDays(startDate, businessDaysToAdd)`
- Location: `html_console_v10.html` line ~6508
- Returns: Date object

**PowerShell Implementation:**
```powershell
function Add-BusinessDays {
    param(
        [DateTime]$StartDate,
        [int]$BusinessDaysToAdd
    )
    
    $result = $StartDate
    $daysAdded = 0
    
    while ($daysAdded -lt $BusinessDaysToAdd) {
        $result = $result.AddDays(1)
        $dayOfWeek = $result.DayOfWeek.value__
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) {
            $daysAdded++
        }
    }
    
    return $result
}
```

---

### 3. Move Weekend Date to Next Monday

**Purpose:** If a date falls on a weekend, move it to the next Monday

**Formula:**
```
IF date is Sunday (0):
    date = date + 1 day (Monday)
ELSE IF date is Saturday (6):
    date = date + 2 days (Monday)
ELSE:
    date unchanged (already a business day)
    
RETURN date
```

**JavaScript Reference:** `getNextBusinessDay(date)`
- Location: `html_console_v10.html` line ~6523
- Returns: Date object

**PowerShell Implementation:**
```powershell
function Get-NextBusinessDay {
    param([DateTime]$Date)
    
    $result = $Date
    $dayOfWeek = $result.DayOfWeek.value__
    
    if ($dayOfWeek -eq 0) {
        # Sunday -> Monday
        $result = $result.AddDays(1)
    }
    elseif ($dayOfWeek -eq 6) {
        # Saturday -> Monday
        $result = $result.AddDays(2)
    }
    
    return $result
}
```

---

### 4. Find Previous Monday from Date

**Purpose:** Find the Monday of the week containing a given date

**Formula:**
```
result = date
WHILE dayOfWeek(result) != Monday (1):
    result = result - 1 day
RETURN result
```

**JavaScript Reference:** `getPreviousMonday(date)`
- Location: `html_console_v10.html` line ~6535
- Returns: Date object

**PowerShell Implementation:**
```powershell
function Get-PreviousMonday {
    param([DateTime]$Date)
    
    $result = $Date
    while ($result.DayOfWeek.value__ -ne 1) {
        $result = $result.AddDays(-1)
    }
    
    return $result
}
```

---

### 5. Calculate Heat Map Baseline Date

**Purpose:** Find the Monday that starts Week 1 of the heat map (earliest task week)

**Formula:**
```
IF no tickets:
    RETURN getPreviousMonday(today)

earliestTaskDate = null

FOR each ticket:
    adjustedStart = getNextBusinessDay(ticket.startDate)
    IF adjustedStart < earliestTaskDate OR earliestTaskDate is null:
        earliestTaskDate = adjustedStart

RETURN getPreviousMonday(earliestTaskDate)
```

**JavaScript Reference:** `getHeatMapBaselineDate(tickets)`
- Location: `html_console_v10.html` line ~6547
- Returns: Date object (always a Monday)

**PowerShell Implementation:**
```powershell
function Get-HeatMapBaselineDate {
    param([array]$Tickets)
    
    if ($Tickets.Count -eq 0) {
        return Get-PreviousMonday (Get-Date)
    }
    
    $earliestTaskDate = $null
    
    foreach ($ticket in $Tickets) {
        $adjustedStart = Get-NextBusinessDay $ticket.StartDate
        if ($null -eq $earliestTaskDate -or $adjustedStart -lt $earliestTaskDate) {
            $earliestTaskDate = $adjustedStart
        }
    }
    
    return Get-PreviousMonday $earliestTaskDate
}
```

---

### 6. Calculate Week Date Range

**Purpose:** Get the start and end dates for a specific week index

**Formula:**
```
weekStart = baselineDate + (weekIndex × 7 days)

IF includeWeekend:
    weekEnd = weekStart + 6 days (Sunday)
ELSE:
    weekEnd = weekStart + 4 days (Friday)

RETURN { weekStart, weekEnd }
```

**JavaScript Reference:** `calculateWeekDateRange(baselineDate, weekIndex, includeWeekend)`
- Location: `html_console_v10.html` line ~6574
- Parameters:
  - `baselineDate`: Date object (usually a Monday)
  - `weekIndex`: Integer (0 = Week 1, 1 = Week 2, etc.)
  - `includeWeekend`: Boolean (true = Sun, false = Fri)
- Returns: Object with `weekStart` and `weekEnd` Date objects

**PowerShell Implementation:**
```powershell
function Get-WeekDateRange {
    param(
        [DateTime]$BaselineDate,
        [int]$WeekIndex,
        [bool]$IncludeWeekend = $true
    )
    
    $weekStart = $BaselineDate.AddDays($WeekIndex * 7)
    $daysToAdd = if ($IncludeWeekend) { 6 } else { 4 }
    $weekEnd = $weekStart.AddDays($daysToAdd)
    
    return @{
        WeekStart = $weekStart
        WeekEnd = $weekEnd
    }
}
```

---

### 7. Calculate Task End Date (CORE FORMULA)

**Purpose:** Calculate when a task will complete based on its type and assignees

**Formula:**
```
// Step 1: Adjust start date to business day
taskStartDate = getNextBusinessDay(startDate)

// Step 2: Calculate business days needed
IF isFixedLength:
    // Fixed-Length: Duration stays constant
    businessDaysNeeded = CEILING(taskDurationDays)
ELSE:
    // Flexible: Duration splits among assignees
    daysPerPerson = taskDurationDays / MAX(assigneeCount, 1)
    businessDaysNeeded = CEILING(daysPerPerson)

// Step 3: Calculate end date
// Subtract 1 because start date counts as day 1
endDate = addBusinessDays(taskStartDate, businessDaysNeeded - 1)

RETURN endDate
```

**JavaScript Reference:** `calculateTaskEndDate(startDate, taskDurationDays, isFixedLength, assigneeCount)`
- Location: `html_console_v10.html` line ~6596
- Parameters:
  - `startDate`: Date object or string
  - `taskDurationDays`: Number (e.g., 5 for Medium task)
  - `isFixedLength`: Boolean (true = Fixed-Length, false = Flexible)
  - `assigneeCount`: Integer (number of people assigned)
- Returns: Date object

**PowerShell Implementation:**
```powershell
function Get-TaskEndDate {
    param(
        [DateTime]$StartDate,
        [double]$TaskDurationDays,
        [bool]$IsFixedLength = $true,
        [int]$AssigneeCount = 1
    )
    
    # Step 1: Adjust start to business day
    $taskStartDate = Get-NextBusinessDay $StartDate
    
    # Step 2: Calculate business days needed
    if ($IsFixedLength) {
        # Fixed-Length: Duration constant
        $businessDaysNeeded = [Math]::Ceiling($TaskDurationDays)
    }
    else {
        # Flexible: Duration splits
        $daysPerPerson = $TaskDurationDays / [Math]::Max($AssigneeCount, 1)
        $businessDaysNeeded = [Math]::Ceiling($daysPerPerson)
    }
    
    # Step 3: Calculate end date (start counts as day 1)
    $endDate = Add-BusinessDays -StartDate $taskStartDate -BusinessDaysToAdd ($businessDaysNeeded - 1)
    
    return $endDate
}
```

---

## 📐 Task Effort Calculation

**Purpose:** Calculate total effort hours for a task size

**Formula:**
```
effortHours = taskSizeDefinitions[size].days × estimationBaseHours
```

**Example:**
- Medium task = 5 days
- Estimation base = 5 hours/day
- Effort = 5 days × 5 hours = 25 hours

**JavaScript Reference:** `calculateEffortMap()`
- Location: `html_console_v10.html` line ~2039
- Global variable: `effortMap` (object mapping size to hours)

**PowerShell Implementation:**
```powershell
$taskSizeDefinitions = @{
    'S'  = @{ Days = 3 }
    'M'  = @{ Days = 5 }
    'L'  = @{ Days = 10 }
    'XL' = @{ Days = 20 }
}

$estimationBaseHours = 5

function Get-TaskEffortHours {
    param([string]$Size)
    
    $days = $taskSizeDefinitions[$Size].Days
    return $days * $estimationBaseHours
}
```

---

## 🔄 Fixed-Length vs Flexible Tasks

### Fixed-Length Tasks (Default)

**Characteristics:**
- Duration = Task Size (constant)
- Multiple people work in parallel
- Each person gets effort ÷ assignee count

**Example:**
- Medium task (5 days, 25 hours)
- 5 people assigned
- Duration: **5 days** (unchanged)
- Per person: 25h ÷ 5 = 5h total (1h/day)

**End Date Formula:**
```
endDate = addBusinessDays(startDate, taskDays - 1)
```

### Flexible Tasks (Opt-in)

**Characteristics:**
- Duration = Task Size ÷ Assignee Count
- More people = shorter duration
- Each person gets full effort

**Example:**
- Medium task (5 days, 25 hours)
- 5 people assigned
- Duration: 5 ÷ 5 = **1 day**
- Per person: 25h total (25h in 1 day = overloaded!)

**End Date Formula:**
```
daysPerPerson = taskDays / assigneeCount
endDate = addBusinessDays(startDate, CEILING(daysPerPerson) - 1)
```

---

## 🎯 Critical Implementation Notes

### 1. Day of Week Values

**JavaScript:**
```javascript
0 = Sunday
1 = Monday
2 = Tuesday
3 = Wednesday
4 = Thursday
5 = Friday
6 = Saturday
```

**PowerShell:**
```powershell
# Use .value__ to get numeric value
0 = Sunday
1 = Monday
2 = Tuesday
3 = Wednesday
4 = Thursday
5 = Friday
6 = Saturday
```

### 2. Date Math

**JavaScript:**
```javascript
date.setDate(date.getDate() + 1)  // Add 1 day
```

**PowerShell:**
```powershell
$date = $date.AddDays(1)  # Add 1 day
```

### 3. Ceiling Function

**JavaScript:**
```javascript
Math.ceil(5.2)  // Returns 6
```

**PowerShell:**
```powershell
[Math]::Ceiling(5.2)  # Returns 6
```

### 4. Max Function

**JavaScript:**
```javascript
Math.max(assigneeCount, 1)  // Ensures at least 1
```

**PowerShell:**
```powershell
[Math]::Max($assigneeCount, 1)  # Ensures at least 1
```

---

## ✅ Validation Test Cases

Use these test cases to verify PowerShell implementation matches JavaScript:

### Test 1: Add Business Days
```
Input: Start = Monday Oct 20, 2025, Add = 5 business days
Expected: Monday Oct 27, 2025 (skips weekend)
```

### Test 2: Weekend Adjustment
```
Input: Saturday Oct 18, 2025
Expected: Monday Oct 20, 2025
```

### Test 3: Fixed-Length Task
```
Input: Medium (5 days), 3 assignees, Start = Mon Oct 20
Expected: End = Fri Oct 24 (5 business days)
```

### Test 4: Flexible Task
```
Input: Medium (5 days), 5 assignees, Start = Mon Oct 20
Expected: End = Mon Oct 20 (ceiling(5/5) = 1 day)
```

### Test 5: Heat Map Baseline
```
Input: Tasks starting Oct 18 (Sat), Oct 20 (Mon), Oct 22 (Wed)
Expected: Baseline = Monday Oct 13 (previous Monday from Oct 18→Oct 20)
```

---

## 🚨 Common Mistakes to Avoid

1. **Off-by-One Errors**: Start date counts as day 1, so use `businessDays - 1` in `addBusinessDays()`
2. **Weekend Logic**: Remember Saturday (6) needs +2 days, Sunday (0) needs +1 day
3. **Null Checks**: Always check if date is valid before operations
4. **Assignee Count**: Use `MAX(count, 1)` to avoid division by zero
5. **Date Mutation**: JavaScript mutates dates in place; PowerShell returns new dates
6. **Day of Week**: PowerShell needs `.value__` to get numeric value from `DayOfWeek` enum

---

## 📚 Reference Locations in JavaScript

All centralized logic is in `html_console_v10.html`:

| Function | Line | Purpose |
|----------|------|---------|
| `calculateBusinessDays()` | ~6495 | Count business days between dates |
| `addBusinessDays()` | ~6508 | Add N business days |
| `getNextBusinessDay()` | ~6523 | Weekend → Monday |
| `getPreviousMonday()` | ~6535 | Find Monday of week |
| `getHeatMapBaselineDate()` | ~6547 | Find Week 1 start |
| `calculateWeekDateRange()` | ~6574 | Get week start/end |
| `calculateTaskEndDate()` | ~6596 | **CORE: Task end date** |
| `calculateEffortMap()` | ~2039 | Task effort hours |

**Header Comment Block**: Lines 6480-6520 (comprehensive documentation)

---

## 🔗 Cross-Reference Guide

When implementing in PowerShell:

1. ✅ Copy formulas EXACTLY from this document
2. ✅ Use the test cases to validate your implementation
3. ✅ Reference JavaScript code ONLY from "Reference Locations" above
4. ❌ Do NOT copy logic from other parts of the HTML file
5. ❌ Do NOT duplicate calculations - call these functions

---

**End of Reference Document**  
*If you find any discrepancies between this document and the JavaScript implementation, the JavaScript code in the listed line numbers is the authoritative source.*
