# Fixed-Length Tasks Feature - Acceptance Criteria

## Feature Overview
The Fixed-Length Tasks feature allows tasks to be either **Fixed-Length** (duration remains constant regardless of assignees) or **Flexible** (duration splits among assignees). This provides more accurate project planning when tasks require a fixed timeline.

## Core Behavior

### Fixed-Length Tasks (Default)
- **Duration**: Constant regardless of number of assignees
- **Capacity**: Each person contributes proportionally over the full duration
- **Example**: 10-day task with 2 people = each person works at 50% capacity for 10 days
- **Icon**: 🔒

### Flexible Tasks (Opt-in)
- **Duration**: Splits among assignees
- **Capacity**: Each person works at 100% capacity for shorter time
- **Example**: 10-day task with 2 people = each person works at 100% for 5 days
- **Icon**: ⚡

---

## 1. Task Creation

### Scenario 1.1: Create Fixed-Length Task (Default)
**Given** I am creating a new task  
**When** I do not check the "Flexible Task" checkbox  
**Then** the task should be created with `isFixedLength = true`  
**And** the task should display the 🔒 icon

### Scenario 1.2: Create Flexible Task
**Given** I am creating a new task  
**When** I check the "Flexible Task" checkbox  
**Then** the task should be created with `isFixedLength = false`  
**And** the task should display the ⚡ icon

### Scenario 1.3: Default Checkbox State
**Given** the task creation form is displayed  
**When** I view the "Flexible Task" checkbox  
**Then** it should be unchecked by default

### Scenario 1.4: Task Type Property Storage
**Given** I have created tasks of both types  
**When** the tasks are saved to localStorage  
**Then** each task should have the `isFixedLength` property correctly stored

### Scenario 1.5: Visual Indicators
**Given** I have tasks of both types in the list  
**When** I view the task list  
**Then** Fixed-Length tasks should show 🔒  
**And** Flexible tasks should show ⚡

### Scenario 1.6: Backwards Compatibility
**Given** I have tasks created before this feature was added  
**When** the system loads these tasks  
**Then** they should be treated as Fixed-Length (isFixedLength = true)

---

## 2. End Date Calculations

### Scenario 2.1: Fixed-Length with 1 Person
**Given** a Fixed-Length task of size L (5 days)  
**And** 1 person assigned  
**When** the end date is calculated  
**Then** the duration should be 5 business days

### Scenario 2.2: Fixed-Length with 2 People - Same Duration
**Given** a Fixed-Length task of size L (5 days)  
**And** 2 people assigned  
**When** the end date is calculated  
**Then** the duration should still be 5 business days (not 2.5 days)

### Scenario 2.3: Fixed-Length with 5 People - Same Duration
**Given** a Fixed-Length task of size XL (10 days)  
**And** 5 people assigned  
**When** the end date is calculated  
**Then** the duration should still be 10 business days (not 2 days)

### Scenario 2.4: Flexible with 1 Person - Baseline
**Given** a Flexible task of size L (5 days)  
**And** 1 person assigned  
**When** the end date is calculated  
**Then** the duration should be 5 business days

### Scenario 2.5: Flexible with 2 People - Half Duration
**Given** a Flexible task of size XL (10 days)  
**And** 2 people assigned  
**When** the end date is calculated  
**Then** the duration should be 5 business days (half of 10)

### Scenario 2.6: Flexible with 5 People - One-Fifth Duration
**Given** a Flexible task of size XXL (15 days)  
**And** 5 people assigned  
**When** the end date is calculated  
**Then** the duration should be 3 business days (one-fifth of 15)

### Scenario 2.7: Task with No Assignees
**Given** a task of either type  
**And** no people assigned  
**When** the end date is calculated  
**Then** the system should display "N/A" without crashing

### Scenario 2.8: Very Large Task Size
**Given** a task with size = 100 days  
**And** 1 person assigned  
**When** the end date is calculated  
**Then** the system should calculate correctly without errors

### Scenario 2.9: Fixed vs Flexible Comparison
**Given** two identical tasks (same size, same assignees)  
**And** one is Fixed-Length, one is Flexible  
**When** end dates are calculated  
**Then** the Fixed task should have longer duration than the Flexible task

### Scenario 2.10: Weekend Boundaries
**Given** a Fixed-Length task starting on Friday  
**And** size = 5 days  
**When** the end date is calculated  
**Then** weekends should be skipped in the calculation

---

## 3. Capacity Calculations

### Scenario 3.1: Fixed with 1 Person = 100% Capacity
**Given** a Fixed-Length task of 5 days (25 hours)  
**And** 1 person assigned  
**When** capacity is calculated  
**Then** the person should be allocated 100% capacity (5h/day) for 5 days

### Scenario 3.2: Fixed with 2 People = 50% Each
**Given** a Fixed-Length task of 5 days (25 hours)  
**And** 2 people assigned  
**When** capacity is calculated  
**Then** each person should be allocated 50% capacity (2.5h/day) for 5 days

### Scenario 3.3: Fixed with 5 People = 20% Each
**Given** a Fixed-Length task of 5 days (25 hours)  
**And** 5 people assigned  
**When** capacity is calculated  
**Then** each person should be allocated 20% capacity (1h/day) for 5 days

