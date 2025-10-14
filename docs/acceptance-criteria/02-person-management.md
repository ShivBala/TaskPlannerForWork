# Acceptance Criteria: Person/Resource Management

## Feature: Add New Person

### Scenario 1: Add person with default values
**Given** the user is on the task tracker page  
**When** the user enters name "Sarah" in the "Add New Person" field  
**And** clicks "Add Person" button  
**Then** a new person should be created with:
- name: "Sarah"
- availability: [25, 25, 25, 25, 25, 25, 25, 25] (8 weeks × 25 hours)
- isProjectReady: true (default)

**And** the person should appear in the people list  
**And** the person should be available in task assignment checkboxes  
**And** the change should be saved to localStorage  
**And** the dirty state indicator should be shown  
**And** capacity calculations should be updated

---

### Scenario 2: Add person with empty name (validation)
**Given** the user is on the task tracker page  
**When** the user leaves the name field empty  
**And** clicks "Add Person" button  
**Then** no person should be created  
**And** an alert should show: "Person already exists or name is invalid."  
**And** the people list should remain unchanged

---

### Scenario 3: Add duplicate person (prevention)
**Given** a person named "Alice" already exists  
**When** the user tries to add another person named "Alice"  
**And** clicks "Add Person" button  
**Then** no person should be created  
**And** an alert should show: "Person already exists or name is invalid."  
**And** the people list should remain unchanged

---

### Scenario 4: Add person with whitespace name (validation)
**Given** the user enters "   " (spaces only) in name field  
**When** the user clicks "Add Person" button  
**Then** no person should be created  
**And** validation should fail on trim()

---

### Scenario 5: Add person and verify UI updates
**Given** the user adds a new person "Charlie"  
**Then** the person card should appear in the people section with:
- Name: "Charlie"
- 8 availability input fields (Week 1 through Week 8)
- Each field defaulted to 25 hours
- "🎯 Project Ready Resource" checkbox checked
- Remove button

**And** "Charlie" should appear in all task assignment dropdowns/checkboxes

---

## Feature: Remove Person

### Scenario 6: Remove person with no task assignments
**Given** a person "Bob" exists  
**And** Bob has no tasks assigned  
**When** the user clicks the remove button for Bob  
**Then** Bob should be removed from the people array  
**And** Bob should disappear from the people list  
**And** Bob should be removed from all task assignment UI  
**And** the change should be saved to localStorage  
**And** the dirty state should be set  
**And** capacity calculations should be updated

---

### Scenario 7: Remove person with active task assignments
**Given** a person "Alice" exists  
**And** Task 1 is assigned to ["Alice", "Bob"]  
**And** Task 2 is assigned to ["Alice"]  
**When** the user clicks the remove button for Alice  
**Then** Alice should be removed from the people array  
**And** Alice should be removed from all task assignments:
- Task 1 assigned becomes ["Bob"]
- Task 2 assigned becomes []

**And** Alice should disappear from the people list  
**And** the change should be saved to localStorage  
**And** capacity calculations should be updated

---

### Scenario 8: Remove last person
**Given** only one person "Alice" exists  
**When** the user removes Alice  
**Then** the people array should be empty  
**And** the people list should show no person cards  
**And** task assignment checkboxes should be empty  
**And** all tasks should become unassigned

---

## Feature: Update Person Availability

### Scenario 9: Update single week availability
**Given** a person "Alice" exists with Week 1 availability of 25 hours  
**When** the user changes Week 1 availability to 30 hours  
**Then** Alice's availability[0] should be updated to 30  
**And** the change should be saved to localStorage  
**And** the dirty state should be set  
**And** capacity calculations should be updated  
**And** Alice's heat map should reflect the new availability

---

### Scenario 10: Update availability to zero
**Given** a person "Bob" exists with Week 2 availability of 25 hours  
**When** the user changes Week 2 availability to 0 hours  
**Then** Bob's availability[1] should be updated to 0  
**And** Bob should have no capacity for Week 2  
**And** Week 2 should show as fully booked/unavailable for Bob

