#!/usr/bin/env python3
"""
Minify html_console_v10.html by extracting and minifying JavaScript sections
"""
import re
import subprocess
import tempfile
import os

def minify_html(input_file, output_file):
    print(f"📖 Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all <script> blocks
    script_pattern = r'<script>(.*?)</script>'
    scripts = re.finditer(script_pattern, content, re.DOTALL)
    
    minified_content = content
    script_count = 0
    
    for match in scripts:
        script_count += 1
        original_script = match.group(1)
        
        # Skip empty or very small scripts
        if len(original_script.strip()) < 50:
            continue
        
        print(f"🔧 Minifying script block {script_count} ({len(original_script)} chars)...")
        
        # Write script to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.js', delete=False, encoding='utf-8') as temp_in:
            temp_in.write(original_script)
            temp_in_path = temp_in.name
        
        try:
            # Minify with terser
            result = subprocess.run(
                ['npx', 'terser', temp_in_path, '--compress', '--mangle'],
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            if result.returncode == 0:
                minified_script = result.stdout
                print(f"   ✅ Reduced to {len(minified_script)} chars ({100 - int(len(minified_script)/len(original_script)*100)}% smaller)")
                
                # Replace in content
                minified_content = minified_content.replace(
                    f'<script>{original_script}</script>',
                    f'<script>{minified_script}</script>',
                    1
                )
            else:
                print(f"   ⚠️  Terser error: {result.stderr[:100]}")
        finally:
            os.unlink(temp_in_path)
    
    # Minify CSS sections
    css_pattern = r'<style>(.*?)</style>'
    css_blocks = re.finditer(css_pattern, minified_content, re.DOTALL)
    
    css_count = 0
    for match in css_blocks:
        css_count += 1
        original_css = match.group(1)
        
        if len(original_css.strip()) < 50:
            continue
        
        print(f"🎨 Minifying CSS block {css_count}...")
        # Simple CSS minification (remove comments, extra whitespace)
        minified_css = re.sub(r'/\*.*?\*/', '', original_css, flags=re.DOTALL)
        minified_css = re.sub(r'\s+', ' ', minified_css)
        minified_css = re.sub(r'\s*([{}:;,])\s*', r'\1', minified_css)
        minified_css = minified_css.strip()
        
        print(f"   ✅ Reduced to {len(minified_css)} chars")
        
        minified_content = minified_content.replace(
            f'<style>{original_css}</style>',
            f'<style>{minified_css}</style>',
            1
        )
    
    # Remove HTML comments (but keep conditional comments)
    minified_content = re.sub(r'<!--(?!\[if).*?-->', '', minified_content, flags=re.DOTALL)
    
    # Remove extra whitespace between tags (but preserve single spaces)
    minified_content = re.sub(r'>\s+<', '><', minified_content)
    
    # Write output
    print(f"💾 Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(minified_content)
    
    # Compare sizes
    original_size = os.path.getsize(input_file)
    minified_size = os.path.getsize(output_file)
    reduction = int((1 - minified_size/original_size) * 100)
    
    print(f"\n✅ Minification complete!")
    print(f"   Original:  {original_size:,} bytes")
    print(f"   Minified:  {minified_size:,} bytes")
    print(f"   Reduction: {reduction}%")

if __name__ == '__main__':
    input_file = 'html_console_v10.html'
    output_file = 'html_console_v10.min.html'
    minify_html(input_file, output_file)
