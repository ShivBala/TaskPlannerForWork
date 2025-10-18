#!/usr/bin/env python3
"""
Safely remove ALL console statements from JavaScript.
"""

import re

def remove_console_statements(content):
    # Remove all console statements (handles multi-line with DOTALL flag)
    content = re.sub(
        r'console\.(log|error|trace|warn)\s*\([^)]*\)\s*;?',
        '',
        content,
        flags=re.DOTALL
    )
    
    # Clean up excessive empty lines
    content = re.sub(r'\n\s*\n\s*\n\s*\n+', '\n\n', content)
    
    return content

input_file = 'html_console_v10.html'

with open(input_file, 'r', encoding='utf-8') as f:
    original = f.read()

cleaned = remove_console_statements(original)

with open(input_file, 'w', encoding='utf-8') as f:
    f.write(cleaned)

print(f"✅ Done! Removed {original.count('console.') - cleaned.count('console.')} console statements")
print(f"Lines: {original.count(chr(10))+1} → {cleaned.count(chr(10))+1}")
print(f"Remaining console calls: {cleaned.count('console.')}")