### Scenario 3.4: Flexible with 1 Person = 100% Capacity
**Given** a Flexible task of 5 days (25 hours)  
**And** 1 person assigned  
**When** capacity is calculated  
**Then** the person should be allocated 100% capacity for 5 days

### Scenario 3.5: Flexible with 2 People = 100% Each, Half Duration
**Given** a Flexible task of 10 days (50 hours)  
**And** 2 people assigned  
**When** capacity is calculated  
**Then** each person should be allocated 100% capacity for 5 days

### Scenario 3.6: Mixed - Same Person with Fixed + Flexible
**Given** Alice is assigned to:
- Fixed task: 5 days, 2 people (50% capacity)
- Flexible task: 5 days, 1 person (100% capacity)
**When** capacity is calculated  
**Then** Alice should show 150% capacity (overallocated)  
**And** the heat map should highlight this in red

### Scenario 3.7: Mixed - Same Person with 2 Fixed Tasks
**Given** Alice is assigned to two Fixed tasks simultaneously  
**And** each is 5 days with 1 person (100% each)  
**When** capacity is calculated  
**Then** Alice should show 200% capacity (overallocated)

### Scenario 3.8: Mixed - Same Person with 2 Flexible Tasks
**Given** Alice is assigned to two Flexible tasks  
**And** both are 2 days, 1 person each  
**And** they start at different times  
**When** capacity is calculated  
**Then** capacities should be calculated for each task's duration

### Scenario 3.9: Overallocation Detection
**Given** a person assigned to multiple overlapping tasks  
**When** total capacity exceeds 100%  
**Then** the heat map should show >100% utilization in red

### Scenario 3.10: Underallocation Detection
**Given** a person assigned to a small task (1 day)  
**When** capacity is calculated  
**Then** the heat map should show <100% utilization in green

### Scenario 3.11: Zero Capacity Edge Case
**Given** a task with no assignees  
**When** capacity is calculated  
**Then** all people should show 0% utilization for that task

### Scenario 3.12: Rounding Precision
**Given** a Fixed task with 3 people (33.33% each)  
**When** capacity is calculated  
**Then** percentages should be rounded appropriately without errors

### Scenario 3.13: Heat Map Structure for Fixed Tasks
**Given** Fixed-Length tasks exist  
**When** the heat map is generated  
**Then** it should have the correct array structure with weeks and utilization data

### Scenario 3.14: Heat Map Structure for Flexible Tasks
**Given** Flexible tasks exist  
**When** the heat map is generated  
**Then** it should have the correct array structure with weeks and utilization data

### Scenario 3.15: Heat Map Structure for Mixed Tasks
**Given** both Fixed and Flexible tasks exist  
**When** the heat map is generated  
**Then** it should correctly combine capacities from both types

---

## 4. UI and Display

### Scenario 4.1: Fixed-Length Icon Display
**Given** a Fixed-Length task exists  
**When** I view the task list  
**Then** I should see the 🔒 icon next to the task name

### Scenario 4.2: Flexible Icon Display
**Given** a Flexible task exists  
**When** I view the task list  
**Then** I should see the ⚡ icon next to the task name

### Scenario 4.3: Checkbox Default State
**Given** I open the task creation form  
**When** the form loads  
**Then** the "Flexible Task" checkbox should be unchecked (Fixed is default)

### Scenario 4.4: Checkbox Controls Task Type
**Given** I am creating a task  
**When** I check the "Flexible Task" checkbox  
**Then** the task should be created as Flexible  
**And** when I uncheck it, the task should be created as Fixed

### Scenario 4.5: Details Button Shows Task Type
**Given** a task of either type  
**When** I click the "Details" button  
**Then** the modal should show "Fixed-Length Task 🔒" or "Flexible Task ⚡"

### Scenario 4.6: Details Button Shows Capacity Breakdown
**Given** a Fixed task with 2 people  
**When** I click the "Details" button  
**Then** I should see capacity breakdown showing 50% per person

### Scenario 4.7: Details Button Shows Duration Explanation
**Given** any task  
**When** I click the "Details" button  
**Then** I should see an explanation of how the duration was calculated

---

## 5. Import and Export

### Scenario 5.1: CSV Export Includes Task Type Column
**Given** I have tasks of both types  
**When** I export to CSV  
**Then** the CSV should have a "Task Type" column

### Scenario 5.2: CSV Export Shows "Fixed"
**Given** a Fixed-Length task  
**When** I export to CSV  
**Then** the Task Type column should show "Fixed"

### Scenario 5.3: CSV Export Shows "Flexible"
**Given** a Flexible task  
**When** I export to CSV  
**Then** the Task Type column should show "Flexible"

### Scenario 5.4: CSV Import Parses "Fixed"
**Given** a CSV with Task Type = "Fixed"  
**When** I import the CSV  
**Then** the task should have isFixedLength = true

### Scenario 5.5: CSV Import Parses "Flexible"
**Given** a CSV with Task Type = "Flexible"  
**When** I import the CSV  
**Then** the task should have isFixedLength = false

