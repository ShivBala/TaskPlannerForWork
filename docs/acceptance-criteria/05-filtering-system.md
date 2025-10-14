# Acceptance Criteria: Filtering System

## Feature: Person Filtering

### Scenario 1: Filter by single person
**Given** tasks exist assigned to multiple people:
- Task 1: Alice
- Task 2: Bob
- Task 3: Alice
- Task 4: Charlie

**When** the user clicks person filter button for "Alice"  
**Then** only tasks assigned to Alice should be visible (Task 1, Task 3)  
**And** Alice's filter button should be highlighted/active  
**And** the filter status should show: "Filtering by: Alice"  
**And** the clear filter button should be visible

---

### Scenario 2: Filter by multiple people (OR logic)
**Given** tasks exist  
**When** the user clicks filter buttons for:
- "Alice" ✓
- "Bob" ✓

**Then** tasks assigned to Alice OR Bob should be visible  
**And** both filter buttons should be highlighted  
**And** filter status should show: "Filtering by: Alice, Bob"

---

### Scenario 3: Clear person filter
**Given** person filter is active for "Alice"  
**When** the user clicks the "Clear" button  
**Then** all tasks should be visible  
**And** no person filter buttons should be highlighted  
**And** the clear button should be hidden  
**And** filter status should be empty

---

### Scenario 4: Filter task with multiple assignees
**Given** Task 1 is assigned to ["Alice", "Bob"]  
**When** user filters by "Alice"  
**Then** Task 1 should be visible (Alice is one of the assignees)  
**When** user filters by "Bob"  
**Then** Task 1 should be visible (Bob is one of the assignees)  
**When** user filters by "Charlie"  
**Then** Task 1 should be hidden

---

### Scenario 5: Filter with no matching tasks
**Given** no tasks are assigned to "David"  
**When** user filters by "David"  
**Then** no tasks should be visible  
**And** "No tasks found for David" message should be displayed

---

## Feature: Status Filtering

### Scenario 6: Filter by single status
**Given** tasks exist with various statuses:
- Task 1: To Do
- Task 2: In Progress
- Task 3: Done
- Task 4: To Do

**When** user clicks status filter button "To Do"  
**Then** only tasks with "To Do" status should be visible (Task 1, Task 4)  
**And** "To Do" filter button should be highlighted

---

### Scenario 7: Filter by multiple statuses
**Given** tasks exist with various statuses  
**When** user selects status filters:
- "To Do" ✓
- "In Progress" ✓

**Then** tasks with "To Do" OR "In Progress" should be visible  
**And** tasks with "Done", "Paused", "Closed" should be hidden  
**And** both filter buttons should be highlighted

---

### Scenario 8: Clear status filter
**Given** status filter is active  
**When** user clicks clear or deselects all status filters  
**Then** all tasks should be visible (status-wise)  
**And** no status filter buttons should be highlighted

---

## Feature: Combined Filters

### Scenario 9: Combine person and status filters (AND logic)
**Given** tasks exist:
- Task 1: Alice, To Do
- Task 2: Alice, Done
- Task 3: Bob, To Do
- Task 4: Bob, In Progress

**When** user filters by:
- Person: "Alice"
- Status: "To Do"

**Then** only Task 1 should be visible  
**And** Task 2 should be hidden (Alice but wrong status)  
**And** Task 3 should be hidden (To Do but wrong person)

---

### Scenario 10: Multiple people and multiple statuses
**Given** tasks exist  
**When** user filters by:
- Person: "Alice" OR "Bob"
- Status: "To Do" OR "In Progress"

**Then** tasks matching (Alice OR Bob) AND (To Do OR In Progress) should be visible

---

### Scenario 11: Clear all filters
**Given** both person and status filters are active  
**When** user clicks "Clear All Filters" button  
**Then** all filters should be cleared  
**And** all tasks should be visible  
**And** all filter buttons should be unhighlighted

---

## Feature: Filter Button State Management

### Scenario 12: Toggle person filter on/off
**Given** no filters are active  
**When** user clicks "Alice" filter button  
**Then** Alice filter should activate (button highlighted)  
**When** user clicks "Alice" filter button again  
**Then** Alice filter should deactivate (button unhighlighted)  
**And** all tasks should be visible

---

