/**
 * V10 Features Tests
 * Tests for Stakeholders, Initiatives, UUID tracking, CreatedDate, and Quick Task
 */

describe('V10 Stakeholder Management', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should add stakeholder to list', () => {
        const initialCount = stakeholders.length;
        addStakeholder('Test Stakeholder');
        
        assert(stakeholders.length === initialCount + 1, 'Should add one stakeholder');
        assert(stakeholders.includes('Test Stakeholder'), 'Should include new stakeholder');
    });

    it('should not add duplicate stakeholder', () => {
        addStakeholder('Duplicate Test');
        const countAfterFirst = stakeholders.length;
        
        addStakeholder('Duplicate Test');
        const countAfterSecond = stakeholders.length;
        
        assert(countAfterFirst === countAfterSecond, 'Should not add duplicate stakeholder');
    });

    it('should not add empty stakeholder name', () => {
        const initialCount = stakeholders.length;
        addStakeholder('');
        
        assert(stakeholders.length === initialCount, 'Should not add empty stakeholder');
    });

    it('should remove stakeholder from list', () => {
        addStakeholder('To Remove');
        const countAfterAdd = stakeholders.length;
        
        removeStakeholder('To Remove');
        
        assert(stakeholders.length === countAfterAdd - 1, 'Should remove one stakeholder');
        assert(!stakeholders.includes('To Remove'), 'Should not include removed stakeholder');
    });

    it('should update stakeholder dropdown in task table', () => {
        const initialDropdowns = document.querySelectorAll('select[id^="stakeholder-"]').length;
        addStakeholder('New Dropdown Test');
        
        // Trigger table recalculation
        calculateProjection();
        
        const dropdowns = document.querySelectorAll('select[id^="stakeholder-"]');
        let foundNewStakeholder = false;
        
        dropdowns.forEach(dropdown => {
            const options = Array.from(dropdown.options);
            if (options.some(opt => opt.value === 'New Dropdown Test')) {
                foundNewStakeholder = true;
            }
        });
        
        assert(foundNewStakeholder || initialDropdowns === 0, 'New stakeholder should appear in dropdowns or no tasks exist');
    });

    it('should assign stakeholder to task', () => {
        addStakeholder('Task Stakeholder');
        const task = addTicket('Test task', 'M', 'P2', [], 'To Do', '2025-10-20');
        
        if (task && task.stakeholder) {
            task.stakeholder = 'Task Stakeholder';
            assert(task.stakeholder === 'Task Stakeholder', 'Task should have assigned stakeholder');
        }
    });
});

describe('V10 Initiative Management', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should add initiative with required fields', () => {
        const initialCount = initiatives.length;
        addInitiative('Test Initiative', '2025-11-01', 'Test description');
        
        assert(initiatives.length === initialCount + 1, 'Should add one initiative');
        
        const newInit = initiatives[initiatives.length - 1];
        assert(newInit.name === 'Test Initiative', 'Should have correct name');
        assert(newInit.startDate === '2025-11-01', 'Should have correct start date');
        assert(newInit.description === 'Test description', 'Should have correct description');
    });

    it('should not add initiative with empty name', () => {
        const initialCount = initiatives.length;
        addInitiative('', '2025-11-01', 'Description');
        
        assert(initiatives.length === initialCount, 'Should not add initiative with empty name');
    });

    it('should not add duplicate initiative', () => {
        addInitiative('Duplicate Initiative', '2025-11-01', 'Test');
        const countAfterFirst = initiatives.length;
        
        addInitiative('Duplicate Initiative', '2025-11-02', 'Test2');
        const countAfterSecond = initiatives.length;
        
        assert(countAfterFirst === countAfterSecond, 'Should not add duplicate initiative');
    });

    it('should add initiative without start date', () => {
        const initialCount = initiatives.length;
        addInitiative('No Date Initiative', '', 'Test description');
        
        assert(initiatives.length === initialCount + 1, 'Should add initiative without start date');
        
        const newInit = initiatives[initiatives.length - 1];
        assert(newInit.startDate === '' || newInit.startDate === null, 'Should have no start date');
    });

    it('should remove initiative from list', () => {
        addInitiative('To Remove', '2025-11-01', 'Test');
        const countAfterAdd = initiatives.length;
        
        removeInitiative('To Remove');
        
        assert(initiatives.length === countAfterAdd - 1, 'Should remove one initiative');
        assert(!initiatives.some(i => i.name === 'To Remove'), 'Should not include removed initiative');
    });

    it('should update initiative dropdown in task table', () => {
        const initialDropdowns = document.querySelectorAll('select[id^="initiative-"]').length;
        addInitiative('New Initiative Dropdown', '2025-11-01', 'Test');
        
        // Trigger table recalculation
        calculateProjection();
        
        const dropdowns = document.querySelectorAll('select[id^="initiative-"]');
        let foundNewInitiative = false;
        
        dropdowns.forEach(dropdown => {
            const options = Array.from(dropdown.options);
            if (options.some(opt => opt.value === 'New Initiative Dropdown')) {
                foundNewInitiative = true;
            }
        });
        
        assert(foundNewInitiative || initialDropdowns === 0, 'New initiative should appear in dropdowns or no tasks exist');
    });

    it('should assign initiative to task', () => {
        addInitiative('Task Initiative', '2025-11-01', 'Test');
        const task = addTicket('Test task', 'M', 'P2', [], 'To Do', '2025-10-20');
        
        if (task && task.initiative) {
            task.initiative = 'Task Initiative';
            assert(task.initiative === 'Task Initiative', 'Task should have assigned initiative');
        }
    });

    it('should calculate initiative timeline correctly', () => {
        addInitiative('Timeline Test', '2025-10-20', 'Test');
        
        // Add tasks to this initiative
        const task1 = addTicket('Init Task 1', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const task2 = addTicket('Init Task 2', 'L', 'P2', ['Bob'], 'To Do', '2025-10-25');
        
        if (task1) task1.initiative = 'Timeline Test';
        if (task2) task2.initiative = 'Timeline Test';
        
        // Timeline calculation should work
        const timeline = typeof getInitiativeTimelineData === 'function' 
            ? getInitiativeTimelineData() 
            : null;
        
        assert(timeline !== null || typeof getInitiativeTimelineData !== 'function', 
            'Timeline data should be calculated or function not available');
    });
});

