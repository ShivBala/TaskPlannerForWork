# Acceptance Criteria: Task Status Management

## Feature: Status Cycling (Click to Advance)

### Scenario 1: Cycle from To Do to In Progress
**Given** a task exists with status "To Do"  
**When** the user clicks on the status badge  
**Then** the task status should change to "In Progress"  
**And** the status badge should update to show "In Progress" with appropriate styling  
**And** the change should be saved to localStorage  
**And** the dirty state should be set

---

### Scenario 2: Cycle from In Progress to Done
**Given** a task exists with status "In Progress"  
**When** the user clicks on the status badge  
**Then** the task status should change to "Done"  
**And** the completedDate should be set to current date  
**And** the status badge should update to show "Done" with appropriate styling  
**And** the task should be excluded from capacity calculations  
**And** the change should be saved to localStorage

---

### Scenario 3: Cycle from Done to Paused
**Given** a task exists with status "Done"  
**When** the user clicks on the status badge  
**Then** the task status should change to "Paused"  
**And** the status badge should update to show "Paused" with appropriate styling  
**And** the change should be saved to localStorage

---

### Scenario 4: Cycle from Paused to To Do
**Given** a task exists with status "Paused"  
**When** the user clicks on the status badge  
**Then** the task status should change to "To Do"  
**And** the status badge should update to show "To Do" with appropriate styling  
**And** the task should be included in capacity calculations  
**And** the change should be saved to localStorage

---

### Scenario 5: Status cycle completes full loop
**Given** a task starts with status "To Do"  
**When** the user clicks the status badge 4 times  
**Then** the status should cycle through:
1. "To Do" → click → "In Progress"
2. "In Progress" → click → "Done"
3. "Done" → click → "Paused"
4. "Paused" → click → "To Do"

**And** end up back at "To Do"

---

## Feature: Status Right-Click Menu

### Scenario 6: Right-click to set specific status
**Given** a task exists with status "To Do"  
**When** the user right-clicks on the status badge  
**Then** a context menu should appear with options:
- To Do
- In Progress
- Done
- Paused
- Closed

**And** the menu should prevent default browser context menu

---

### Scenario 7: Select status from context menu
**Given** a task has status "To Do"  
**And** the user right-clicks the status badge  
**When** the user clicks "Done" from the context menu  
**Then** the task status should change directly to "Done"  
**And** completedDate should be set  
**And** the context menu should close  
**And** the change should be saved

---

### Scenario 8: Cancel context menu
**Given** the status context menu is open  
**When** the user clicks elsewhere or presses Escape  
**Then** the context menu should close  
**And** no status change should occur

---

## Feature: Status Badge Visual Styling

### Scenario 9: Display To Do status badge
**Given** a task has status "To Do"  
**When** the task is rendered  
**Then** the status badge should:
- Show text: "📋 To Do"
- Have blue color scheme (bg-blue-100, text-blue-800)
- Be clickable
- Show hover effect

---

### Scenario 10: Display In Progress status badge
**Given** a task has status "In Progress"  
**When** the task is rendered  
**Then** the status badge should:
- Show text: "🔄 In Progress"
- Have yellow color scheme (bg-yellow-100, text-yellow-800)
- Be clickable
- Show hover effect

---

### Scenario 11: Display Done status badge
**Given** a task has status "Done"  
**When** the task is rendered  
**Then** the status badge should:
- Show text: "✅ Done"
- Have green color scheme (bg-green-100, text-green-800)
- Be clickable
- Show hover effect

---

### Scenario 12: Display Paused status badge
**Given** a task has status "Paused"  
**When** the task is rendered  
**Then** the status badge should:
- Show text: "⏸️ Paused"
- Have gray color scheme (bg-gray-100, text-gray-800)
- Be clickable
- Show hover effect

---

### Scenario 13: Display Closed status badge
**Given** a task has status "Closed"  
**When** the task is rendered  
**Then** the status badge should:
- Show text: "🚫 Closed"
- Have red color scheme (bg-red-100, text-red-800)
- Be clickable
- Show hover effect

---

## Feature: Status with Comments/Notes

### Scenario 14: Display status with comment indicator
**Given** a task has status "Paused"  
**And** task has statusComments: "Waiting for API access"  
**When** the status badge is rendered  
**Then** the badge should display:
- "⏸️ Paused 💬"
- Comment icon (💬) to indicate notes exist

---

### Scenario 15: Show status tooltip with comments
**Given** a task has status "Paused"  
**And** task has statusComments: "Waiting for API access"  
**When** the user hovers over the status badge  
**Then** a tooltip should appear with:
- "Status: Paused"
- "Note: Waiting for API access"

---

### Scenario 16: Status without comments
**Given** a task has status "In Progress"  
**And** task has no statusComments  
**When** the status badge is rendered  
**Then** the badge should display:
- "🔄 In Progress" (no comment icon)
- Tooltip should only show: "Status: In Progress"

---

## Feature: Status Change with Completion Date

### Scenario 17: Set completion date when marking Done
**Given** a task has status "In Progress"  
**And** task has no completedDate  
**When** the user changes status to "Done"  
**Then** completedDate should be set to current date in format YYYY-MM-DD  
**And** completedDate should be displayed in task details

