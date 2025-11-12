#!/usr/bin/env python3
"""
Convert SVG to PNG for Flutter launcher icons
Requires: pip install pillow
"""

import sys
from pathlib import Path
import subprocess

# Since Python SVG libraries have Cairo dependencies on Windows,
# let's use ImageMagick if available, otherwise ask user to convert manually
svg_path = Path('assets/icon/icon.svg')
output_path = Path('assets/icon/icon.png')

# Padding percentage (e.g., 0.1 = 10% padding on each side)
PADDING = 0.1
OUTPUT_SIZE = 1024

print(f"Attempting to convert {svg_path} to PNG using ImageMagick...")

try:
    # Calculate the size with padding
    # If we want 10% padding on each side, the content should be 80% of final size
    content_size = int(OUTPUT_SIZE * (1 - 2 * PADDING))
    
    # Try using ImageMagick
    result = subprocess.run(
        ['magick', 'convert', '-background', 'none', '-density', '300', 
         str(svg_path), '-resize', f'{content_size}x{content_size}',
         '-gravity', 'center', '-extent', f'{OUTPUT_SIZE}x{OUTPUT_SIZE}',
         str(output_path)],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print(f"✓ Successfully converted to {output_path}")
        print(f"  Size: {OUTPUT_SIZE}x{OUTPUT_SIZE}px")
        print(f"  Content size: {content_size}x{content_size}px ({int(PADDING*100)}% padding)")
    else:
        raise Exception("ImageMagick conversion failed")
        
except Exception:
    print("\n⚠ ImageMagick not found or conversion failed.")
    print("\nPlease convert icon.svg to PNG manually:")
    print("1. Open icon.svg in a graphics editor (Inkscape, GIMP, etc.)")
    print("2. Export as PNG with size 1024x1024px with padding")
    print("3. Save as assets/icon/icon.png")
    print("\nOr install ImageMagick: https://imagemagick.org/script/download.php")
    sys.exit(1)