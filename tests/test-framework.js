/**
 * Task Tracker Testing Framework
 * 
 * A comprehensive testing suite for the HTML Task Tracker application
 * and future PowerShell script testing capabilities.
 * 
 * Usage:
 *   - For HTML tests: Open test-runner.html in a browser
 *   - For Node.js tests: Run `node tests/test-framework.js`
 *   - For PowerShell tests: Use PowerShell testing utilities (future)
 */

class TestFramework {
    constructor(options = {}) {
        this.testResults = [];
        this.testCount = 0;
        this.passCount = 0;
        this.failCount = 0;
        this.skipCount = 0;
        this.suiteResults = {};
        this.options = {
            verbose: options.verbose || false,
            stopOnFirstFailure: options.stopOnFirstFailure || false,
            timeout: options.timeout || 5000
        };
        this.beforeEachCallbacks = [];
        this.afterEachCallbacks = [];
        this.beforeAllCallbacks = [];
        this.afterAllCallbacks = [];
    }

    // Test lifecycle hooks
    beforeAll(callback) {
        this.beforeAllCallbacks.push(callback);
    }

    afterAll(callback) {
        this.afterAllCallbacks.push(callback);
    }

    beforeEach(callback) {
        this.beforeEachCallbacks.push(callback);
    }

    afterEach(callback) {
        this.afterEachCallbacks.push(callback);
    }

    // Core assertion methods
    assert(condition, message, details = {}) {
        this.testCount++;
        const result = {
            id: this.testCount,
            passed: !!condition,
            message: message,
            details: details,
            timestamp: new Date().toISOString(),
            stackTrace: condition ? null : new Error().stack
        };
        
        this.testResults.push(result);
        
        if (result.passed) {
            this.passCount++;
            if (this.options.verbose) {
                this.log(`✅ Test ${this.testCount}: ${message}`);
            }
        } else {
            this.failCount++;
            this.log(`❌ Test ${this.testCount}: ${message}`, 'error');
            if (details && Object.keys(details).length > 0) {
                this.log('Details:', details, 'error');
            }
            
            if (this.options.stopOnFirstFailure) {
                throw new Error(`Test failed: ${message}`);
            }
        }
        
        return result.passed;
    }

    assertEqual(actual, expected, message) {
        const passed = actual === expected;
        return this.assert(passed, message || `Expected ${expected}, got ${actual}`, {
            actual,
            expected
        });
    }

    assertNotEqual(actual, expected, message) {
        const passed = actual !== expected;
        return this.assert(passed, message || `Expected ${actual} to not equal ${expected}`, {
            actual,
            expected
        });
    }

    assertDeepEqual(actual, expected, message) {
        const passed = JSON.stringify(actual) === JSON.stringify(expected);
        return this.assert(passed, message || `Objects are not deeply equal`, {
            actual,
            expected
        });
    }

    assertTrue(condition, message) {
        return this.assert(condition === true, message || `Expected true, got ${condition}`);
    }

    assertFalse(condition, message) {
        return this.assert(condition === false, message || `Expected false, got ${condition}`);
    }

    assertThrows(fn, message) {
        try {
            fn();
            return this.assert(false, message || 'Expected function to throw an error');
        } catch (error) {
            return this.assert(true, message || 'Function threw an error as expected', {
                error: error.message
            });
        }
    }

    assertDoesNotThrow(fn, message) {
        try {
            fn();
            return this.assert(true, message || 'Function did not throw an error');
        } catch (error) {
            return this.assert(false, message || 'Expected function not to throw an error', {
                error: error.message
            });
        }
    }

    // Test organization
    describe(suiteName, testFunction) {
        this.log(`\n📋 ${suiteName}`, 'suite');
        const suiteStartTime = Date.now();
        const initialPassCount = this.passCount;
        const initialFailCount = this.failCount;
        const initialTestCount = this.testCount;

        try {
            // Run beforeAll hooks
            this.beforeAllCallbacks.forEach(callback => callback());
            
            // Run the test suite
            testFunction();
            
            // Run afterAll hooks
            this.afterAllCallbacks.forEach(callback => callback());
            
        } catch (error) {
            this.log(`💥 Suite "${suiteName}" failed with error: ${error.message}`, 'error');
            this.failCount++;
        }

        const suiteEndTime = Date.now();
        const suitePassed = this.passCount - initialPassCount;
        const suiteFailed = this.failCount - initialFailCount;
        const suiteTotal = this.testCount - initialTestCount;

        this.suiteResults[suiteName] = {
            passed: suitePassed,
            failed: suiteFailed,
            total: suiteTotal,
            duration: suiteEndTime - suiteStartTime
        };

        this.log(`📊 Suite "${suiteName}": ${suitePassed}✅ ${suiteFailed}❌ (${suiteEndTime - suiteStartTime}ms)`, 'suite');
    }