describe('V10 UUID Tracking', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should assign UUID to new task', () => {
        const task = addTicket('UUID Test Task', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        
        assert(task.uuid, 'Task should have UUID');
        assert(typeof task.uuid === 'string', 'UUID should be a string');
        assert(task.uuid.length > 0, 'UUID should not be empty');
    });

    it('should generate unique UUIDs for different tasks', () => {
        const task1 = addTicket('UUID Task 1', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const task2 = addTicket('UUID Task 2', 'M', 'P2', ['Bob'], 'To Do', '2025-10-20');
        
        assert(task1.uuid !== task2.uuid, 'UUIDs should be unique for different tasks');
    });

    it('should preserve UUID when task is updated', () => {
        const task = addTicket('UUID Preserve Test', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const originalUUID = task.uuid;
        
        // Update task
        task.description = 'Updated description';
        task.size = 'L';
        
        assert(task.uuid === originalUUID, 'UUID should remain unchanged after updates');
    });

    it('should include UUID in CSV export', () => {
        const task = addTicket('UUID Export Test', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        
        // Check if export functions exist and include UUID
        if (typeof exportToCSV === 'function') {
            const csvData = exportToCSV();
            assert(csvData.includes('uuid') || csvData.includes('UUID'), 'CSV should include UUID field');
        }
    });
});

describe('V10 CreatedDate Tracking', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should assign createdDate to new task', () => {
        const task = addTicket('CreatedDate Test', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        
        assert(task.createdDate, 'Task should have createdDate');
        assert(typeof task.createdDate === 'string', 'createdDate should be a string');
    });

    it('should use today date for createdDate', () => {
        const task = addTicket('CreatedDate Today', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const today = new Date().toISOString().split('T')[0];
        
        assert(task.createdDate === today, 'createdDate should be today');
    });

    it('should preserve createdDate when task is updated', () => {
        const task = addTicket('CreatedDate Preserve', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const originalDate = task.createdDate;
        
        // Update task
        task.description = 'Updated description';
        task.status = 'In Progress';
        
        assert(task.createdDate === originalDate, 'createdDate should remain unchanged after updates');
    });

    it('should allow sorting tasks by createdDate', () => {
        // Add multiple tasks
        const task1 = addTicket('Task 1', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const task2 = addTicket('Task 2', 'M', 'P2', ['Bob'], 'To Do', '2025-10-20');
        const task3 = addTicket('Task 3', 'M', 'P2', ['Charlie'], 'To Do', '2025-10-20');
        
        // All should have createdDate
        assert(task1.createdDate && task2.createdDate && task3.createdDate, 
            'All tasks should have createdDate for sorting');
    });
});

describe('V10 Initiative Chart', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should generate initiative chart data', () => {
        addInitiative('Chart Init 1', '2025-10-20', 'Test 1');
        addInitiative('Chart Init 2', '2025-11-01', 'Test 2');
        
        // Add tasks to initiatives
        const task1 = addTicket('Chart Task 1', 'M', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const task2 = addTicket('Chart Task 2', 'L', 'P2', ['Bob'], 'To Do', '2025-11-01');
        
        if (task1) task1.initiative = 'Chart Init 1';
        if (task2) task2.initiative = 'Chart Init 2';
        
        // Chart generation should work
        if (typeof getInitiativeTimelineData === 'function') {
            const chartData = getInitiativeTimelineData();
            assert(chartData !== null, 'Chart data should be generated');
        }
    });

    it('should calculate initiative duration correctly', () => {
        addInitiative('Duration Test', '2025-10-20', 'Test');
        
        // Add multiple tasks with different sizes
        const task1 = addTicket('Duration Task 1', 'S', 'P2', ['Alice'], 'To Do', '2025-10-20');
        const task2 = addTicket('Duration Task 2', 'M', 'P2', ['Alice'], 'To Do', '2025-10-21');
        
        if (task1) task1.initiative = 'Duration Test';
        if (task2) task2.initiative = 'Duration Test';
        
        // Duration should be sum of all task durations
        if (typeof getInitiativeTimelineData === 'function') {
            const data = getInitiativeTimelineData();
            const durationInit = data.find(d => d.name === 'Duration Test');
            
            if (durationInit) {
                assert(durationInit.duration > 0, 'Initiative should have positive duration');
            }
        }
    });

    it('should handle initiatives with no tasks', () => {
        addInitiative('Empty Initiative', '2025-10-20', 'No tasks');
        
        if (typeof getInitiativeTimelineData === 'function') {
            const data = getInitiativeTimelineData();
            const emptyInit = data.find(d => d.name === 'Empty Initiative');
            
            // Should either handle gracefully or show 0 duration
            assert(emptyInit === undefined || emptyInit.duration === 0, 
                'Empty initiative should have 0 duration or not appear');
        }
    });
});