### Scenario 13: Filter button visual states
**Given** person filter buttons exist  
**Then** inactive buttons should have:
- Default background color
- Default text color
- Hover effect on mouseover

**When** a filter is activated  
**Then** active button should have:
- Highlighted background (blue/accent color)
- White text color
- Active border or shadow

---

### Scenario 14: Update filter buttons when people change
**Given** person filter buttons exist for Alice, Bob, Charlie  
**When** Charlie is removed from the system  
**Then** Charlie's filter button should be removed  
**And** if Charlie filter was active, it should be cleared

---

## Feature: Filter Persistence

### Scenario 15: Maintain filters during task updates
**Given** filter is active for "Alice"  
**When** user adds a new task assigned to "Bob"  
**Then** the new task should not be visible (filtered out)  
**And** filter should remain active for "Alice"

---

### Scenario 16: Maintain filters during status changes
**Given** filter is active for status "To Do"  
**When** user changes Task 1 from "To Do" to "In Progress"  
**Then** Task 1 should disappear from filtered view  
**And** filter should remain active for "To Do"

---

### Scenario 17: Filter state after page refresh (optional)
**Given** filters are active  
**When** user refreshes the page  
**Then** filters may be cleared (no persistence)  
**Or** filters should be restored from localStorage (if persistence is implemented)

---

## Feature: Filter Status Display

### Scenario 18: Show active filter count
**Given** multiple filters are active:
- Person: Alice, Bob
- Status: To Do, In Progress

**When** filter status is displayed  
**Then** status should show:
- "Filtering by: Alice, Bob"
- "Status: To Do, In Progress"
- "Showing X of Y tasks"

---

### Scenario 19: Show no results message
**Given** filters result in no matching tasks  
**Then** display should show:
- "No tasks found matching filters"
- List of active filters
- Suggestion to clear filters

---

### Scenario 20: Show filter summary on hover
**Given** person filter button for "Alice" is hovered  
**Then** tooltip should show:
- "Alice"
- Number of tasks: "3 tasks"
- Click to filter/unfilter

---

## Feature: Filter Performance

### Scenario 21: Filter large dataset efficiently
**Given** 100+ tasks exist  
**When** user applies a filter  
**Then** filtering should complete in < 100ms  
**And** UI should not freeze  
**And** filtered results should display immediately

---

### Scenario 22: Update filters on data change
**Given** filter is active for "Alice" showing 5 tasks  
**When** a new task is added for Alice  
**Then** filtered view should update to show 6 tasks  
**And** update should be automatic (reactive)

---

## Feature: Filter UI/UX

### Scenario 23: Responsive filter layout
**Given** person filter buttons exist for 10+ people  
**When** viewport is resized to mobile  
**Then** filter buttons should wrap to multiple lines  
**And** remain clickable and readable

---

### Scenario 24: Clear filter button visibility
**Given** no filters are active  
**Then** clear filter button should be hidden  
**When** any filter is activated  
**Then** clear filter button should become visible

---

### Scenario 25: Filter button hover states
**Given** person filter buttons exist  
**When** user hovers over an inactive button  
**Then** button should show hover effect (lighter background)  
**When** user hovers over an active button  
**Then** button should show darker/emphasized state

---

## Feature: Filter Accessibility

### Scenario 26: Keyboard navigation for filters
**Given** filter buttons are rendered  
**When** user uses Tab key  
**Then** focus should move through filter buttons  
**When** user presses Enter or Space on a focused button  
**Then** the filter should toggle on/off

---

### Scenario 27: Screen reader support
**Given** filter buttons exist  
**Then** each button should have appropriate ARIA labels:
- aria-label="Filter by Alice"
- aria-pressed="true/false" (active state)
- role="button"

---

## Feature: Advanced Filtering (Future)

### Scenario 28: Search filter by task description
**Given** tasks exist with various descriptions  
**When** user types "API" in search box  
**Then** only tasks with "API" in description should be visible

---

### Scenario 29: Date range filter
**Given** tasks with various start dates exist  
**When** user selects date range "Oct 14 - Oct 20"  
**Then** only tasks starting within that range should be visible

---

### Scenario 30: Priority filter
**Given** tasks with various priorities exist  
**When** user filters by "P1" priority  
**Then** only P1 tasks should be visible

---

**Document Version:** 1.0  
**Feature Area:** Filtering System  
**Last Updated:** October 14, 2025