---

### Scenario 18: Clear completion date when reverting from Done
**Given** a task has status "Done"  
**And** task has completedDate: "2025-10-14"  
**When** the user changes status to "In Progress"  
**Then** completedDate should remain (historical record)  
**But** task should be treated as active again in calculations

---

### Scenario 19: Keep completion date when changing to Closed
**Given** a task has status "Done"  
**And** task has completedDate: "2025-10-14"  
**When** the user changes status to "Closed"  
**Then** completedDate should be preserved  
**And** task should remain excluded from capacity calculations

---

## Feature: Status Filtering

### Scenario 20: Filter tasks by single status
**Given** tasks exist with various statuses:
- Task 1: To Do
- Task 2: In Progress
- Task 3: Done
- Task 4: Paused

**When** the user clicks status filter button "In Progress"  
**Then** only Task 2 should be visible  
**And** other tasks should be hidden  
**And** the "In Progress" filter button should be highlighted

---

### Scenario 21: Filter by multiple statuses
**Given** tasks exist with various statuses  
**When** the user clicks status filter buttons:
- "To Do" ✓
- "In Progress" ✓

**Then** tasks with "To Do" OR "In Progress" should be visible  
**And** tasks with "Done" or "Paused" should be hidden  
**And** both filter buttons should be highlighted

---

### Scenario 22: Clear status filter
**Given** status filter is active for "Done"  
**When** the user clicks the "Clear" button or deselects all status filters  
**Then** all tasks should be visible regardless of status  
**And** no status filter buttons should be highlighted

---

### Scenario 23: Combined person and status filters
**Given** tasks exist:
- Task 1: Alice, To Do
- Task 2: Alice, Done
- Task 3: Bob, To Do

**When** the user filters by:
- Person: "Alice"
- Status: "To Do"

**Then** only Task 1 should be visible  
**And** Task 2 should be hidden (Alice but wrong status)  
**And** Task 3 should be hidden (To Do but wrong person)

---

## Feature: Status Impact on Capacity

### Scenario 24: Exclude Done tasks from capacity
**Given** a task is assigned to "Alice" with 10 hours effort  
**And** task status is "Done"  
**When** capacity calculations run  
**Then** the task should NOT be included in Alice's workload  
**And** Alice's available capacity should NOT be reduced  
**And** the task should NOT appear in capacity heat map

---

### Scenario 25: Exclude Paused tasks from capacity
**Given** a task is assigned to "Bob" with 15 hours effort  
**And** task status is "Paused"  
**When** capacity calculations run  
**Then** the task should NOT be included in Bob's workload  
**And** Bob's available capacity should NOT be reduced  
**And** the task should NOT appear in capacity projections

---

### Scenario 26: Exclude Closed tasks from capacity
**Given** a task is assigned to "Charlie" with 20 hours effort  
**And** task status is "Closed"  
**When** capacity calculations run  
**Then** the task should NOT be included in Charlie's workload  
**And** Charlie's available capacity should NOT be reduced

---

### Scenario 27: Include To Do and In Progress in capacity
**Given** tasks exist:
- Task 1: Alice, To Do, 10 hours
- Task 2: Alice, In Progress, 15 hours

**When** capacity calculations run  
**Then** both tasks should be included in Alice's workload  
**And** Alice's capacity should be reduced by 25 hours total  
**And** both tasks should appear in capacity heat map

---

## Feature: Status Change History (Future Enhancement)

### Scenario 28: Track status change history
**Given** a task status changes from "To Do" to "In Progress"  
**When** the status changes  
**Then** status history should record:
- oldStatus: "To Do"
- newStatus: "In Progress"
- timestamp: current date/time
- reason: "Manual status change"

**And** statusHistory array should contain the change record

---

### Scenario 29: View status change history
**Given** a task has multiple status changes in history  
**When** the user requests status history  
**Then** a timeline should display:
- All status transitions
- Timestamps
- Duration in each status

---

## Feature: Bulk Status Updates

### Scenario 30: Mark multiple tasks as Done
**Given** 5 tasks are selected with status "In Progress"  
**When** the user clicks "Mark All as Done"  
**Then** all 5 tasks should change to "Done"  
**And** each should have completedDate set  
**And** all should be excluded from capacity  
**And** changes should be saved to localStorage

---

### Scenario 31: Pause multiple tasks
**Given** 3 tasks are selected with status "To Do"  
**When** the user clicks "Pause All Selected"  
**Then** all 3 tasks should change to "Paused"  
**And** all should be excluded from capacity  
**And** changes should be saved

---

## Feature: Status Validation

### Scenario 32: Handle undefined status
**Given** a task has no status field (legacy data)  
**When** the task is rendered  
**Then** status should default to "To Do"  
**And** the task should be migrated to include status: "To Do"  
**And** saved to localStorage

---

### Scenario 33: Handle invalid status value
**Given** a task has status: "InvalidStatus"  
**When** the task is rendered  
**Then** status should be corrected to "To Do"  
**Or** display error and request manual correction

---

**Document Version:** 1.0  
**Feature Area:** Task Status Management  
**Last Updated:** October 14, 2025
