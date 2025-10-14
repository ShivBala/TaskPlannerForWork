# Acceptance Criteria: Task Management

## Feature: Add New Task

### Scenario 1: Add task with all required fields
**Given** the user is on the task tracker page  
**When** the user fills in all required fields:
- Description: "Implement user authentication"
- Start Date: "2025-10-21"
- Size: "L"
- Priority: "P1"
- Assigned to: ["Alice", "Bob"]

**And** clicks "Add Task" button  
**Then** a new task should be created with:
- Unique ID generated
- All provided field values
- Status defaulted to "To Do"
- originalEstimate calculated from size
- endDate calculated from startDate + size
- customEndDate set to null
- completedDate set to null
- assigned array containing ["Alice", "Bob"]

**And** the task should appear in the task table  
**And** the task should be saved to localStorage  
**And** the dirty state indicator should be shown  
**And** capacity calculations should be updated  
**And** the form should be cleared

---

### Scenario 2: Add task with minimal fields (defaults applied)
**Given** the user is on the task tracker page  
**When** the user fills in only the description: "Quick bug fix"  
**And** leaves all other fields at defaults  
**And** clicks "Add Task" button  
**Then** a new task should be created with:
- Description: "Quick bug fix"
- Size: "L" (default)
- Priority: "P3" (default)
- Status: "To Do" (default)
- Start Date: next Monday from current date
- Assigned: [] (empty array - unassigned)

**And** the task should appear in the task table

---

### Scenario 3: Add task with no description (validation)
**Given** the user is on the task tracker page  
**When** the user leaves description field empty  
**And** clicks "Add Task" button  
**Then** no task should be created  
**And** the task list should remain unchanged  
**And** no dirty state should be set

---

### Scenario 4: Add duplicate task (prevention)
**Given** a task exists with description "Fix login bug"  
**When** the user tries to add another task with description "Fix login bug"  
**And** clicks "Add Task" button  
**Then** the system should detect the duplicate  
**And** skip adding the duplicate task  
**And** log a warning: "Skipping duplicate task: Fix login bug"  
**And** the task count should remain unchanged

---

### Scenario 5: Add task with Common Start Date enabled
**Given** Common Start Date mode is enabled  
**And** Common Start Date is set to "2025-10-28"  
**When** the user adds a new task  
**Then** the task's start date should be "2025-10-28"  
**And** the individual start date field should be ignored

---

### Scenario 6: Add task with multiple assignees
**Given** the user is on the task tracker page  
**When** the user checks multiple people in the "Assign to" section:
- ☑ Vipul
- ☑ Peter
- ☑ Sharanya

**And** fills in other fields  
**And** clicks "Add Task" button  
**Then** the task's assigned array should contain ["Vipul", "Peter", "Sharanya"]  
**And** the task should appear in all three people's workload  
**And** capacity should be distributed across all assignees

---

## Feature: Remove Task

### Scenario 7: Remove existing task
**Given** a task exists with ID 5 and description "Update documentation"  
**When** the user clicks the remove button for that task  
**Then** the task should be removed from the tickets array  
**And** the task should disappear from the task table  
**And** the change should be saved to localStorage  
**And** the dirty state indicator should be shown  
**And** capacity calculations should be updated  
**And** people display should be refreshed (if not using common start date)

---

### Scenario 8: Remove task assigned to person
**Given** a task is assigned to "Alice"  
**And** Alice has other tasks  
**When** the user removes the task  
**Then** the task should be removed  
**And** Alice's workload should be recalculated  
**And** Alice's other tasks should remain intact

---

### Scenario 9: Remove last task
**Given** only one task exists in the system  
**When** the user removes that task  
**Then** the tickets array should be empty  
**And** the "No tasks" message should be displayed  
**And** the task table should show no rows

---

## Feature: Update Task Assignment

### Scenario 10: Update task to assign single person
**Given** a task exists with no assignees (assigned: [])  
**When** the user checks "Alice" in the assignment checkboxes  
**Then** the task's assigned array should be updated to ["Alice"]  
**And** the change should be saved to localStorage  
**And** the dirty state should be set  
**And** capacity calculations should be updated  
**And** Alice should see the task in her workload

---

### Scenario 11: Update task to unassign person
**Given** a task is assigned to ["Alice", "Bob"]  
**When** the user unchecks "Alice" in the assignment checkboxes  
**Then** the task's assigned array should be updated to ["Bob"]  
**And** Alice's workload should no longer include this task  
**And** Bob should still have the task in his workload

---

### Scenario 12: Update task to multiple assignees
**Given** a task is assigned to ["Alice"]  
**When** the user checks "Bob" and "Charlie" in addition to Alice  
**Then** the task's assigned array should be updated to ["Alice", "Bob", "Charlie"]  
**And** all three people should see the task in their workload

---

### Scenario 13: Update task to unassign all people
**Given** a task is assigned to ["Alice", "Bob"]  
**When** the user unchecks both Alice and Bob  
**Then** the task's assigned array should be empty []  
**And** the task should remain in the system  
**And** the task should appear as "Unassigned"  
**And** no person's workload should include this task

---

## Feature: Update Task Size

### Scenario 14: Update task size from dropdown
**Given** a task exists with size "M" (2 days)  
**And** task start date is "2025-10-14"  
**And** task end date is "2025-10-16"  
**When** the user changes the size dropdown to "L" (5 days)  
**Then** the task's size should be updated to "L"  
**And** the task's originalEstimate should be updated to 5  
**And** the task's end date should be recalculated to "2025-10-21"  
**And** the size change should be tracked in history  
**And** the dirty state should be set  
**And** capacity calculations should be updated

---

