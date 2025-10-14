# Acceptance Criteria: Capacity & Workload Calculations

## Feature: Calculate Projected Tickets

### Scenario 1: Calculate simple task end date
**Given** a task with:
- startDate: "2025-10-14" (Monday)
- size: "M" (2 days)
- assigned: ["Alice"]

**When** getProjectedTickets() is called  
**Then** the task should have:
- originalEstimate: 2 days
- endDate: "2025-10-16" (Wednesday)
- assigned: ["Alice"]

---

### Scenario 2: Calculate task end date with custom end date override
**Given** a task with:
- startDate: "2025-10-14"
- size: "L" (5 days)
- customEndDate: "2025-10-25"

**When** getProjectedTickets() is called  
**Then** the effective end date should be "2025-10-25"  
**And** originalEstimate should still reflect "L" size (5 days)  
**But** displayed end date should be customEndDate

---

### Scenario 3: Calculate multi-person task capacity distribution
**Given** a task with:
- size: "XL" (10 days = 50 hours with 5 hours/day)
- assigned: ["Alice", "Bob"]

**When** capacity is distributed  
**Then** each person should be allocated:
- Alice: 25 hours (50% of 50 hours)
- Bob: 25 hours (50% of 50 hours)

---

### Scenario 4: Calculate task with three assignees
**Given** a task with:
- size: "XXL" (15 days = 75 hours)
- assigned: ["Alice", "Bob", "Charlie"]

**When** capacity is distributed  
**Then** each person should be allocated:
- Alice: 25 hours (⅓ of 75 hours)
- Bob: 25 hours (⅓ of 75 hours)
- Charlie: 25 hours (⅓ of 75 hours)

---

### Scenario 5: Calculate task with single assignee
**Given** a task with:
- size: "M" (2 days = 10 hours)
- assigned: ["Alice"]

**When** capacity is distributed  
**Then** Alice should be allocated:
- 10 hours (100% of task)

---

### Scenario 6: Filter out Done tasks from projections
**Given** tasks exist:
- Task 1: status "To Do", 10 hours
- Task 2: status "Done", 15 hours
- Task 3: status "In Progress", 5 hours

**When** getProjectedTickets() is called for capacity  
**Then** returned tasks should include:
- Task 1 ✓
- Task 3 ✓

**And** exclude:
- Task 2 ✗ (Done)

---

### Scenario 7: Filter out Paused tasks from projections
**Given** tasks exist:
- Task 1: status "Paused", 10 hours
- Task 2: status "To Do", 15 hours

**When** capacity calculations run  
**Then** Task 1 should be excluded  
**And** Task 2 should be included

---

### Scenario 8: Filter out Closed tasks from projections
**Given** a task has status "Closed"  
**When** capacity calculations run  
**Then** the task should be excluded from:
- Capacity projections
- Heat map calculations
- Timeline display

---

## Feature: Workload Heat Map Calculation

### Scenario 9: Calculate heat map for 8 weeks
**Given** a person "Alice" with availability [25, 25, 25, 25, 25, 25, 25, 25]  
**And** Alice has tasks spanning 6 weeks  
**When** calculateWorkloadHeatMap() is called  
**Then** heat map should calculate:
- 8 weeks of data
- Each week should have: { available, allocated, remaining }
- Weeks 1-6: show task allocations
- Weeks 7-8: show only availability

---

### Scenario 10: Calculate heat map with task starting mid-week
**Given** a task starts on Wednesday "2025-10-16"  
**And** task duration is 5 days  
**When** heat map is calculated  
**Then** task allocation should span:
- Week 1 (Oct 14-20): 3 days (Wed-Fri)
- Week 2 (Oct 21-27): 2 days (Mon-Tue)

**And** hours should be proportionally distributed

---

### Scenario 11: Calculate heat map baseline from earliest task
**Given** tasks exist with start dates:
- Task 1: "2025-10-21"
- Task 2: "2025-10-14" (earliest)
- Task 3: "2025-10-28"

**When** calculateWorkloadHeatMap() is called  
**Then** heat map should start from Monday "2025-10-14"  
**And** heatMapStartDate should be set to "2025-10-14"

