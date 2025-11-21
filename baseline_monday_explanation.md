# How heatMapBaselineDate Works in html_console_v10.html

## Overview
The `heatMapBaselineDate` (also referred to as the baseline Monday) is a critical reference point used throughout the task scheduling and capacity allocation system. It establishes a consistent "Week 1" starting point that all week calculations reference.

## How the Baseline is Set

The baseline is calculated by the `getHeatMapBaselineDate(tickets)` function:

```javascript
function getHeatMapBaselineDate(tickets) {
    if (!tickets || tickets.length === 0) {
        // No tickets, use current date and find its Monday
        return getPreviousMonday(new Date());
    }

    // Find earliest task start date with weekend adjustment
    let earliestTaskDate = null;

    tickets.forEach(task => {
        // Adjust weekend starts to next Monday
        const adjustedStart = getNextBusinessDay(new Date(task.startDate));
        
        // Track the earliest adjusted date
        if (!earliestTaskDate || adjustedStart < earliestTaskDate) {
            earliestTaskDate = new Date(adjustedStart);
        }
    });

    // Find the Monday of the week containing the earliest task
    return getPreviousMonday(earliestTaskDate || new Date());
}
```

### Algorithm Steps:
1. **No Tasks**: If there are no tickets, it uses the current date and finds the previous Monday
2. **With Tasks**: 
   - Loops through all tasks to find the earliest start date
   - Adjusts weekend starts to the next business day (Monday)
   - Finds the **Monday of the week** containing the earliest task start date
   - This Monday becomes the "Week 1" baseline

## Significance of the Baseline

### 1. Week Index Calculation

The baseline is used to calculate which week a task belongs to:

```javascript
// Calculate days from baseline
const daysDiff = Math.round((currentDate.getTime() - heatMapBaselineDate.getTime()) / (1000 * 60 * 60 * 24));

// Convert to week index
const weekIndex = Math.floor(daysDiff / 7);
```

**Example:**
- Baseline: Monday, September 29, 2025 (Week 1 starts)
- Task starts: Monday, October 6, 2025
- Days difference: 7 days
- Week index: Math.floor(7 / 7) = 1 (which represents Week 2)

### 2. Consistent Reference Point

The baseline ensures **all calculations use the same reference point**:

- **Capacity allocation**: Determines which week's capacity to deduct from
- **Heatmap rendering**: Shows "Week 1", "Week 2", etc. consistently across the UI
- **Date ranges**: Week headers display correct date ranges
- **Task scheduling**: All tasks calculate their week position relative to the same baseline

### 3. Weekend Handling

The baseline is **always a Monday** because:
- Work weeks start on Monday (business day alignment)
- Prevents confusion with weekend dates
- Makes 7-day week calculations clean and accurate
- Ensures consistent business day counting

### 4. Prevents Date Calculation Drift

Without a centralized baseline, different parts of the application might use different reference points, causing:
- Task A calculating it's in Week 2
- Task B calculating it's in Week 3  
- Heatmap displaying Week 1
- **With baseline: All components agree on week numbers**

## Usage Throughout the Code

The baseline is used in three main areas:

### A. Fixed-Length Task Processing (Line 2212)
```javascript
const heatMapBaselineDate = getHeatMapBaselineDate(tickets);
// Used to determine which week's capacity to consume during task allocation
```

### B. Flexible Task Processing (Line 2337)
```javascript
const heatMapBaselineDate = getHeatMapBaselineDate(tickets);
// Used to determine task start week for capacity allocation
// UTC normalization applied to prevent timezone issues
```

### C. Heatmap Data Calculation (Line 6465)
```javascript
const startDate = getHeatMapBaselineDate(activeTickets);
heatMapStartDate = new Date(startDate); // Stored globally for reuse
```

## Visual Example

```
Baseline Monday: September 29, 2025
├── Week 1: Sept 29 - Oct 5    (weekIndex = 0)
├── Week 2: Oct 6 - Oct 12     (weekIndex = 1)
├── Week 3: Oct 13 - Oct 19    (weekIndex = 2)
├── Week 4: Oct 20 - Oct 26    (weekIndex = 3)
├── Week 5: Oct 27 - Nov 2     (weekIndex = 4)
├── Week 6: Nov 3 - Nov 9      (weekIndex = 5)
├── Week 7: Nov 10 - Nov 16    (weekIndex = 6)
└── Week 8: Nov 17 - Nov 23    (weekIndex = 7)

Example Task Calculation:
Task starts October 8 (Tuesday):
- Days from baseline: (Oct 8 - Sept 29) = 9 days
- Week index: Math.floor(9 / 7) = 1 (Week 2) ✅
```

## Why This Matters

### 1. Accurate Capacity Tracking
Ensures tasks deduct hours from the correct week's capacity pool. Without this, a task might incorrectly consume capacity from Week 1 when it actually runs in Week 2.

### 2. Consistent Heatmap Display
Week headers in the heatmap UI match actual task scheduling. Users see accurate workload distribution across the 8-week planning horizon.

### 3. Timezone Safety
UTC normalization is applied to the baseline to prevent date calculation errors across different timezones:

```javascript
const normalizedBaseline = new Date(Date.UTC(
    heatMapBaselineDate.getFullYear(), 
    heatMapBaselineDate.getMonth(), 
    heatMapBaselineDate.getDate()
));
```

### 4. Chronological Processing
Tasks are processed in order from the baseline forward, ensuring capacity is allocated sequentially and realistically.

### 5. Multi-Module Consistency
The same baseline is used by:
- Fixed-length task allocation
- Flexible task allocation  
- Heatmap visualization
- Week detail modals
- Calendar rendering

## Critical Design Decisions

### Why Monday?
- Industry standard for work week start
- Simplifies business day calculations (Mon-Fri = days 1-5)
- Avoids edge cases with weekend dates

### Why Centralized Function?
- Single source of truth prevents calculation drift
- Easier to maintain and debug
- Ensures consistency across all features

### Why Earliest Task Date?
- Creates a sensible "start of project" reference
- No empty weeks at the beginning of the heatmap
- Week 1 always contains actual work

## Impact on Capacity Allocation

When a task is processed:

1. Task start date is converted to days from baseline
2. Days are divided by 7 to get week index
3. Task capacity is deducted from that week's pool
4. If multiple people are assigned, each person's capacity for that week is reduced
5. Heatmap cells update to reflect utilization percentage

Without the baseline, this entire chain breaks down, leading to:
- Incorrect capacity deductions
- Misaligned heatmap displays
- Overload warnings in wrong weeks
- Scheduling conflicts

## Conclusion

The `heatMapBaselineDate` is the foundational reference point for the entire task scheduling system. It ensures that week numbers, date ranges, and capacity allocations remain consistent across all features. By always being a Monday and based on the earliest task start date, it provides a logical, predictable, and maintainable approach to multi-week project planning.
