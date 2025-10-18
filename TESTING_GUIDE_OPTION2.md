# Testing Guide: No OT + Fixed-Length + P1 Priority Features

## Implementation Summary (Option 2)

**Fixed-Length tasks IGNORE No OT constraint** - they will show >100% utilization if needed, giving you visibility to make reallocation decisions.

## How the Algorithm Works

### Step 1: Separate Tasks
- **Fixed-Length tasks**: Duration-based allocation (e.g., 5 days × 4h/day = 20h regardless of capacity)
- **Flexible tasks**: Capacity-based allocation (respects remaining capacity)

### Step 2: Allocate Fixed Tasks FIRST
- Calculate daily hours needed: `totalEffort / (days × assignees)`
- Allocate up to `dailyHours × 5 working days` per week
- **Ignore No OT constraint** - allocate the full amount needed
- Track as P1 or Other priority hours

### Step 3: Calculate Remaining Capacity
- `remainingCapacity = weekCapacity - fixedTasksUsed`
- If remaining capacity is 0 or negative, no room for Flexible tasks

### Step 4: Allocate Flexible Tasks
- Use remaining capacity only
- Apply P1 priority weighting:
  - If P1 exists: 80% to P1, 20% to others
  - If no P1: 100% to others
- Split capacity proportionally among tasks

### Step 5: Apply No OT Constraint (Flexible Only)
- If total > 100% AND No OT enabled:
  - Scale down **only Flexible tasks**
  - Return unused effort to next week
  - **Keep Fixed tasks at their allocated hours**

## Test Scenarios

### Scenario 1: Person A - No OT ON with Fixed P1
**Setup:**
- Person A: 20h/week capacity, No OT = TRUE
- TASK-1: Fixed P1, size M (5 days, 20h total) → needs 4h/day
- TASK-7: Fixed P1, size S (3 days, 12h total) → needs 4h/day

**Expected Result (Week 1):**
- TASK-1 allocated: 20h (4h/day × 5 days)
- TASK-7 allocated: 12h (4h/day × 3 days)
- **Total: 32h / 20h = 160% ⚠️ OVER CAPACITY**
- Heatmap should show RED (>100%)
- Console should show: "⚠️ OVER CAPACITY: 32.0h / 20h (160%) - Fixed-Length tasks exceed capacity!"

**Action Required:** You should reassign TASK-7 to another person or adjust task durations.

---

### Scenario 2: Person B - No OT OFF with Fixed P1
**Setup:**
- Person B: 20h/week capacity, No OT = FALSE
- TASK-2: Fixed P1, size M (5 days, 20h total) → needs 4h/day

**Expected Result (Week 1):**
- TASK-2 allocated: 20h (4h/day × 5 days)
- **Total: 20h / 20h = 100%**
- Heatmap should show YELLOW/ORANGE (100%)
- No OT constraint doesn't apply (OFF)

---

### Scenario 3: Person C - Mixed Fixed P1 + Flexible P2
**Setup:**
- Person C: 20h/week capacity, No OT = TRUE
- TASK-3: Fixed P1, size M (5 days, 20h total) → needs 4h/day
- TASK-4: Flexible P2, size S (3 days, 12h total)

**Expected Result (Week 1):**
- TASK-3 (Fixed P1) allocated: 20h
- TASK-4 (Flexible P2) allocated: 0h (no capacity remaining)
- **Total: 20h / 20h = 100%**
- Heatmap shows 100% with P1 badge

**Expected Result (Week 2):**
- TASK-3 complete (0h remaining)
- TASK-4 (Flexible P2) allocated: 12h (gets full capacity now)
- **Total: 12h / 20h = 60%**
- Task ends in Week 2

---

### Scenario 4: Person D - Only Flexible Tasks with P1 Priority
**Setup:**
- Person D: 20h/week capacity, No OT = TRUE
- TASK-5: Flexible P1, size S (3 days, 12h total)
- TASK-6: Flexible P2, size S (3 days, 12h total)

**Expected Result (Week 1):**
- TASK-5 (Flex P1) allocated: 12h (would get 16h with 80% but only needs 12h)
- TASK-6 (Flex P2) allocated: 4h (gets 20% = 4h of 20h capacity)
- **Total: 16h / 20h = 80%**
- Heatmap shows 80% with P1 badge

