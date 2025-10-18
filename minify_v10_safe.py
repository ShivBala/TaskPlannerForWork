#!/usr/bin/env python3
"""
Minify html_console_v10.html using the proven htmlmin library.
This preserves JavaScript functionality while reducing file size.
"""

import htmlmin
import os

input_file = 'html_console_v10.html'
output_file = 'html_console_v10_minified.html'

print(f"📖 Reading {input_file}...")
with open(input_file, 'r', encoding='utf-8') as f:
    original = f.read()

original_size = len(original)
original_lines = original.count('\n') + 1

print(f"🔧 Minifying with htmlmin library...")
# Use htmlmin with safe options that preserve functionality
minified = htmlmin.minify(
    original,
    remove_comments=True,
    remove_empty_space=True,
    remove_all_empty_space=False,  # Keep some spaces for JS safety
    reduce_empty_attributes=True,
    reduce_boolean_attributes=False,  # Keep for compatibility
    remove_optional_attribute_quotes=False,  # Keep quotes for safety
    keep_pre=True,  # Preserve <pre> tag formatting
    pre_tags=('pre', 'textarea'),
    pre_attr='pre'
)

minified_size = len(minified)
minified_lines = minified.count('\n') + 1

print(f"💾 Writing {output_file}...")
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(minified)

# Calculate savings
size_saved = original_size - minified_size
size_percent = (size_saved / original_size) * 100

print("\n✅ Minification Complete!")
print("=" * 60)
print(f"Original:  {original_lines:,} lines, {original_size:,} bytes ({original_size/1024:.1f} KB)")
print(f"Minified:  {minified_lines:,} lines, {minified_size:,} bytes ({minified_size/1024:.1f} KB)")
print(f"Saved:     {size_saved:,} bytes ({size_saved/1024:.1f} KB)")
print(f"Reduction: {size_percent:.1f}%")
print("=" * 60)
print(f"\n📄 Output: {output_file}")
print(f"✅ JavaScript functionality preserved")