---

### Scenario 12: Calculate heat map with weekend adjustment
**Given** a task starts on Saturday "2025-10-18"  
**When** heat map baseline is calculated  
**Then** task start should be adjusted to Monday "2025-10-20"  
**And** heat map should start from Monday "2025-10-20"

---

### Scenario 13: Calculate heat map with Sunday adjustment
**Given** a task starts on Sunday "2025-10-19"  
**When** heat map baseline is calculated  
**Then** task start should be adjusted to Monday "2025-10-20"

---

### Scenario 14: Calculate heat map for person with varying availability
**Given** "Bob" has availability [25, 15, 30, 20, 25, 25, 25, 25]  
**And** Bob has consistent task load of 10 hours/week  
**When** heat map is calculated  
**Then** each week should show:
- Week 1: 25 available, 10 allocated, 15 remaining
- Week 2: 15 available, 10 allocated, 5 remaining
- Week 3: 30 available, 10 allocated, 20 remaining
- Week 4: 20 available, 10 allocated, 10 remaining

---

### Scenario 15: Calculate heat map with capacity overflow
**Given** "Alice" has Week 2 availability: 25 hours  
**And** Alice has tasks requiring 40 hours in Week 2  
**When** heat map is calculated  
**Then** Week 2 should show:
- available: 25
- allocated: 40
- remaining: -15 (overflow)
- overCapacity: true

**And** visual indicator should show red/warning color

---

### Scenario 16: Calculate heat map excluding Done tasks
**Given** "Charlie" has:
- Task 1: To Do, 10 hours, Week 1
- Task 2: Done, 15 hours, Week 1
- Task 3: In Progress, 5 hours, Week 1

**When** heat map is calculated for Week 1  
**Then** allocated hours should be:
- Task 1: 10 hours ✓
- Task 2: 0 hours ✗ (excluded)
- Task 3: 5 hours ✓
- **Total: 15 hours**

---

### Scenario 17: Calculate heat map with zero availability week
**Given** "Bob" has Week 3 availability: 0 hours (on leave)  
**And** Bob has tasks assigned in Week 3  
**When** heat map is calculated  
**Then** Week 3 should show:
- available: 0
- allocated: [task hours]
- remaining: negative
- **Visual warning:** "Person on leave with assigned tasks"

---

## Feature: Person Capacity Over Weeks

### Scenario 18: Calculate person capacity with no tasks
**Given** "Alice" has availability [25, 25, 25, 25, 25, 25, 25, 25]  
**And** Alice has no tasks assigned  
**When** capacity is calculated  
**Then** all weeks should show:
- available: 25
- allocated: 0
- remaining: 25
- utilization: 0%

---

### Scenario 19: Calculate person capacity fully booked
**Given** "Bob" has availability [25, 25, 25, 25, 25, 25, 25, 25]  
**And** Bob has tasks exactly matching 25 hours each week  
**When** capacity is calculated  
**Then** all weeks should show:
- available: 25
- allocated: 25
- remaining: 0
- utilization: 100%

---

### Scenario 20: Calculate capacity for part-time person
**Given** "Charlie" has availability [15, 15, 15, 15, 15, 15, 15, 15]  
**And** Charlie has tasks requiring 10 hours/week  
**When** capacity is calculated  
**Then** each week should show:
- available: 15
- allocated: 10
- remaining: 5
- utilization: 66.7%

---

## Feature: Priority-Based Capacity Allocation

### Scenario 21: Allocate P1 tasks before P3 tasks
**Given** "Alice" has 25 hours availability in Week 1  
**And** tasks exist:
- Task A: P1, 15 hours
- Task B: P3, 20 hours

**When** capacity is allocated  
**Then** Task A (P1) should be fully allocated first: 15 hours  
**And** Task B (P3) should get remaining: 10 hours  
**And** Task B should show: "Delayed - insufficient capacity"

---

### Scenario 22: Multiple P1 tasks capacity conflict
**Given** "Bob" has 25 hours in Week 1  
**And** tasks exist:
- Task X: P1, 20 hours
- Task Y: P1, 15 hours

