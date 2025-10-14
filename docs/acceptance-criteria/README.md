# Acceptance Criteria Index - HTML Task Tracker

## Overview
This directory contains comprehensive Given-When-Then acceptance criteria for all features of the HTML Task Tracker application. Each document covers a specific functional area with detailed scenarios.

---

## Document Structure

### 📋 [01 - Task Management](./01-task-management.md)
**30 Scenarios** covering:
- Add new task (with validations)
- Remove task
- Update task assignments
- Update task size
- Update task priority
- Update task start date
- Update task description
- Bulk task operations
- Task validation rules
- Task display and rendering

**Key Scenarios:**
- Add task with all required fields
- Duplicate task prevention
- Multi-assignee tasks
- P1 conflict detection on priority update
- Task size change with history tracking
- Bulk CSV import with duplicate detection

---

### 👥 [02 - Person/Resource Management](./02-person-management.md)
**33 Scenarios** covering:
- Add new person
- Remove person (with task cleanup)
- Update person availability (8 weeks)
- Toggle Project Ready flag
- Person capacity calculations
- Person display and rendering
- Data migration for legacy formats
- Person filter integration
- Week range display

**Key Scenarios:**
- Add person with default 8-week availability
- Remove person removes from all task assignments
- Zero availability handling (person on leave)
- Multi-person task capacity distribution
- Project Ready flag excludes from timeline
- Migrate legacy 5-week to 8-week availability

---

### 🚦 [03 - Status Management](./03-status-management.md)
**33 Scenarios** covering:
- Status cycling (click to advance)
- Right-click status context menu
- Status badge visual styling
- Status with comments/notes
- Completion date management
- Status filtering
- Status impact on capacity
- Status change history
- Bulk status updates

**Key Scenarios:**
- Cycle: To Do → In Progress → Done → Paused → To Do
- Right-click menu for direct status selection
- Set completion date when marking Done
- Exclude Done/Paused/Closed from capacity
- Status filter combinations
- Status badge colors and icons per status

---

### 📊 [04 - Capacity & Workload Calculations](./04-capacity-calculations.md)
**33 Scenarios** covering:
- Calculate projected tickets (end dates)
- Workload heat map calculation (8 weeks)
- Person capacity over weeks
- Priority-based capacity allocation
- Task sequencing and dependencies
- Project Ready flag impact
- Overdue task capacity impact
- Effort mapping and configuration
- Multi-person task distribution
- Capacity overflow detection

**Key Scenarios:**
- Calculate task end date from size + start date
- Custom end date override
- Heat map baseline from earliest task (Monday-aligned)
- Weekend adjustment (Sat/Sun → Monday)
- Capacity overflow warnings
- P1 tasks allocated before P3 tasks
- Project completion based on project-ready people only
- Zero availability week handling

---

### 🔍 [05 - Filtering System](./05-filtering-system.md)
**30 Scenarios** covering:
- Person filtering (single/multiple)
- Status filtering (single/multiple)
- Combined filters (person + status)
- Filter button state management
- Filter persistence during updates
- Filter status display
- Filter performance
- Filter UI/UX
- Filter accessibility

**Key Scenarios:**
- Filter by single person shows only their tasks
- Multiple person filter uses OR logic
- Combined person + status filter uses AND logic
- Clear all filters button
- Filter buttons highlight when active
- Task with multiple assignees appears in any assignee filter
- No results message when filter matches nothing

---

### 💾 [06 - Data Persistence & Configuration](./06-data-persistence.md)
**34 Scenarios** covering:
- Save to localStorage (auto-save)
- Load from localStorage (with migration)
- Export data as JSON
- Export configuration as JSON
- Import configuration from JSON
- Import tasks from CSV
- Clear all data
- Dirty state tracking
- Configuration settings
- Data versioning
- Data backup & recovery

**Key Scenarios:**
- Auto-save on every task/person change
- Load with data migration for new fields
- Export includes all tasks + config with timestamped filename
- Import CSV with duplicate detection
- Dirty state visual indicator (teal highlight)
- Warn on page unload with unsaved changes
- Configuration update recalculates all dependent values

---

### 🔒 [07 - Fixed-Length Tasks](./07-fixed-length-tasks.md)
**54 Scenarios** covering:
- Fixed-Length vs Flexible task types
- Task creation with type selection
- End date calculations for both types
- Capacity calculations for mixed scenarios
- Visual indicators (🔒 Fixed, ⚡ Flexible)
- Details modal with task type information
- CSV import/export with Task Type column
- Configuration import/export
- Backwards compatibility

**Key Scenarios:**
- Fixed-Length: Duration constant regardless of assignees
- Flexible: Duration splits among assignees
- Default behavior: Fixed-Length (checkbox unchecked)
- Mixed scenario: Same person with both types = additive capacity
- Capacity per person in Fixed: Total effort / (duration × assignees)
- Heat map handles >100% overallocation
- Import defaults to Fixed if Task Type column missing
- Visual indicators show task type at a glance

---

## Additional Feature Areas (To Be Documented)

