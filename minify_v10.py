#!/usr/bin/env python3
"""
Simple but effective HTML minifier for html_console_v10.html
Removes whitespace, comments, and unnecessary characters without breaking functionality.
"""

import re
import sys

def minify_html(html):
    """Minify HTML content"""
    
    # Remove HTML comments (but not conditional comments)
    html = re.sub(r'<!--(?!\[if).*?-->', '', html, flags=re.DOTALL)
    
    # Remove JavaScript comments (single-line // comments)
    # But preserve URLs like http://
    html = re.sub(r'(?<!:)//[^\n]*', '', html)
    
    # Remove multi-line JavaScript comments /* ... */
    # But preserve important ones like /*! ... */
    html = re.sub(r'/\*(?!!)[^*]*\*+(?:[^/*][^*]*\*+)*/', '', html)
    
    # Remove leading/trailing whitespace from lines
    lines = html.split('\n')
    lines = [line.strip() for line in lines]
    
    # Remove empty lines
    lines = [line for line in lines if line]
    
    # Join lines
    html = ' '.join(lines)
    
    # Collapse multiple spaces into one
    html = re.sub(r'\s+', ' ', html)
    
    # Remove spaces around certain characters
    html = re.sub(r'\s*([{};:,<>])\s*', r'\1', html)
    html = re.sub(r'\s*([=+\-*/])\s*', r'\1', html)
    
    # Remove space after opening tags and before closing tags
    html = re.sub(r'>\s+', '>', html)
    html = re.sub(r'\s+<', '<', html)
    
    return html

def main():
    input_file = 'html_console_v10.html'
    output_file = 'html_console_v10_minified.html'
    
    print(f"📖 Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        original = f.read()
    
    original_size = len(original)
    original_lines = original.count('\n') + 1
    
    print(f"🔧 Minifying...")
    minified = minify_html(original)
    
    minified_size = len(minified)
    minified_lines = minified.count('\n') + 1
    
    print(f"💾 Writing {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(minified)
    
    # Calculate savings
    size_saved = original_size - minified_size
    size_percent = (size_saved / original_size) * 100
    
    print("\n✅ Minification Complete!")
    print("=" * 50)
    print(f"Original:  {original_lines:,} lines, {original_size:,} bytes ({original_size/1024:.1f} KB)")
    print(f"Minified:  {minified_lines:,} lines, {minified_size:,} bytes ({minified_size/1024:.1f} KB)")
    print(f"Saved:     {size_saved:,} bytes ({size_saved/1024:.1f} KB)")
    print(f"Reduction: {size_percent:.1f}%")
    print("=" * 50)
    print(f"\n📄 Output: {output_file}")

if __name__ == '__main__':
    main()
