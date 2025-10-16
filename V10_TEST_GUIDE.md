# HTML Task Tracker V10 - Quick Test Guide

## 🎯 Test Sequence (Do this NOW before using)

### Test 1: Basic Functionality ✅
1. Open `html_console_v10.html` in browser
2. Check console for errors (F12)
3. Verify UI loads correctly
4. Check that Stakeholder and Initiative dropdowns appear in Add Task form

### Test 2: Add New Task with V10 Features ✅
1. Fill in task description: "Test V10 Task"
2. Select stakeholder from dropdown (should default to "General")
3. Select initiative from dropdown (should default to "General")
4. Assign to a person
5. Click "Add Task"
6. **Expected**: Duplicate detection should NOT trigger (no similar tasks yet)
7. **Expected**: Task appears in table with stakeholder and initiative columns
8. Verify task has ID = 1 (display ID)
9. Open browser console and check for UUID (should be generated)

### Test 3: Duplicate Detection ✅
1. Try to add another task with exact same title: "Test V10 Task"
2. **Expected**: Popup shows "Found 1 similar task(s)" with 100% match
3. Click "OK" to change title
4. **Expected**: Form stays open, input is selected
5. Change title to "Test V10 Task Modified"
6. Click "Add Task"
7. **Expected**: Task is added successfully

### Test 4: Fuzzy Duplicate Detection ✅
1. Try to add task: "TestV10Task" (no spaces)
2. **Expected**: Should detect similarity to "Test V10 Task" (fuzzy match)
3. Test variations:
   - "Test V 10 Task" (extra spaces)
   - "test v10 task" (different case)
   All should be detected as duplicates

### Test 5: Stakeholder & Initiative Changes ✅
1. In the task table, change stakeholder dropdown for task #1
2. **Expected**: Background flashes teal, value saves
3. Change initiative dropdown for task #1
4. **Expected**: Background flashes orange, value saves
5. Open browser console - check for initiative start date update log

### Test 6: Heat Map Date Sync (CRITICAL FIX) ✅
1. Scroll down to "Team Workload Heat Map"
2. Click on any colored cell for a person/week
3. **Expected**: Week details popup opens
4. Find a task in the popup
5. Change the start date using the date picker
6. Click outside the date picker
7. **Expected**: 
   - Popup refreshes immediately
   - Task table updates (scroll up to verify)
   - End date recalculates
8. **V10 FIX**: Previously this would NOT sync to the table!

### Test 7: CSV Export (V10 Format) ✅
1. Click "Export Config" button
2. Open the downloaded CSV file
3. Verify new sections exist:
   - `SECTION,STAKEHOLDERS`
   - `SECTION,INITIATIVES` (with columns: Name, Creation Date, Start Date)
4. Verify TICKETS section has new columns:
   - Column 1: UUID (like "a1b2c3d4-...")
   - Column 2: ID (numeric)
   - Columns 7-8: Stakeholder, Initiative
5. Verify all tasks have UUIDs

### Test 8: CSV Import (V10 Format) ✅
1. Export config first (Test 7)
2. Close browser tab
3. Open `html_console_v10.html` again (fresh start)
4. Click "Import Config"
5. Select the CSV you just exported
6. **Expected**: Import confirmation shows:
   - Stakeholders count
   - Initiatives count
7. Click OK
8. **Expected**: 
   - Success message shows "V10"
   - All tasks restored with stakeholders/initiatives
   - Initiative start dates recalculated
9. Verify tasks in table show correct stakeholder/initiative

### Test 9: Backward Compatibility (V9 Import) ✅
1. Create a V9-style CSV (without UUID, Stakeholder, Initiative columns)
2. Or use an old V9 export if you have one
3. Import it
4. **Expected**:
   - Import succeeds
   - UUIDs generated automatically
   - Stakeholder/Initiative default to "General"
   - No errors in console
5. Export again and verify V10 format with new fields

### Test 10: Initiative Auto-Calculation ✅
1. Add multiple tasks with different start dates to same initiative
2. Check browser console for initiative start date logs
3. **Expected**: Initiative start date should be earliest task start date
4. Change a task's start date to earlier date
5. Check that initiative start date updates

### Test 11: LocalStorage Persistence ✅
1. Add several tasks with different stakeholders/initiatives
2. Refresh browser (F5)
3. **Expected**: All data persists including:
   - UUIDs
   - Stakeholders list
   - Initiatives list with dates
   - Task assignments to stakeholders/initiatives

### Test 12: Performance Test ✅
1. Import a large CSV with 50+ tasks
2. Scroll through task table
3. **Expected**: Smooth scrolling (debouncing from V9 still active)
4. Change multiple task fields quickly
5. **Expected**: No freezing or lag

---

## 🐛 Known Issues to Watch For

### FIXED Issues:
✅ Heat map date sync - NOW FIXED (calls immediateRender instead of updateTable)
✅ Missing UUID on import - NOW FIXED (generates automatically)
✅ Duplicate detection false positives - TUNED (70% threshold)

### Potential Issues:
⚠️ CSV parsing with special characters in stakeholder/initiative names
⚠️ Very long lists of stakeholders/initiatives (UI may need scrolling)
⚠️ Duplicate stakeholder/initiative names (not currently validated)

---

## 📝 Quick Verification Checklist

Before declaring V10 complete:

- [ ] Can add tasks with stakeholder/initiative
- [ ] Duplicate detection works for exact, contains, and fuzzy matches
- [ ] Heat map date changes sync to task table
- [ ] Stakeholder/Initiative dropdowns populate and update
- [ ] CSV export includes V10 fields (UUID, Stakeholder, Initiative sections)
- [ ] CSV import handles V10 format
- [ ] CSV import handles V9 format (backward compatibility)
- [ ] Initiative start dates auto-calculate
- [ ] LocalStorage saves/loads V10 data
- [ ] No console errors
- [ ] Performance is acceptable with 50+ tasks

---

## 🎉 Success Criteria

V10 is ready to use when:
1. ✅ All 4 features implemented and working
2. ✅ CSV export/import works for V10 format
3. ✅ V9 backward compatibility confirmed
4. ✅ No critical console errors
5. ✅ Performance acceptable (no freezing/lag)

---

## 🚀 Next Steps After Testing

If all tests pass:
1. Create V10_USER_GUIDE.md explaining new features
2. Update PowerShell scripts (helper2.ps1, etc.)
3. Consider adding UI for managing stakeholders/initiatives
4. Add more duplicate detection options (configurable threshold)
5. Add initiative summary dashboard

If issues found:
1. Document the issue
2. Fix and re-test
3. Update this checklist
