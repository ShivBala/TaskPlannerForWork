const fs = require('fs');
const path = require('path');

// Read the HTML file
const filePath = path.join(__dirname, 'html_console_v10.html');
let content = fs.readFileSync(filePath, 'utf8');

// Store original stats
const originalLines = content.split('\n').length;
const originalSize = Buffer.byteLength(content, 'utf8');

// Count console statements
const consolePattern = /console\.(log|error|warn|trace)/g;
const originalCount = (content.match(consolePattern) || []).length;

// Replace console statements by commenting them out instead of deleting
// This preserves the code structure
content = content.replace(/(\s*)(console\.(log|error|warn|trace)\([^;]*\);?)/g, '$1// $2');

// Count remaining
const remaining = (content.match(consolePattern) || []).length;

// Get new stats
const newLines = content.split('\n').length;
const newSize = Buffer.byteLength(content, 'utf8');

// Write back
fs.writeFileSync(filePath, content, 'utf8');

console.log('✅ Console statements commented out!');
console.log(`Original: ${originalLines} lines, ${(originalSize/1024).toFixed(1)} KB`);
console.log(`New: ${newLines} lines, ${(newSize/1024).toFixed(1)} KB`);
console.log(`Console statements: ${originalCount} → ${remaining} (${originalCount - remaining} commented out)`);