### Scenario 15: Update task size with size history tracking
**Given** a task exists with size "M"  
**When** the user changes the size to "XL"  
**Then** the size history should record:
- oldSize: "M"
- newSize: "XL"
- timestamp: current date/time
- reason: "Manual update"

**And** sizeHistory array should contain the change record

---

### Scenario 16: Update task to custom size
**Given** a custom size "3D" exists with 3 days  
**And** a task exists with size "M"  
**When** the user changes the task size to "3D"  
**Then** the task's size should be "3D"  
**And** the task's originalEstimate should be 3  
**And** the end date should reflect 3 days duration

---

## Feature: Update Task Priority

### Scenario 17: Update task priority
**Given** a task exists with priority "P3"  
**When** the user changes the priority dropdown to "P1"  
**Then** the task's priority should be updated to "P1"  
**And** the task should be marked with P1 visual indicator  
**And** the dirty state should be set  
**And** P1 conflict detection should run  
**And** capacity calculations should consider P1 priority

---

### Scenario 18: Update task to P1 with existing P1 conflict
**Given** "Alice" has a P1 task from "2025-10-14" to "2025-10-20"  
**When** the user assigns another P1 task to Alice from "2025-10-16" to "2025-10-25"  
**Then** the system should detect the P1 overlap  
**And** show a warning modal with:
- "⚠️ P1 Conflict Warning"
- "Alice will have multiple P1 tasks during overlapping periods"
- Overlapping date range
- List of conflicting P1 tasks

**And** ask for user confirmation  
**When** user confirms  
**Then** the priority change should be applied  
**When** user cancels  
**Then** the priority change should be reverted

---

## Feature: Update Task Start Date

### Scenario 19: Update task start date manually
**Given** a task exists with start date "2025-10-14"  
**And** size "M" (2 days)  
**And** end date "2025-10-16"  
**When** the user changes the start date to "2025-10-21"  
**Then** the task's start date should be updated to "2025-10-21"  
**And** the task's end date should be recalculated to "2025-10-23"  
**And** the start date change should be tracked in history  
**And** the dirty state should be set  
**And** capacity calculations should be updated  
**And** people display should be refreshed

---

### Scenario 20: Update task start date with history tracking
**Given** a task exists with start date "2025-10-14"  
**When** the user changes the start date to "2025-10-21"  
**Then** the start date history should record:
- oldDate: "2025-10-14"
- newDate: "2025-10-21"
- timestamp: current date/time
- reason: "Manual update"

**And** startDateHistory array should contain the change record

---

### Scenario 21: Update task start date to weekend (auto-adjust)
**Given** a task exists  
**When** the user sets the start date to Saturday "2025-10-18"  
**Then** the start date should be auto-adjusted to Monday "2025-10-20"  
**When** the user sets the start date to Sunday "2025-10-19"  
**Then** the start date should be auto-adjusted to Monday "2025-10-20"

---

## Feature: Update Task Description

### Scenario 22: Update task description
**Given** a task exists with description "Fix login bug"  
**When** the user updates the description to "Fix login authentication issue"  
**Then** the task's description should be updated  
**And** the dirty state should be set  
**And** the change should be saved to localStorage

---

## Feature: Bulk Task Operations

### Scenario 23: Bulk import tasks from CSV
**Given** a CSV file contains:
```
Description,StartDate,Size,Priority,Assigned
"Task A","2025-10-21","M","P1","Alice"
"Task B","2025-10-22","L","P2","Bob|Charlie"
```

**When** the user imports the CSV  
**Then** 2 tasks should be created  
**And** Task A should have:
- assigned: ["Alice"]
- size: "M"
- priority: "P1"

**And** Task B should have:
- assigned: ["Bob", "Charlie"]
- size: "L"
- priority: "P2"

**And** all tasks should be saved to localStorage

---

### Scenario 24: Bulk import with duplicate detection
**Given** a task "Task A" already exists  
**And** a CSV file contains "Task A" and "Task B"  
**When** the user imports the CSV  
**Then** "Task A" should be skipped with warning  
**And** "Task B" should be added  
**And** import summary should show:
- Added: 1
- Skipped: 1

---

### Scenario 25: Add multiple tasks via text input
**Given** the user enters in bulk input:
```
Design homepage
Implement API
Write tests
```

**When** the user clicks "Add All Tasks"  
**Then** 3 tasks should be created with default settings  
**And** each task should have unique ID  
**And** all tasks should appear in task table

---

## Feature: Task Validation

### Scenario 26: Validate task with invalid date
**Given** the user is adding a task  
**When** the user enters an invalid date format "abc-def-ghi"  
**Then** the system should use the default start date  
**Or** show a validation error

---

### Scenario 27: Validate task with past date warning
**Given** today is "2025-10-14"  
**When** the user sets start date to "2025-10-01" (past date)  
**Then** the task should be created  
**And** the task should be flagged as "overdue"  
**And** appear in overdue task detection

---

## Feature: Task Display and Rendering

### Scenario 28: Render task in table with all properties
**Given** a task exists with all properties populated  
**When** the task table is rendered  
**Then** the task row should display:
- Description
- Start date (editable)
- Size (dropdown)
- Priority (dropdown)
- Status (clickable badge)
- Assignment checkboxes
- End date (calculated, optionally custom)
- Remove button

**And** all fields should be interactive

---

### Scenario 29: Task sorting in table
**Given** multiple tasks exist with different priorities  
**When** the task table is rendered  
**Then** tasks should be sorted by:
1. Priority (P1, P2, P3, P4, P5)
2. Start date (earliest first)

---

### Scenario 30: Task display with no assignees
**Given** a task has assigned: []  
**When** the task table is rendered  
**Then** the assignment column should show "Unassigned"  
**Or** show empty checkboxes with all unchecked

---

**Document Version:** 1.0  
**Feature Area:** Task Management  
**Last Updated:** October 14, 2025