**When** capacity is allocated  
**Then** both P1 tasks should be flagged  
**And** warning should show: "P1 conflict - capacity overflow"  
**And** user should be prompted to resolve

---

### Scenario 23: Priority ordering (P1 > P2 > P3 > P4 > P5)
**Given** tasks with mixed priorities exist  
**When** capacity allocation runs  
**Then** tasks should be processed in order:
1. All P1 tasks first
2. Then P2 tasks
3. Then P3 tasks
4. Then P4 tasks
5. Finally P5 tasks

**And** lower priority tasks should be delayed if capacity is insufficient

---

## Feature: Task Sequencing and Dependencies

### Scenario 24: Sequential tasks for same person
**Given** "Alice" has:
- Task 1: Oct 14-18 (Week 1)
- Task 2: Oct 21-25 (Week 2)

**When** capacity is calculated  
**Then** tasks should not overlap  
**And** each task should have distinct time allocation

---

### Scenario 25: Concurrent tasks for same person (capacity split)
**Given** "Bob" has:
- Task A: Oct 14-25 (2 weeks), 20 hours
- Task B: Oct 14-20 (1 week), 15 hours

**When** both tasks run in Week 1  
**Then** Week 1 capacity should show:
- Task A allocation: 10 hours (half of 20)
- Task B allocation: 15 hours
- **Total: 25 hours** (if 25 available)

---

## Feature: Project Ready Flag Impact

### Scenario 26: Calculate timeline with project ready people
**Given** tasks assigned to:
- Alice (isProjectReady: true), completes Week 4
- Bob (isProjectReady: true), completes Week 6

**When** project completion date is calculated  
**Then** project end date should be Week 6  
**And** based on latest project-ready person

---

### Scenario 27: Exclude non-project-ready from timeline
**Given** tasks assigned to:
- Alice (isProjectReady: true), completes Week 4
- Charlie (isProjectReady: false), completes Week 8

**When** project completion date is calculated  
**Then** project end date should be Week 4  
**And** Charlie's completion should not affect project timeline  
**But** Charlie's capacity should still be tracked

---

### Scenario 28: All people non-project-ready
**Given** all people have isProjectReady: false  
**When** project timeline is calculated  
**Then** no project completion date should be shown  
**Or** warning message: "No project-ready resources assigned"

---

## Feature: Overdue Task Impact on Capacity

### Scenario 29: Overdue task capacity calculation
**Given** today is "2025-10-14"  
**And** a task with:
- startDate: "2025-10-01" (13 days overdue)
- status: "To Do"
- assigned: ["Alice"]

**When** capacity is calculated  
**Then** the task should still consume capacity  
**And** should show visual warning: "Overdue"  
**And** should affect current week capacity

---

### Scenario 30: Multiple overdue tasks capacity stacking
**Given** "Bob" has 3 overdue tasks totaling 60 hours  
**And** Bob has 25 hours/week availability  
**When** capacity is calculated  
**Then** current week should show severe overflow  
**And** overdue tasks should be prioritized in allocation  
**And** visual indicator should show critical state

---

## Feature: Effort Mapping and Configuration

### Scenario 31: Calculate with custom effort map
**Given** effortMap is set to: {"Alice": 0.8, "Bob": 1.0}  
**And** a task requires 10 hours  
**When** task is assigned to Alice  
**Then** Alice's allocated time should be: 10 × 0.8 = 8 hours  
**When** task is assigned to Bob  
**Then** Bob's allocated time should be: 10 × 1.0 = 10 hours

---

### Scenario 32: Calculate with estimation base hours
**Given** estimationBaseHours is set to 6 hours/day  
**And** a task is size "M" (2 days)  
**When** capacity is calculated  
**Then** task effort should be: 2 × 6 = 12 hours

---

### Scenario 33: Calculate with project hours per day
**Given** projectHoursPerDay is set to 5  
**And** a person has 25 hours/week availability  
**When** timeline is calculated  
**Then** days calculation should be: 25 hours / 5 hours/day = 5 days

---

**Document Version:** 1.0  
**Feature Area:** Capacity & Workload Calculations  
**Last Updated:** October 14, 2025
