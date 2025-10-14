# Acceptance Criteria: Data Persistence & Configuration

## Feature: Save to LocalStorage

### Scenario 1: Save tasks and people to localStorage
**Given** tasks and people data exist in memory  
**When** saveToLocalStorage() is called  
**Then** data should be saved to localStorage with key:
- "projectSchedulerDataV2"

**And** saved data should include:
- tickets array (all tasks)
- people array (all resources)
- currentTicketId (counter)
- useCommonStartDate (boolean)
- taskSizeDefinitions (object)
- ticketDays (object)
- effortMap (object)
- estimationBaseHours (number)
- projectHoursPerDay (number)

**And** data should be stringified as JSON

---

### Scenario 2: Auto-save on task add
**Given** the user adds a new task  
**When** the task is added to tickets array  
**Then** saveToLocalStorage() should be called automatically  
**And** the dirty state should be set  
**And** data should persist in localStorage

---

### Scenario 3: Auto-save on task update
**Given** the user updates task size, priority, or assignment  
**When** the task is modified  
**Then** saveToLocalStorage() should be called automatically  
**And** changes should be persisted immediately

---

### Scenario 4: Auto-save on person add/update
**Given** the user adds or updates a person  
**When** the person data changes  
**Then** saveToLocalStorage() should be called automatically  
**And** people array should be persisted

---

### Scenario 5: Save status after marking as clean
**Given** dirty state is active  
**When** saveToLocalStorage() completes successfully  
**Then** markClean() should be called  
**And** dirty state indicator should be removed  
**And** UI should show "saved" state

---

## Feature: Load from LocalStorage

### Scenario 6: Load existing data on startup
**Given** data exists in localStorage under "projectSchedulerDataV2"  
**When** loadFromLocalStorage() is called on page load  
**Then** data should be parsed and loaded into:
- tickets array
- people array
- currentTicketId
- useCommonStartDate
- taskSizeDefinitions
- ticketDays
- effortMap
- configuration settings

**And** function should return true

---

### Scenario 7: Handle missing data on first load
**Given** no data exists in localStorage (first time user)  
**When** loadFromLocalStorage() is called  
**Then** function should return false  
**And** initializeDefaultData() should be called  
**And** default data should be loaded

---

### Scenario 8: Handle corrupted data gracefully
**Given** corrupted/invalid JSON exists in localStorage  
**When** loadFromLocalStorage() is called  
**Then** JSON.parse() should fail  
**And** error should be caught  
**And** function should return false  
**And** initializeDefaultData() should be called as fallback

---

### Scenario 9: Data migration on load (add missing fields)
**Given** old data format exists without "priority" field  
**When** loadFromLocalStorage() is called  
**Then** migration should detect missing fields  
**And** add default values:
- priority: "P3"
- status: "To Do"

**And** save migrated data back to localStorage

---

### Scenario 10: Migrate people to 8-week availability
**Given** legacy data has people with 5-week availability  
**When** migratePeopleToEightWeeks() is called  
**Then** each person's availability should be extended to 8 weeks  
**And** new weeks should default to 25 hours  
**And** migrated data should be saved

---

## Feature: Export Data

### Scenario 11: Export configuration as JSON
**Given** the user clicks "Export Configuration"  
**When** exportConfiguration() is called  
**Then** a JSON file should be downloaded containing:
- taskSizeDefinitions
- ticketDays
- estimationBaseHours
- projectHoursPerDay
- people array
- useCommonStartDate

**And** filename should be: "task_scheduler_config_[date].json"

---

### Scenario 12: Export all data (tasks + config)
**Given** the user clicks "Export Data"  
**When** exportData() is called  
**Then** a JSON file should be downloaded containing:
- tickets (all tasks)
- people (all resources)
- configuration settings
- metadata (export date, version)

**And** filename should be: "task_scheduler_data_[date].json"

---

### Scenario 13: Export data with custom date in filename
**Given** today is "2025-10-14"  
**When** export is triggered  
**Then** filename should include: "task_scheduler_data_2025-10-14.json"

---

## Feature: Import Configuration

### Scenario 14: Import configuration from JSON file
**Given** a valid configuration JSON file is selected  
**When** the user imports the file via file input  
**Then** the system should:
- Parse the JSON
- Validate the structure
- Load taskSizeDefinitions
- Load people array
- Load other configuration settings
- Call renderPeople()
- Call calculateProjection()
- Save to localStorage

**And** show success message

---

### Scenario 15: Import configuration with validation
**Given** an invalid configuration file is selected  
**When** import is attempted  
**Then** validation should check for:
- Valid JSON format
- Required fields present
- Data types correct

**And** if invalid, show error message:
- "Invalid configuration file format"

---

### Scenario 16: Import configuration overwrites existing
**Given** current configuration exists  
**When** user imports new configuration  
**Then** a confirmation prompt should ask:
- "This will overwrite your current settings. Continue?"

**When** user confirms  
**Then** current configuration should be replaced  
**When** user cancels  
**Then** import should be aborted

---

## Feature: Import Tasks