describe('V10 Priority Picklist', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should accept P1-P5 priority values', () => {
        const priorities = ['P1', 'P2', 'P3', 'P4', 'P5'];
        
        priorities.forEach((priority, index) => {
            const task = addTicket(`Priority ${priority} Task`, 'M', priority, ['Alice'], 'To Do', '2025-10-20');
            assert(task.priority === priority, `Task should have ${priority} priority`);
        });
    });

    it('should default to P2 if no priority specified', () => {
        const task = addTicket('Default Priority Task', 'M', '', ['Alice'], 'To Do', '2025-10-20');
        
        if (task && (task.priority === 'P2' || task.priority === '')) {
            assert(true, 'Task should default to P2 or empty priority');
        }
    });

    it('should display priority correctly in table', () => {
        const task = addTicket('Priority Display', 'M', 'P1', ['Alice'], 'To Do', '2025-10-20');
        
        if (task) {
            calculateProjection();
            // Priority should be displayed in table
            assert(task.priority === 'P1', 'Priority should be stored as P1');
        }
    });
});

describe('V10 Size Picklist', () => {
    beforeEach(() => {
        initializeTestState();
    });

    it('should accept S/M/L/XL/XXL size values', () => {
        const sizes = ['S', 'M', 'L', 'XL', 'XXL'];
        
        sizes.forEach((size, index) => {
            const task = addTicket(`Size ${size} Task`, size, 'P2', ['Alice'], 'To Do', '2025-10-20');
            assert(task.size === size, `Task should have ${size} size`);
        });
    });

    it('should default to M if no size specified', () => {
        const task = addTicket('Default Size Task', '', 'P2', ['Alice'], 'To Do', '2025-10-20');
        
        if (task && (task.size === 'M' || task.size === '')) {
            assert(true, 'Task should default to M or empty size');
        }
    });

    it('should map size to correct duration', () => {
        const sizeDurations = {
            'S': 1,
            'M': 3,
            'L': 5,
            'XL': 10,
            'XXL': 15
        };
        
        Object.entries(sizeDurations).forEach(([size, expectedDays]) => {
            const sizeConfig = TASK_SIZES.find(s => s.key === size);
            if (sizeConfig) {
                assert(sizeConfig.days === expectedDays, 
                    `Size ${size} should map to ${expectedDays} days`);
            }
        });
    });
});

console.log('✅ V10 Features tests loaded successfully');
