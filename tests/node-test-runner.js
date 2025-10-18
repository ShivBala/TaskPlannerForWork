#!/usr/bin/env node

/**
 * Node.js Test Runner for Task Tracker
 * 
 * This script provides a command-line interface for running tests
 * in CI/CD environments or for automated testing.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Import the test framework
const TestFramework = require('./test-framework.js');

class NodeTestRunner extends TestFramework {
    constructor(options = {}) {
        super(options);
        this.projectRoot = options.projectRoot || process.cwd();
        this.outputDir = options.outputDir || path.join(this.projectRoot, 'test-results');
    }

    async loadTestModules() {
        // For Node.js environment, we'll focus on unit tests
        // HTML tests require a browser environment
        
        console.log('🔍 Scanning for test modules...');
        
        // Look for test files
        const testFiles = this.findTestFiles();
        
        if (testFiles.length === 0) {
            console.log('ℹ️  No test files found');
            return;
        }

        console.log(`Found ${testFiles.length} test file(s):`);
        testFiles.forEach(file => console.log(`  - ${path.relative(this.projectRoot, file)}`));

        // For now, we'll create a basic structure test
        this.describe('Project Structure Tests', () => {
            this.testProjectStructure();
        });

        this.describe('Code Quality Tests', () => {
            this.testCodeQuality();
        });
    }

    findTestFiles() {
        const testDirs = [
            path.join(this.projectRoot, 'tests'),
            path.join(this.projectRoot, 'test'),
            path.join(this.projectRoot, '__tests__')
        ];

        const testFiles = [];
        
        testDirs.forEach(dir => {
            if (fs.existsSync(dir)) {
                const files = this.walkDirectory(dir)
                    .filter(file => file.endsWith('.test.js') || file.endsWith('.spec.js'));
                testFiles.push(...files);
            }
        });

        return testFiles;
    }

    walkDirectory(dir) {
        const files = [];
        const items = fs.readdirSync(dir);

        items.forEach(item => {
            const fullPath = path.join(dir, item);
            const stat = fs.statSync(fullPath);

            if (stat.isDirectory()) {
                files.push(...this.walkDirectory(fullPath));
            } else {
                files.push(fullPath);
            }
        });

        return files;
    }

    testProjectStructure() {
        this.it('should have main HTML file', () => {
            const htmlFile = path.join(this.projectRoot, 'html_console_v10.html');
            this.assert(fs.existsSync(htmlFile), 'Main HTML file should exist');
        });

        this.it('should have tests directory', () => {
            const testsDir = path.join(this.projectRoot, 'tests');
            this.assert(fs.existsSync(testsDir), 'Tests directory should exist');
        });

        this.it('should have test framework files', () => {
            const frameworkFile = path.join(this.projectRoot, 'tests', 'test-framework.js');
            this.assert(fs.existsSync(frameworkFile), 'Test framework should exist');
        });

        this.it('should have HTML test files', () => {
            const htmlTestFile = path.join(this.projectRoot, 'tests', 'html', 'html-task-tracker-tests.js');
            this.assert(fs.existsSync(htmlTestFile), 'HTML test file should exist');
        });

        this.it('should have test runner HTML', () => {
            const testRunnerFile = path.join(this.projectRoot, 'tests', 'test-runner.html');
            this.assert(fs.existsSync(testRunnerFile), 'Test runner HTML should exist');
        });
    }

    testCodeQuality() {
        this.it('should have valid JavaScript syntax in test framework', () => {
            const frameworkFile = path.join(this.projectRoot, 'tests', 'test-framework.js');
            if (fs.existsSync(frameworkFile)) {
                this.assertDoesNotThrow(() => {
                    require(frameworkFile);
                }, 'Test framework should have valid syntax');
            } else {
                this.assert(false, 'Test framework file not found');
            }
        });

        this.it('should have proper file structure', () => {
            const requiredDirs = ['tests/html', 'tests/powershell'];
            requiredDirs.forEach(dir => {
                const fullPath = path.join(this.projectRoot, dir);
                this.assert(fs.existsSync(fullPath), `Directory ${dir} should exist`);
            });
        });

        this.it('should have documentation files', () => {
            const docFiles = ['README.md', 'tests/README.md'];
            docFiles.forEach(file => {
                const fullPath = path.join(this.projectRoot, file);
                if (fs.existsSync(fullPath)) {
                    this.assert(true, `Documentation file ${file} exists`);
                } else {
                    // Not critical, just log
                    console.log(`ℹ️  Optional documentation file ${file} not found`);
                }
            });
        });
    }

    async exportResults(format = 'json') {
        if (!fs.existsSync(this.outputDir)) {
            fs.mkdirSync(this.outputDir, { recursive: true });
        }

        const results = {
            timestamp: new Date().toISOString(),
            summary: {
                total: this.testCount,
                passed: this.passCount,
                failed: this.failCount,
                skipped: this.skipCount,
                successRate: this.testCount > 0 ? (this.passCount / this.testCount) * 100 : 0
            },
            suites: this.suiteResults,
            tests: this.testResults
        };

        // Export as JSON
        const jsonFile = path.join(this.outputDir, 'test-results.json');
        fs.writeFileSync(jsonFile, JSON.stringify(results, null, 2));
        console.log(`📄 Results exported to ${jsonFile}`);

        // Export as JUnit XML for CI/CD
        if (format === 'junit' || format === 'all') {
            const junitFile = path.join(this.outputDir, 'junit-results.xml');
            this.exportJUnitXML(results, junitFile);
            console.log(`📄 JUnit results exported to ${junitFile}`);
        }

        // Export as HTML report
        if (format === 'html' || format === 'all') {
            const htmlFile = path.join(this.outputDir, 'test-report.html');
            this.exportHTMLReport(results, htmlFile);
            console.log(`📄 HTML report exported to ${htmlFile}`);
        }

        return results;
    }

    exportJUnitXML(results, outputFile) {
        const xml = `<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="${results.summary.total}" failures="${results.summary.failed}" errors="0" time="${results.duration || 0}">
${Object.entries(results.suites).map(([suiteName, suite]) => `
    <testsuite name="${suiteName}" tests="${suite.total}" failures="${suite.failed}" errors="0" time="${suite.duration || 0}">
${results.tests.filter(test => test.suite === suiteName).map(test => `
        <testcase name="${test.message}" time="0">
${!test.passed ? `            <failure message="${test.message}">${JSON.stringify(test.details)}</failure>` : ''}
        </testcase>`).join('')}
    </testsuite>`).join('')}
</testsuites>`;

        fs.writeFileSync(outputFile, xml);
    }

    exportHTMLReport(results, outputFile) {
        const html = `<!DOCTYPE html>
<html>
<head>
    <title>Test Results Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .pass { color: green; }
        .fail { color: red; }
        .suite { margin-bottom: 15px; }
        .suite-header { font-weight: bold; background: #e9e9e9; padding: 10px; }
        .test-item { padding: 5px 0; margin-left: 20px; }
    </style>
</head>
<body>
    <h1>Test Results Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Total: ${results.summary.total}</p>
        <p class="pass">Passed: ${results.summary.passed}</p>
        <p class="fail">Failed: ${results.summary.failed}</p>
        <p>Success Rate: ${results.summary.successRate.toFixed(1)}%</p>
        <p>Generated: ${results.timestamp}</p>
    </div>
    
    ${Object.entries(results.suites).map(([suiteName, suite]) => `
    <div class="suite">
        <div class="suite-header">${suiteName} (${suite.passed}✅ ${suite.failed}❌)</div>
        ${results.tests.map(test => `
        <div class="test-item ${test.passed ? 'pass' : 'fail'}">
            ${test.passed ? '✅' : '❌'} ${test.message}
        </div>`).join('')}
    </div>`).join('')}
</body>
</html>`;

        fs.writeFileSync(outputFile, html);
    }

    static async run(options = {}) {
        const runner = new NodeTestRunner(options);
        
        console.log('🧪 Task Tracker Node.js Test Runner');
        console.log('=' .repeat(40));
        
        const startTime = Date.now();
        const results = await runner.runTests();
        const endTime = Date.now();
        
        results.duration = endTime - startTime;
        
        // Export results
        await runner.exportResults(options.outputFormat || 'all');
        
        // Exit with error code if tests failed
        const exitCode = results.failed > 0 ? 1 : 0;
        console.log(`\n🏁 Tests completed with exit code: ${exitCode}`);
        
        return { results, exitCode };
    }
}

// Command line interface
if (require.main === module) {
    const args = process.argv.slice(2);
    const options = {};
    
    // Parse command line arguments
    for (let i = 0; i < args.length; i += 2) {
        const key = args[i].replace(/^--/, '');
        const value = args[i + 1];
        
        switch (key) {
            case 'output-format':
                options.outputFormat = value;
                break;
            case 'project-root':
                options.projectRoot = value;
                break;
            case 'verbose':
                options.verbose = true;
                i -= 1; // No value for this flag
                break;
            case 'stop-on-failure':
                options.stopOnFirstFailure = true;
                i -= 1; // No value for this flag
                break;
        }
    }
    
    NodeTestRunner.run(options)
        .then(({ results, exitCode }) => {
            process.exit(exitCode);
        })
        .catch(error => {
            console.error('❌ Test runner failed:', error);
            process.exit(1);
        });
}

module.exports = NodeTestRunner;