    it(testName, testFunction) {
        if (this.options.verbose) {
            this.log(`🔍 ${testName}`);
        }

        try {
            // Run beforeEach hooks
            this.beforeEachCallbacks.forEach(callback => callback());
            
            // Run the test
            testFunction();
            
            // Run afterEach hooks
            this.afterEachCallbacks.forEach(callback => callback());
            
        } catch (error) {
            this.assert(false, `Test "${testName}" failed with error: ${error.message}`, {
                error: error.message,
                stack: error.stack
            });
        }
    }

    skip(testName, testFunction) {
        this.skipCount++;
        this.log(`⏭️  Skipped: ${testName}`, 'skip');
    }

    // Utility methods
    log(message, type = 'info', data = null) {
        const timestamp = new Date().toISOString();
        const prefix = `[${timestamp}]`;
        
        if (typeof window !== 'undefined') {
            // Browser environment
            switch (type) {
                case 'error':
                    console.error(prefix, message, data || '');
                    break;
                case 'suite':
                    console.log(`%c${prefix} ${message}`, 'color: #3b82f6; font-weight: bold');
                    break;
                case 'skip':
                    console.log(`%c${prefix} ${message}`, 'color: #f59e0b');
                    break;
                default:
                    console.log(prefix, message, data || '');
            }
        } else {
            // Node.js environment
            const colors = {
                error: '\x1b[31m',
                suite: '\x1b[34m',
                skip: '\x1b[33m',
                reset: '\x1b[0m'
            };
            const color = colors[type] || '';
            console.log(`${color}${prefix} ${message}${colors.reset}`, data || '');
        }
    }

    // Test execution
    async runTests() {
        this.log('🧪 Starting Test Suite Execution...\n', 'suite');
        const startTime = Date.now();

        // Reset counters
        this.testResults = [];
        this.testCount = 0;
        this.passCount = 0;
        this.failCount = 0;
        this.skipCount = 0;

        try {
            // Import and run all test modules
            await this.loadTestModules();
        } catch (error) {
            this.log(`Failed to load test modules: ${error.message}`, 'error');
        }

        const endTime = Date.now();
        const totalDuration = endTime - startTime;

        // Generate final report
        return this.generateReport(totalDuration);
    }

    async loadTestModules() {
        // This method will be overridden by specific implementations
        throw new Error('loadTestModules must be implemented by subclass');
    }

    // Report generation
    generateReport(duration = 0) {
        this.log('\n📋 TEST EXECUTION SUMMARY', 'suite');
        this.log('='.repeat(50), 'suite');
        this.log(`Total Tests: ${this.testCount}`);
        this.log(`Passed: ${this.passCount} ✅`);
        this.log(`Failed: ${this.failCount} ❌`);
        this.log(`Skipped: ${this.skipCount} ⏭️`);
        this.log(`Success Rate: ${this.testCount > 0 ? ((this.passCount / this.testCount) * 100).toFixed(1) : 0}%`);
        this.log(`Total Duration: ${duration}ms`);

        // Suite breakdown
        if (Object.keys(this.suiteResults).length > 0) {
            this.log('\n📊 SUITE BREAKDOWN:', 'suite');
            Object.entries(this.suiteResults).forEach(([suiteName, results]) => {
                this.log(`  ${suiteName}: ${results.passed}✅ ${results.failed}❌ (${results.duration}ms)`);
            });
        }

        // Failed tests details
        if (this.failCount > 0) {
            this.log('\n❌ FAILED TESTS:', 'error');
            this.log('='.repeat(30), 'error');
            this.testResults
                .filter(result => !result.passed)
                .forEach(result => {
                    this.log(`Test ${result.id}: ${result.message}`, 'error');
                    if (result.details && Object.keys(result.details).length > 0) {
                        this.log(`Details: ${JSON.stringify(result.details, null, 2)}`, 'error');
                    }
                });
        }

        // Return summary for programmatic access
        return {
            total: this.testCount,
            passed: this.passCount,
            failed: this.failCount,
            skipped: this.skipCount,
            successRate: this.testCount > 0 ? (this.passCount / this.testCount) * 100 : 0,
            duration: duration,
            results: this.testResults,
            suites: this.suiteResults
        };
    }

    // Utility for creating test data
    createMockData(type, overrides = {}) {
        const mockDataTemplates = {
            task: {
                id: 'test-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                title: 'Test Task',
                person: 'Test Person',
                status: 'To Do',
                size: 3,
                startDate: '2025-10-14',
                endDate: '2025-10-16',
                customEndDate: null,
                completedDate: null,
                ...overrides
            },
            person: {
                id: 'person-' + Date.now(),
                name: 'Test Person',
                email: 'test@example.com',
                capacity: 8,
                ...overrides
            }
        };

        return mockDataTemplates[type] ? { ...mockDataTemplates[type], ...overrides } : {};
    }
}

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TestFramework;
} else if (typeof window !== 'undefined') {
    window.TestFramework = TestFramework;
}