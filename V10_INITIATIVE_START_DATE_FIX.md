# V10 Bug Fix: Initiative Start Date Not Updating

## Problem
When editing a task's start date in the task table, the initiative's start date was not being recalculated. This caused the exported configuration to show outdated initiative start dates.

## Root Cause
The `handleStartDateChange()` function (line 5526) was missing the call to `recalculateAllInitiativeStartDates()`.

### Why This Happened
There are two places where task start dates can be edited:

1. **Heat Map Popup** → Uses `updateTaskStartDate()` function
   - ✅ Already had `recalculateAllInitiativeStartDates()` call (line 3670)
   
2. **Task Table** → Uses `handleStartDateChange()` function  
   - ❌ Was missing `recalculateAllInitiativeStartDates()` call

## Solution
Added `recalculateAllInitiativeStartDates()` call to `handleStartDateChange()` function.

### Code Change (Line ~5536)
```javascript
window.handleStartDateChange = (inputElement, ticketId) => {
    const newStartDate = inputElement.value;
    const ticket = tickets.find(t => t.id === ticketId);
    
    if (ticket) {
        const oldStartDate = ticket.startDate;
        ticket.startDate = newStartDate;
        
        trackStartDateChange(ticket, oldStartDate, newStartDate, 'Manual update via UI');
        
        // V10: Recalculate initiative start dates when task start date changes
        recalculateAllInitiativeStartDates(); // ← ADDED THIS LINE
        
        // ... rest of the function
    }
}
```

## How Initiative Start Dates Work

### Calculation Logic
The `recalculateAllInitiativeStartDates()` function:
1. Finds all tasks associated with each initiative
2. Determines the earliest start date among those tasks
3. Sets that as the initiative's start date
4. If no tasks exist, sets start date to `null`

```javascript
function recalculateAllInitiativeStartDates() {
    for (const initiative of initiatives) {
        const associatedTasks = tickets.filter(t => 
            t.initiative === initiative.name && t.startDate
        );
        
        if (associatedTasks.length > 0) {
            const earliestDate = associatedTasks.reduce((earliest, task) => {
                return !earliest || task.startDate < earliest ? task.startDate : earliest;
            }, null);
            initiative.startDate = earliestDate;
        } else {
            initiative.startDate = null; // No tasks yet
        }
    }
}
```

## Testing Checklist

✅ Edit task start date in task table → Initiative start date updates
✅ Edit task start date in heat map popup → Initiative start date updates
✅ Pre-date a task (make it earliest) → Initiative start date updates to that earlier date
✅ Post-date the earliest task → Initiative start date updates to next earliest task
✅ Export configuration → Initiative start dates are correct
✅ Multiple tasks in same initiative → Initiative shows earliest start date
✅ Remove all tasks from initiative → Initiative start date becomes null
✅ Change task to different initiative → Both initiatives' start dates recalculate

## Impact
- **Before**: Editing task start dates in the table didn't update initiative start dates → Incorrect data in exports
- **After**: All task start date changes (table or popup) now correctly update initiative start dates → Accurate exports

## Related Functions
- `handleStartDateChange()` - Task table date editor (NOW FIXED)
- `updateTaskStartDate()` - Heat map popup date editor (Already working)
- `recalculateAllInitiativeStartDates()` - Core calculation logic
- `addTicket()` - Also calls recalculation when new tasks are added
- `removeTicket()` - Also calls recalculation when tasks are deleted

---

**Status**: ✅ Fixed
**Version**: V10
**Date**: October 16, 2025
**Bug Severity**: Medium (Affected data accuracy in exports)