---

### Scenario 11: Update availability with negative value (validation)
**Given** a person "Charlie" exists  
**When** the user tries to enter -10 in any availability field  
**Then** the system should convert it to 0 (Math.max(0, value))  
**And** the availability should be set to 0

---

### Scenario 12: Update availability with non-numeric value (validation)
**Given** a person "Alice" exists  
**When** the user enters "abc" in Week 3 availability field  
**Then** the system should detect NaN  
**And** no update should occur (early return)  
**And** the availability should remain unchanged

---

### Scenario 13: Update multiple weeks availability
**Given** a person "Alice" exists  
**When** the user updates:
- Week 1: 20 hours
- Week 2: 15 hours
- Week 3: 30 hours

**Then** Alice's availability should be [20, 15, 30, 25, 25, 25, 25, 25]  
**And** each change should trigger capacity recalculation  
**And** the dirty state should be set

---

### Scenario 14: Update availability for person on leave
**Given** a person "Bob" is on leave for Weeks 4-6  
**When** the user sets:
- Week 4: 0
- Week 5: 0
- Week 6: 0

**Then** Bob's availability should be [25, 25, 25, 0, 0, 0, 25, 25]  
**And** Bob should have no capacity for those weeks  
**And** tasks should not be scheduled in those weeks

---

## Feature: Toggle Project Ready Flag

### Scenario 15: Set person as not project ready
**Given** a person "Alice" exists with isProjectReady: true  
**When** the user unchecks the "🎯 Project Ready Resource" checkbox  
**Then** Alice's isProjectReady should be updated to false  
**And** the change should be saved to localStorage  
**And** the dirty state should be set  
**And** capacity calculations should be updated  
**And** Alice should be excluded from project timeline calculations  
**But** Alice's tasks should still appear in task list

---

### Scenario 16: Set person as project ready
**Given** a person "Bob" exists with isProjectReady: false  
**When** the user checks the "🎯 Project Ready Resource" checkbox  
**Then** Bob's isProjectReady should be updated to true  
**And** Bob should be included in project timeline calculations  
**And** Bob's completion date should affect overall project timeline

---

### Scenario 17: Project ready flag and capacity distribution
**Given** Task 1 is assigned to ["Alice", "Bob"]  
**And** Alice has isProjectReady: true  
**And** Bob has isProjectReady: false  
**When** capacity is calculated  
**Then** both Alice and Bob should show the task in their workload  
**But** only Alice's completion date should affect project timeline  
**And** Bob's capacity should be tracked but not critical path

---

## Feature: Person Display and Rendering

### Scenario 18: Render person card with all details
**Given** a person "Alice" exists with:
- availability: [25, 20, 30, 25, 15, 25, 25, 25]
- isProjectReady: true

**When** the people section is rendered  
**Then** Alice's card should display:
- Name: "Alice"
- 8 availability input fields with values [25, 20, 30, 25, 15, 25, 25, 25]
- "🎯 Project Ready Resource" checkbox: checked
- Week range info showing date ranges
- Remove button

---

### Scenario 19: Render person with low availability warning
**Given** a person "Bob" has Week 3 availability of 5 hours  
**And** Bob has tasks requiring 20 hours in Week 3  
**When** the capacity display is rendered  
**Then** Bob's Week 3 should show capacity overload warning  
**And** visual indicator should highlight the conflict

---

### Scenario 20: Render people in sorted order
**Given** multiple people exist: ["Zara", "Alice", "Mike"]  
**When** the people list is rendered  
**Then** people should be displayed in order:
1. Alice
2. Mike
3. Zara
(Alphabetically sorted)

---

## Feature: Person Capacity Calculations

### Scenario 21: Calculate person available hours for week
**Given** a person "Alice" has Week 1 availability: 25 hours  
**And** Alice has tasks requiring 10 hours in Week 1  
**When** capacity is calculated  
**Then** Alice's remaining capacity for Week 1 should be 15 hours  
**And** capacity utilization should be 40% (10/25)

---