### Scenario 17: Import tasks from CSV file
**Given** a valid CSV file with tasks is selected  
**When** handleTaskImport() is called  
**Then** the system should:
- Parse CSV rows
- Create task objects from each row
- Check for duplicates
- Add non-duplicate tasks to tickets array
- Update UI
- Save to localStorage

**And** show import summary:
- "Added: X tasks"
- "Skipped: Y duplicates"

---

### Scenario 18: Import CSV with header row
**Given** CSV file starts with header:
```
Description,StartDate,Size,Priority,Assigned
```

**When** CSV is parsed  
**Then** first row should be treated as headers  
**And** subsequent rows should be data  
**And** column mapping should use header names

---

### Scenario 19: Import CSV with multiple assignees
**Given** CSV row has Assigned column: "Alice|Bob|Charlie"  
**When** task is imported  
**Then** assigned array should be: ["Alice", "Bob", "Charlie"]  
**And** split by "|" delimiter

---

### Scenario 20: Import CSV skip duplicates
**Given** task "Fix login bug" already exists  
**And** CSV contains a row for "Fix login bug"  
**When** import runs  
**Then** duplicate should be detected  
**And** task should be skipped  
**And** skip counter should increment  
**And** log warning message

---

### Scenario 21: Import CSV with date format validation
**Given** CSV has StartDate: "2025-10-14"  
**When** imported  
**Then** date should be validated as YYYY-MM-DD format  
**And** invalid dates should be corrected to next Monday

---

## Feature: Clear All Data

### Scenario 22: Clear all data from localStorage
**Given** data exists in localStorage  
**When** user clicks "Clear All Data" (with confirmation)  
**Then** confirm dialog should appear:
- "Are you sure? This will delete all tasks and settings."

**When** user confirms  
**Then** localStorage.removeItem("projectSchedulerDataV2") should be called  
**And** page should reload or initialize default data

---

### Scenario 23: Clear data cancellation
**Given** user clicks "Clear All Data"  
**When** user cancels the confirmation dialog  
**Then** no data should be deleted  
**And** application should remain unchanged

---

## Feature: Dirty State Tracking

### Scenario 24: Mark dirty on task changes
**Given** application is in clean state  
**When** user adds, updates, or deletes a task  
**Then** markDirty() should be called  
**And** isDirty flag should be set to true  
**And** visual indicator should appear (teal highlight on cards)

---

### Scenario 25: Mark clean after save
**Given** application is in dirty state  
**When** saveToLocalStorage() completes  
**Then** markClean() should be called  
**And** isDirty flag should be set to false  
**And** visual indicators should be removed

---

### Scenario 26: Dirty state visual indicator
**Given** isDirty is true  
**When** UI is rendered  
**Then** cards should have:
- Light teal background (#f0fdfa)
- Teal border (#5eead4)
- Subtle shadow with teal tint

**And** visual cue should indicate "unsaved changes"

---

### Scenario 27: Warn on page unload with unsaved changes
**Given** isDirty is true (unsaved changes exist)  
**When** user tries to close tab or navigate away  
**Then** browser should show warning:
- "You have unsaved changes. Are you sure you want to leave?"

**When** user confirms  
**Then** page should unload (changes lost)  
**When** user cancels  
**Then** page should remain open

---

## Feature: Configuration Settings

### Scenario 28: Update estimation base hours
**Given** estimationBaseHours is 5  
**When** user changes it to 6  
**Then** all task effort calculations should use 6 hours/day  
**And** end dates should be recalculated  
**And** setting should be saved to localStorage

---

### Scenario 29: Update project hours per day
**Given** projectHoursPerDay is 5  
**When** user changes it to 6  
**Then** timeline calculations should use 6 hours/day  
**And** project completion dates should be recalculated

---

### Scenario 30: Toggle common start date mode
**Given** useCommonStartDate is false  
**When** user toggles it to true  
**Then** common start date field should appear  
**And** individual start date fields should be hidden  
**And** all tasks should use the common date  
**And** setting should be saved

---

## Feature: Data Versioning

### Scenario 31: Detect data version mismatch
**Given** data version in localStorage is "v1"  
**And** current application expects "v2"  
**When** data is loaded  
**Then** version migration should run  
**And** data should be upgraded to v2 format  
**And** saved with new version tag

---

### Scenario 32: Backward compatibility
**Given** newer data version exists in localStorage  
**When** older application version loads it  
**Then** application should detect version mismatch  
**And** show warning: "Data format not compatible"  
**Or** attempt to load compatible fields only

---

## Feature: Data Backup & Recovery

### Scenario 33: Auto-backup before major operations
**Given** user is about to import CSV with 50+ tasks  
**When** import begins  
**Then** current data should be backed up to:
- "projectSchedulerDataV2_backup_[timestamp]"

**And** allow recovery if import fails

---

### Scenario 34: Recover from backup
**Given** a backup exists in localStorage  
**When** user clicks "Restore from Backup"  
**Then** backup data should be loaded  
**And** current data should be replaced  
**And** UI should refresh

---

**Document Version:** 1.0  
**Feature Area:** Data Persistence & Configuration  
**Last Updated:** October 14, 2025
