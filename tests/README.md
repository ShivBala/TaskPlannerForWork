# Task Tracker Testing Framework

A comprehensive testing suite for the HTML Task Tracker application with support for future PowerShell script testing.

## 🏗️ Architecture

```
tests/
├── test-framework.js           # Core testing framework
├── test-runner.html           # Browser-based test runner
├── node-test-runner.js        # Node.js/CI test runner
├── html/
│   └── html-task-tracker-tests.js  # HTML application tests
├── powershell/
│   └── powershell-test-framework.ps1  # PowerShell testing utilities
└── README.md                  # This file
```

## 🚀 Quick Start

### Browser Testing (Recommended for HTML App)

1. Open `test-runner.html` in your browser
2. Click "▶️ Run All Tests" to execute the full test suite
3. View results in the interactive interface

### Command Line Testing

```bash
# Run all tests
node tests/node-test-runner.js

# Run with verbose output
node tests/node-test-runner.js --verbose

# Export results in specific format
node tests/node-test-runner.js --output-format junit

# Run from different project root
node tests/node-test-runner.js --project-root /path/to/project
```

### PowerShell Testing (Future)

```powershell
# Load the PowerShell test framework
. .\tests\powershell\powershell-test-framework.ps1

# Run PowerShell tests
Invoke-TaskTrackerPowerShellTests
```

## 🧪 Test Suites

### HTML Application Tests

**Filter Functionality**
- ✅ Person filter validation
- ✅ Status filter validation  
- ✅ Date filter validation

**Task Status Transitions**
- ✅ To Do → In Progress → Done workflow
- ✅ Completion date tracking
- ✅ Status rollback handling

**Heat Map Calculations**
- ✅ Workload distribution accuracy
- ✅ Exclusion of Done/Paused tasks
- ✅ Multi-person capacity planning

**Custom End Date Handling**
- ✅ Override functionality
- ✅ Effective date calculation
- ✅ Bulk resolution integration

**Delay Analysis**
- ✅ Start date delay detection
- ✅ End date delay analysis
- ✅ Comprehensive risk assessment

**Data Persistence**
- ✅ localStorage save/load
- ✅ Data integrity validation
- ✅ Backward compatibility

**CSV Operations**
- ✅ Export data format
- ✅ Import validation
- ✅ Custom field preservation

### Project Structure Tests

**File Validation**
- ✅ Required files existence
- ✅ Directory structure
- ✅ Syntax validation

**Code Quality**
- ✅ JavaScript syntax checking
- ✅ Module loading validation
- ✅ Dependency verification

## 🔧 Framework Features

### Core Testing Capabilities

```javascript
// Assertion methods
testFramework.assert(condition, message, details)
testFramework.assertEqual(actual, expected, message)
testFramework.assertNotEqual(actual, expected, message)
testFramework.assertDeepEqual(actual, expected, message)
testFramework.assertTrue(condition, message)
testFramework.assertFalse(condition, message)
testFramework.assertThrows(fn, message)
testFramework.assertDoesNotThrow(fn, message)

// Test organization
testFramework.describe('Suite Name', () => {
    testFramework.it('should do something', () => {
        // Test implementation
    });
});

// Lifecycle hooks
testFramework.beforeAll(callback)
testFramework.afterAll(callback)
testFramework.beforeEach(callback)
testFramework.afterEach(callback)
```

### Data Management

```javascript
// Create test data
const testTask = testFramework.createMockData('task', {
    title: 'Custom Test Task',
    status: 'In Progress'
});

// Backup and restore application state
const backup = htmlTests.backupApplicationState();
// ... run tests ...
htmlTests.restoreApplicationState(backup);
```

### Reporting Features

- **Console Output**: Real-time test execution feedback
- **HTML Reports**: Interactive browser-based results
- **JSON Export**: Machine-readable test data
- **JUnit XML**: CI/CD integration support
- **Success Rate Tracking**: Performance metrics

## 🌐 Browser Test Runner

The HTML test runner (`test-runner.html`) provides:

- **Interactive Interface**: Visual test execution and results
- **Real-time Console**: Live test output capture
- **Suite Breakdown**: Detailed test organization
- **Expandable Results**: Drill-down into test details
- **Configuration Options**: Verbose mode, stop-on-failure
- **Application Integration**: Tests run against actual HTML app

### Controls