**Expected Result (Week 2):**
- TASK-5 complete (0h remaining)
- TASK-6 (Flex P2) allocated: 8h (remaining effort, gets 100% now)
- **Total: 8h / 20h = 40%**
- Both tasks complete

---

## How to Test

### 1. Load Test Data
1. Open `html_console_v10.html` in your browser
2. Click **"Import CSV"**
3. Select `test_no_ot_scenarios.csv`
4. Verify 4 people, 7 tasks loaded

### 2. Check Workload Heatmap
Look at the heatmap table and verify:

**Person A (No OT ON):**
- Week 1: **RED cell (>100%)** showing ~160%
- Should see P1 badge
- Tooltip should show both TASK-1 and TASK-7

**Person B (No OT OFF):**
- Week 1: **YELLOW/ORANGE cell (100%)**
- Should see P1 badge
- Single task TASK-2

**Person C (Mixed):**
- Week 1: **YELLOW/ORANGE cell (100%)** - only TASK-3 (Fixed P1)
- Week 2: **GREEN cell (~60%)** - only TASK-4 (Flexible P2)
- P1 badge in Week 1 only

**Person D (Flex Only):**
- Week 1: **YELLOW cell (80%)** - TASK-5 + TASK-6
- Week 2: **GREEN cell (40%)** - remaining TASK-6
- P1 badge in Week 1 only

### 3. Check Browser Console Logs
Open Developer Tools (F12) → Console tab

Look for allocation logs showing:
```
Week 0: Person A - No OT ON
  📌 Fixed-Length Tasks: 2, Flexible Tasks: 0
    📌 FIXED P1 Task TASK-1: Allocated 20.0h (4.0h/day required)
    📌 FIXED P1 Task TASK-7: Allocated 12.0h (4.0h/day required)
  ⚠️ OVER CAPACITY: 32.0h / 20h (160%) - Fixed-Length tasks exceed capacity!
```

### 4. Validate Task End Dates
Check that tasks extend properly:
- Person C's TASK-4 should end 1 week later than TASK-3
- Person D's TASK-6 should end 1 week later than TASK-5

### 5. Test Interactive Changes
1. Toggle Person A's "No Overtime Allowed" checkbox to OFF
   - Heatmap should still show >100% (Fixed tasks don't care about OT setting)
2. Toggle Person C's "No Overtime Allowed" checkbox to OFF
   - Week 1 should now show ~160% (TASK-3 + TASK-4 both allocated)
   - Week 2 should be empty (both complete in Week 1)

## What You Should See

### ✅ Success Indicators
1. **Person A**: Clearly shows RED (>100%) - alerts you to overallocation
2. **Fixed-Length tasks**: Always allocated their required daily hours
3. **Flexible tasks**: Scale down gracefully when capacity limited
4. **P1 badges**: Show on cells with P1 priority tasks
5. **Console logs**: Clear breakdown of Fixed vs Flexible allocations
6. **Tooltips**: Show which tasks contribute to each week's workload

### ⚠️ Warning Signs (Expected)
- Person A showing >100% is INTENTIONAL - this is the flag for you to reallocate
- Console warning: "⚠️ OVER CAPACITY" - this is your alert system

### ❌ Problems (Should NOT See)
- Fixed-Length tasks being scaled down
- No OT constraint affecting Fixed-Length allocations
- Flexible P1 tasks getting less than 80% when capacity available
- Missing P1 badges on weeks with P1 tasks
- Tasks disappearing or not being allocated

## Real-World Usage Pattern

When you see >100% in the heatmap:

1. **Identify the cause**: Check tooltip or console - usually Fixed-Length tasks
2. **Decide action**:
   - Reassign Fixed task to another person with capacity
   - Convert Fixed → Flexible (uncheck Fixed column)
   - Increase person's capacity temporarily
   - Delay task start date to spread load
3. **Adjust and recalculate**: Heatmap updates in real-time
4. **Verify**: Heatmap should return to ≤100% after changes

## Option 2 Benefits

✅ **Visibility**: You SEE the problem immediately (red cells)
✅ **Realistic**: Matches workplace behavior (Fixed deadlines can't be stretched)
✅ **Actionable**: Clear indication when reallocation needed
✅ **Flexible**: You control how to resolve conflicts
✅ **Accurate**: Shows true capacity demands

---

**Ready to test?** Load the CSV and check each scenario! 🚀