### Scenario 22: Calculate person over-capacity
**Given** a person "Bob" has Week 2 availability: 25 hours  
**And** Bob has tasks requiring 35 hours in Week 2  
**When** capacity is calculated  
**Then** Bob should be over-capacity by 10 hours  
**And** capacity utilization should be 140% (35/25)  
**And** visual warning should be displayed

---

### Scenario 23: Calculate person with zero availability
**Given** a person "Charlie" has Week 4 availability: 0 hours  
**When** capacity is calculated  
**Then** Charlie should have 0 capacity for Week 4  
**And** no tasks should be scheduled in that week  
**And** if tasks exist, they should show as blocked/delayed

---

### Scenario 24: Calculate multi-person task capacity distribution
**Given** Task 1 is assigned to ["Alice", "Bob", "Charlie"]  
**And** Task 1 requires 30 hours  
**When** capacity is calculated  
**Then** task effort should be distributed:
- Alice: 10 hours (⅓)
- Bob: 10 hours (⅓)
- Charlie: 10 hours (⅓)

**And** each person's capacity should be reduced by 10 hours

---

## Feature: Person Migration and Data Integrity

### Scenario 25: Migrate person to 8-week availability
**Given** legacy person data exists with 5 weeks: [25, 25, 25, 25, 25]  
**When** the system loads and runs migratePeopleToEightWeeks()  
**Then** the person's availability should be extended to [25, 25, 25, 25, 25, 25, 25, 25]  
**And** the new weeks should default to 25 hours  
**And** the change should be saved to localStorage

---

### Scenario 26: Add isProjectReady to legacy person
**Given** legacy person data exists without isProjectReady field  
**When** the system loads  
**Then** each person should have isProjectReady: true added  
**And** the change should be saved to localStorage

---

### Scenario 27: Person data validation on load
**Given** corrupted person data in localStorage  
**When** the system loads  
**Then** the system should detect invalid data  
**And** fallback to default people data  
**Or** attempt to repair the data structure

---

## Feature: Person Filter Integration

### Scenario 28: Filter tasks by person
**Given** tasks exist assigned to multiple people  
**When** the user clicks person filter button for "Alice"  
**Then** only tasks assigned to Alice should be visible  
**And** Alice's filter button should be highlighted  
**And** other people's tasks should be hidden

---

### Scenario 29: Remove person with active filter
**Given** filter is active for "Alice"  
**And** Alice is removed from the system  
**When** the people list is updated  
**Then** the filter should be cleared  
**And** all remaining tasks should be visible  
**And** the filter button for Alice should be removed

---

## Feature: Person Assignment UI

### Scenario 30: Person checkbox in task assignment
**Given** a person "Alice" exists  
**When** rendering task assignment UI  
**Then** Alice should appear as:
- ☐ Alice (unchecked by default for new tasks)
- Clickable checkbox
- Styled with hover effect

**When** user checks Alice's checkbox  
**Then** Alice should be added to task's assigned array

---

### Scenario 31: Person removed while task form is open
**Given** task add form is open  
**And** "Bob" is available in assignment checkboxes  
**When** Bob is removed from the system  
**Then** Bob's checkbox should disappear from the form  
**And** if Bob was checked, the selection should be cleared

---

## Feature: Week Range Display

### Scenario 32: Display week ranges for availability
**Given** the earliest task starts on "2025-10-14" (Monday)  
**When** the people section is rendered  
**Then** week ranges should be calculated as:
- Week 1: Oct 14 - Oct 20
- Week 2: Oct 21 - Oct 27
- Week 3: Oct 28 - Nov 3
- ... (8 weeks total)

**And** week range info should be displayed under each person's availability inputs

---

### Scenario 33: Update week ranges when earliest task changes
**Given** earliest task starts on "2025-10-14"  
**When** a new task is added with start date "2025-10-07"  
**Then** week ranges should be recalculated from "2025-10-07"  
**And** all people's week range displays should be updated

---

**Document Version:** 1.0  
**Feature Area:** Person/Resource Management  
**Last Updated:** October 14, 2025