- **▶️ Run All Tests**: Execute complete test suite
- **🌐 HTML Tests Only**: Run only HTML application tests  
- **🗑️ Clear Results**: Reset test output
- **Verbose Output**: Enable detailed logging
- **Stop on First Failure**: Halt execution on first error

## 🤖 CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '16'
      - run: node tests/node-test-runner.js --output-format all
      - uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: test-results/
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'node tests/node-test-runner.js --output-format junit'
                publishTestResults testResultsPattern: 'test-results/junit-results.xml'
            }
        }
    }
}
```

## 📊 Output Formats

### JSON Results
```json
{
  "timestamp": "2025-10-12T10:30:00.000Z",
  "summary": {
    "total": 25,
    "passed": 23,
    "failed": 2,
    "skipped": 0,
    "successRate": 92.0
  },
  "suites": { "..." },
  "tests": [ "..." ]
}
```

### JUnit XML
Standard JUnit format for CI/CD integration with test failures and timing data.

### HTML Report
Comprehensive web-based report with visual success/failure indicators and detailed test breakdown.

## 🔄 Adding New Tests

### HTML Application Tests

1. Open `tests/html/html-task-tracker-tests.js`
2. Add new test methods to the `HTMLTaskTrackerTests` class
3. Call new tests from the `runTests()` method

```javascript
testNewFeature() {
    this.testFramework.it('should validate new feature', () => {
        const backup = this.backupApplicationState();
        try {
            // Test implementation
            this.testFramework.assert(condition, 'Feature works correctly');
        } finally {
            this.restoreApplicationState(backup);
        }
    });
}
```

### PowerShell Script Tests

1. Add scripts to `tests/powershell/`
2. Use the PowerShell test framework functions
3. Follow Pester testing conventions

```powershell
Describe "New PowerShell Script Tests" {
    It "Should execute correctly" {
        # Test implementation
        $result | Should -Be $expected
    }
}
```

## 🐛 Debugging Tests

### Browser Debugging
1. Open `test-runner.html` in browser
2. Open Developer Tools (F12)
3. Set breakpoints in test files
4. Run tests with verbose mode enabled

### Node.js Debugging
```bash
# Run with Node.js debugger
node --inspect-brk tests/node-test-runner.js

# Run with verbose output
node tests/node-test-runner.js --verbose
```

### Common Issues

**"tasks is not defined" Error**
- Ensure application is fully loaded before running tests
- Check that test backup/restore functions handle undefined globals

**Test Isolation Problems**
- Verify backup/restore functions capture all application state
- Clear localStorage between test runs

**Timing Issues**
- Add delays for asynchronous operations
- Use proper async/await patterns

## 🚀 Future Enhancements

### Planned Features
- **Visual Regression Testing**: Screenshot comparison for UI changes
- **Performance Testing**: Load time and execution benchmarks
- **API Testing**: Backend integration test support
- **Mobile Testing**: Responsive design validation
- **Accessibility Testing**: WCAG compliance checks

### PowerShell Integration
- **Script Testing**: Comprehensive PowerShell script validation
- **Module Testing**: PowerShell module functionality tests
- **Integration Testing**: Cross-platform script testing
- **Coverage Reporting**: PowerShell code coverage analysis

### Advanced Reporting
- **Trend Analysis**: Historical test performance tracking
- **Failure Analysis**: Automatic failure categorization
- **Performance Metrics**: Execution time trends
- **Coverage Reports**: Code coverage visualization

## 📝 Contributing

1. **Adding Tests**: Follow existing patterns and include proper cleanup
2. **Test Data**: Use the mock data creation utilities
3. **Documentation**: Update this README for new features
4. **Error Handling**: Include proper error handling and cleanup
5. **Performance**: Keep tests fast and focused

## 🏷️ Version History

- **v1.0.0**: Initial testing framework with HTML application tests
- **v1.1.0**: Added Node.js test runner and CI/CD support
- **v1.2.0**: PowerShell testing framework template
- **v1.3.0**: Enhanced reporting and browser test runner

---

## 🤝 Support

For issues or questions about the testing framework:

1. Check the console output for detailed error messages
2. Verify all required files are present
3. Ensure the HTML application loads correctly
4. Review test isolation and cleanup procedures

The testing framework is designed to be comprehensive, maintainable, and extensible for the evolving needs of the Task Tracker project.