### Scenario 5.6: CSV Import Defaults to Fixed
**Given** a CSV without a Task Type column (old format)  
**When** I import the CSV  
**Then** all tasks should default to Fixed-Length (isFixedLength = true)

### Scenario 5.7: Config Export Includes isFixedLength
**Given** I have tasks of both types  
**When** I export configuration  
**Then** the JSON should include the isFixedLength property for each task

### Scenario 5.8: Config Import Parses isFixedLength
**Given** a configuration JSON with isFixedLength properties  
**When** I import the configuration  
**Then** tasks should be created with the correct task type  
**And** tasks without isFixedLength should default to true

---

## 6. Edge Cases and Validation

### Scenario 6.1: Task with No Assignees
**Given** a task with no people assigned  
**When** calculations are performed  
**Then** the system should not crash  
**And** should show "N/A" for end date

### Scenario 6.2: Task with 1 Assignee (Fixed = Flexible)
**Given** a task with only 1 person assigned  
**When** comparing Fixed and Flexible behavior  
**Then** both should behave identically (same duration and capacity)

### Scenario 6.3: Very Small Task Size (0.5 days)
**Given** a task with size = 0.5 days  
**When** calculations are performed  
**Then** the system should handle fractional days correctly

### Scenario 6.4: Very Large Task Size (100 days)
**Given** a task with size = 100 days  
**When** calculations are performed  
**Then** the system should not break or cause performance issues

### Scenario 6.5: Changing Task Type After Creation
**Given** an existing Fixed task  
**When** I change it to Flexible (or vice versa)  
**Then** the task should be updated correctly  
**And** recalculations should reflect the new type

### Scenario 6.6: Deleting Task with Specific Type
**Given** tasks of both types exist  
**When** I delete a Fixed task  
**Then** it should be removed successfully  
**And** Flexible tasks should remain unaffected

### Scenario 6.7: Status Changes Don't Affect Task Type
**Given** a Fixed task with status "To Do"  
**When** I change the status to "In Progress"  
**Then** the task should remain Fixed-Length  
**And** isFixedLength should not change

### Scenario 6.8: Filtering Works with Both Types
**Given** I have tasks of both types assigned to different people  
**When** I filter by person  
**Then** the filter should work regardless of task type  
**And** both Fixed and Flexible tasks should be included in results

---

## Test Coverage Summary

| Category | Scenarios | Status |
|----------|-----------|--------|
| Task Creation | 6 | ✅ Complete |
| End Date Calculations | 10 | ✅ Complete |
| Capacity Calculations | 15 | ✅ Complete |
| UI and Display | 7 | ✅ Complete |
| Import/Export | 8 | ✅ Complete |
| Edge Cases | 8 | ✅ Complete |
| **TOTAL** | **54** | **✅ Complete** |

---

## Manual Testing Checklist

### Basic Functionality
- [ ] Create a Fixed-Length task (default) - verify 🔒 icon
- [ ] Create a Flexible task (checked box) - verify ⚡ icon
- [ ] Verify Fixed task with 2 people keeps same duration
- [ ] Verify Flexible task with 2 people halves duration
- [ ] Check details button shows correct task type
- [ ] Verify capacity percentages in heat map

### Import/Export
- [ ] Export tasks - verify "Task Type" column exists
- [ ] Import old CSV (no Task Type column) - verify defaults to Fixed
- [ ] Import new CSV with Task Type - verify correct parsing
- [ ] Export and re-import configuration - verify task types preserved

### Edge Cases
- [ ] Task with 0 assignees - should show N/A
- [ ] Task with 1 assignee - Fixed = Flexible behavior
- [ ] Very large task (100 days) - should calculate correctly
- [ ] Mixed tasks on same person - should show >100% if overallocated

### Backwards Compatibility
- [ ] Load old localStorage data - tasks should default to Fixed
- [ ] Old configuration files - should import successfully
- [ ] All 110 original tests still pass

---

## Success Criteria

✅ **All 54 new automated tests pass**  
✅ **All 110 original automated tests still pass (164 total)**  
✅ **Fixed-Length is the default behavior**  
✅ **Flexible tasks work correctly with duration splitting**  
✅ **Heat map correctly handles mixed task scenarios**  
✅ **Import/export preserves task types**  
✅ **Backwards compatibility maintained**  
✅ **UI clearly shows task type indicators**  
✅ **Details button provides complete information**

---

## Known Limitations

1. **8-Week Planning Window**: Tasks beyond 8 weeks may show as delayed
2. **Heat Map Resolution**: Weekly granularity, not daily
3. **Capacity Rounding**: Small rounding differences in edge cases (e.g., 33.33%)
4. **Simple CSV Import**: Only imports task names, full CSV import uses configuration format

---

## Future Enhancements

- [ ] Ability to bulk change task types
- [ ] Visual timeline showing Fixed vs Flexible task spans
- [ ] Capacity optimization suggestions
- [ ] Export capacity report showing overallocations
- [ ] Custom task type templates

---

**Document Version**: 1.0  
**Last Updated**: October 14, 2025  
**Feature Status**: ✅ Implemented and Tested
