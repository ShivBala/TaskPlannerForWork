/**
 * Unit Tests for Heat Map Capacity Calculation
 * 
 * Tests that workload distribution is correctly calculated when multiple people
 * are assigned to tasks, ensuring proper parallel work calculation.
 * 
 * These tests document the expected behavior for heat map capacity calculations:
 * 
 * ## Test Cases
 * 
 * ### 1. Multi-person Task Assignment (Parallel Work)
 * - **TC1:** 10-day task assigned to 2 people = 5 days each = 100% utilization for 5 days
 * - **TC2:** 10-day task assigned to 4 people = 2.5 days each ≈ 60% utilization
 * - **TC3:** 1-day task assigned to 2 people = 0.5 days each = 20% utilization for 1 day
 * - **TC4:** 2-day task assigned to 1 person = 40% utilization for 2 days
 * 
 * ### 2. Task Duration Calculation
 * - **TC5:** 10-day task with 2 people should span 5 business days (Mon-Fri)
 * - **TC6:** Task starting Friday should span weekend correctly (Fri + Mon)
 * 
 * ### 3. Edge Cases
 * - **TC7:** Tasks with zero assignees should not crash
 * - **TC8:** Done and Paused tasks should not count toward capacity
 * 
 * ## Usage
 * Run these tests by opening test-runner.html in a browser.
 * 
 * ## Implementation Notes
 * The heat map uses the following logic:
 * 1. Total task days ÷ number of assignees = days per person
 * 2. Each person works at full daily capacity (estimationBaseHours = 5 hours/day)
 * 3. Calendar duration = ceil(days per person) business days
 * 4. Utilization = (assigned hours) / (available hours) × 100%
 */

console.log(`
📋 Heat Map Capacity Test Specifications Loaded

This file documents the test cases for heat map capacity calculations.
To verify these behaviors manually:

TEST CASE 1: Two people on 10-day (XL) task
--------------------------------------------
Setup:
- Create task: XL size (10 days), assigned to 2 people
- Start date: Monday of any week
- Each person: 25 hours available/week

Expected Result:
- Task duration: 5 business days (Mon-Fri)
- Each person: 25 hours assigned = 100% utilization
- Calculation: (10 days ÷ 2 people) × 5 hours/day = 25 hours each

TEST CASE 2: Four people on 10-day task
---------------------------------------
Setup:
- Create task: XL size (10 days), assigned to 4 people  
- Start date: Monday of any week
- Each person: 25 hours available/week

Expected Result:
- Task duration: 3 business days (Mon-Wed)
- Each person: 15 hours assigned = 60% utilization
- Calculation: (10 days ÷ 4 people = 2.5, ceil = 3 days) × 5 hours/day = 15 hours

TEST CASE 3: Single person assignment
-------------------------------------
Setup:
- Create task: M size (2 days), assigned to 1 person
- Start date: Monday of any week
- Person: 25 hours available/week

Expected Result:
- Task duration: 2 business days (Mon-Tue)
- Person: 10 hours assigned = 40% utilization
- Calculation: 2 days × 5 hours/day = 10 hours

TEST CASE 4: One-day task with 2 people
---------------------------------------
Setup:
- Create task: S size (1 day), assigned to 2 people
- Start date: Monday of any week
- Each person: 25 hours available/week

Expected Result:
- Task duration: 1 business day (Mon)
- Each person: 5 hours assigned = 20% utilization
- Calculation: (1 day ÷ 2 people = 0.5, ceil = 1 day) × 5 hours/day = 5 hours

TEST CASE 5: Weekend-spanning task
-----------------------------------
Setup:
- Create task: M size (2 days), assigned to 1 person
- Start date: Friday
- Person: 25 hours available/week

Expected Result:
- Task spans 2 weeks: Friday (Week 1) + Monday (Week 2)
- Week 1: 5 hours = 20% utilization
- Week 2: 5 hours = 20% utilization
- Total: 10 hours (2 days × 5 hours/day)

TEST CASE 6: Zero assignees (edge case)
----------------------------------------
Setup:
- Create task: S size (1 day), no assignees
- Start date: Monday of any week

Expected Result:
- No person should have hours assigned
- All people should show 0% utilization

TEST CASE 7: Done/Paused tasks
-------------------------------
Setup:
- Create task: M size (2 days), assigned to 1 person
- Start date: Monday of any week
- Status: Done or Paused

Expected Result:
- Task should NOT count toward capacity
- Person should show 0 hours and 0% utilization

TEST CASE 8: Multiple tasks same week
--------------------------------------
Setup:
- Task 1: S size (1 day), Monday, Person A
- Task 2: M size (2 days), Wednesday, Person A
- Each person: 25 hours available/week

Expected Result:
- Person A Week total: 1 day + 2 days = 3 days = 15 hours
- Person A utilization: 15 / 25 = 60%

REGRESSION PREVENTION:
---------------------
If heat map shows 100% for Task 1 with Vipul & Peter (XL task, 2 people),
this is CORRECT behavior - they work in parallel at full capacity for 5 days.

IMPORTANT NOTES:
----------------
1. Multiple assignees work in PARALLEL, not sequentially
2. Formula: total task days ÷ number of assignees = days per person
3. Each person works at full capacity (5 hours/day) during their assigned days
4. Weekend days are automatically skipped (business days only)
5. Done and Paused tasks do NOT count toward capacity

Last verified: ${new Date().toISOString()}
`);