### 📅 08 - Date Management & History (Planned)
- Start date history tracking
- End date history tracking
- Size change history
- Weekend adjustments
- Common vs individual start dates
- Date validation and formatting

### 🎯 09 - P1 Conflict Detection (Planned)
- Detect multiple P1 tasks for same person
- Overlapping date range calculation
- Warning modal with conflict details
- User confirmation flow
- Conflict resolution strategies

### 📈 09 - Delay Analysis & Reporting (Planned)
- Calculate task delays (completed vs planned)
- Overdue task detection
- Delay analysis report generation
- Bulk overdue task resolution
- Individual overdue task actions

### 📊 10 - Gantt Chart / Timeline (Planned)
- Gantt chart rendering
- Task bar positioning by dates
- Multi-person task visualization
- Capacity bar display
- Overdue highlighting

### 📤 11 - CSV Export Operations (Planned)
- Export task map CSV
- Export with date ranges
- Export with capacity data
- Column customization
- Date formatting options

### 📐 12 - Task Sizing System (Planned)
- Predefined sizes (S, M, L, XL, XXL)
- Custom size creation
- Size removal (custom only)
- Size-to-days mapping
- Size-to-effort mapping
- Size change impact on timelines

---

## Coverage Statistics

| Document | Scenarios | Status | Test Coverage |
|----------|-----------|--------|---------------|
| Task Management | 30 | ✅ Complete | ~10% (3 tests) |
| Person Management | 33 | ✅ Complete | ~0% (0 tests) |
| Status Management | 33 | ✅ Complete | ~6% (2 tests) |
| Capacity Calculations | 33 | ✅ Complete | ~6% (2 tests) |
| Filtering System | 30 | ✅ Complete | ~7% (2 tests) |
| Data Persistence | 34 | ✅ Complete | ~3% (1 test) |
| Fixed-Length Tasks | 54 | ✅ Complete | 100% (54 tests) |
| **TOTAL DOCUMENTED** | **247** | **7 Docs** | **~26% (64/247)** |
| Date Management | TBD | 🔄 Planned | ~3% (1 test) |
| P1 Conflict Detection | TBD | 🔄 Planned | ~0% (0 tests) |
| Delay Analysis | TBD | 🔄 Planned | ~3% (1 test) |
| Gantt/Timeline | TBD | 🔄 Planned | ~0% (0 tests) |
| CSV Export Extended | TBD | 🔄 Planned | ~3% (1 test) |
| Task Sizing | TBD | 🔄 Planned | ~0% (0 tests) |

---

## How to Use These Documents

### For Developers
1. **Before implementing**: Read relevant acceptance criteria
2. **During development**: Use scenarios as checklist
3. **For testing**: Convert scenarios to test cases
4. **For debugging**: Verify behavior matches specified criteria

### For Testers
1. **Manual testing**: Use scenarios as test scripts
2. **Test automation**: Convert to automated test cases
3. **Regression testing**: Verify all scenarios after changes
4. **Bug reporting**: Reference scenario numbers

### For Product Owners
1. **Requirements validation**: Ensure all requirements are captured
2. **Priority setting**: Identify must-have vs nice-to-have scenarios
3. **Feature documentation**: Use as feature specifications
4. **User acceptance**: Use as acceptance test criteria

---

## Scenario Numbering Convention

Each scenario has a unique number within its document:
- **01-task-management.md**: Scenarios 1-30
- **02-person-management.md**: Scenarios 1-33
- **03-status-management.md**: Scenarios 1-33
- **04-capacity-calculations.md**: Scenarios 1-33
- **05-filtering-system.md**: Scenarios 1-30
- **06-data-persistence.md**: Scenarios 1-34

**Example Reference:** "06-12" means Document 6 (Data Persistence), Scenario 12 (Export all data)

---

## Test Implementation Priority

### 🔴 Critical (Sprint 1)
- All Task Management scenarios (30)
- All Person Management scenarios (33)
- P1 Conflict Detection (when documented)
- **Total: ~70 scenarios**

### 🟡 High (Sprint 2)
- All Status Management scenarios (33)
- All Capacity Calculations scenarios (33)
- Date Management (when documented)
- **Total: ~80 scenarios**

### 🟢 Medium (Sprint 3)
- All Filtering System scenarios (30)
- All Data Persistence scenarios (34)
- Delay Analysis (when documented)
- CSV Export Extended (when documented)
- **Total: ~80 scenarios**

### 🔵 Low (Sprint 4)
- Gantt/Timeline (when documented)
- Task Sizing (when documented)
- Edge cases and error handling
- **Total: ~40 scenarios**

---

## Related Documents
- [Test Coverage Analysis](../TEST_COVERAGE_ANALYSIS.md) - Gap analysis and testing strategy
- [Test Framework](../../tests/test-framework.js) - Base testing infrastructure
- [Current Tests](../../tests/html/html-task-tracker-tests.js) - Implemented tests

---

**Document Version:** 1.0  
**Total Scenarios Documented:** 193  
**Last Updated:** October 14, 2025  
**Next Review:** After each sprint completion
