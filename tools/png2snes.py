#!/usr/bin/env python3
"""
png2snes.py — Convert PNG images to SNES tile and palette data.

Reads a PNG file organized as an 8x8 tile grid and outputs:
  - .inc file with tile data in SNES 4bpp planar format
  - .inc file with palette data in SNES CGRAM format (bbbbbgggggrrrrr)

Usage:
    python3 png2snes.py input.png --tiles tiles.inc --palette palette.inc
    python3 png2snes.py input.png --tiles tiles.inc --palette palette.inc --bpp 2
"""

import argparse
import sys

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)


def rgb_to_snes(r, g, b):
    """Convert 8-bit RGB to 15-bit SNES color (bbbbbgggggrrrrr)."""
    sr = (r >> 3) & 0x1F
    sg = (g >> 3) & 0x1F
    sb = (b >> 3) & 0x1F
    return sr | (sg << 5) | (sb << 10)


def extract_palette(image):
    """Extract unique colors from image, return as list of SNES colors."""
    pixels = list(image.getdata())
    seen = {}
    palette = []

    for pixel in pixels:
        r, g, b = pixel[0], pixel[1], pixel[2]
        key = (r, g, b)
        if key not in seen:
            seen[key] = len(palette)
            palette.append(rgb_to_snes(r, g, b))
            if len(palette) > 256:
                print("Warning: more than 256 unique colors", file=sys.stderr)
                break

    return palette, seen


def pixel_to_index(pixel, color_map):
    """Map an RGB pixel to its palette index."""
    key = (pixel[0], pixel[1], pixel[2])
    return color_map.get(key, 0)


def encode_tile_4bpp(tile_pixels):
    """
    Encode an 8x8 tile in SNES 4bpp planar format.
    SNES 4bpp: 32 bytes per tile.
    Bitplane layout (per row):
      Bytes 0-15: bitplanes 0,1 interleaved (row0_bp0, row0_bp1, row1_bp0, row1_bp1, ...)
      Bytes 16-31: bitplanes 2,3 interleaved
    """
    result = []

    # Bitplanes 0 and 1 (rows 0-7, interleaved)
    for y in range(8):
        bp0 = 0
        bp1 = 0
        for x in range(8):
            idx = tile_pixels[y * 8 + x]
            bp0 |= ((idx >> 0) & 1) << (7 - x)
            bp1 |= ((idx >> 1) & 1) << (7 - x)
        result.append(bp0)
        result.append(bp1)

    # Bitplanes 2 and 3 (rows 0-7, interleaved)
    for y in range(8):
        bp2 = 0
        bp3 = 0
        for x in range(8):
            idx = tile_pixels[y * 8 + x]
            bp2 |= ((idx >> 2) & 1) << (7 - x)
            bp3 |= ((idx >> 3) & 1) << (7 - x)
        result.append(bp2)
        result.append(bp3)

    return result


def encode_tile_2bpp(tile_pixels):
    """Encode an 8x8 tile in SNES 2bpp planar format (16 bytes)."""
    result = []
    for y in range(8):
        bp0 = 0
        bp1 = 0
        for x in range(8):
            idx = tile_pixels[y * 8 + x]
            bp0 |= ((idx >> 0) & 1) << (7 - x)
            bp1 |= ((idx >> 1) & 1) << (7 - x)
        result.append(bp0)
        result.append(bp1)
    return result


def format_bytes_as_inc(data, label, bytes_per_line=16):
    """Format byte data as ca65 .byte directives."""
    lines = [f"; {label}"]
    for i in range(0, len(data), bytes_per_line):
        chunk = data[i:i + bytes_per_line]
        hex_vals = ", ".join(f"${b:02X}" for b in chunk)
        lines.append(f"    .byte {hex_vals}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Convert PNG to SNES tile/palette data")
    parser.add_argument("input", help="Input PNG file")
    parser.add_argument("--tiles", required=True, help="Output tile data .inc file")
    parser.add_argument("--palette", required=True, help="Output palette data .inc file")
    parser.add_argument("--bpp", type=int, default=4, choices=[2, 4],
                        help="Bits per pixel (2 or 4, default: 4)")
    parser.add_argument("--label", default="gfx_data",
                        help="Label prefix for data (default: gfx_data)")
    args = parser.parse_args()

    img = Image.open(args.input).convert("RGBA")
    width, height = img.size

    if width % 8 != 0 or height % 8 != 0:
        print(f"Error: Image dimensions ({width}x{height}) must be multiples of 8", file=sys.stderr)
        sys.exit(1)

    tiles_x = width // 8
    tiles_y = height // 8

    palette, color_map = extract_palette(img)
    max_colors = 4 if args.bpp == 2 else 16

    if len(palette) > max_colors:
        print(f"Warning: {len(palette)} colors found, but {args.bpp}bpp supports {max_colors}",
              file=sys.stderr)

    # Extract tiles
    all_tile_bytes = []
    for ty in range(tiles_y):
        for tx in range(tiles_x):
            tile_pixels = []
            for y in range(8):
                for x in range(8):
                    px = img.getpixel((tx * 8 + x, ty * 8 + y))
                    tile_pixels.append(pixel_to_index(px, color_map))

            if args.bpp == 4:
                all_tile_bytes.extend(encode_tile_4bpp(tile_pixels))
            else:
                all_tile_bytes.extend(encode_tile_2bpp(tile_pixels))

    # Write tile data
    with open(args.tiles, "w") as f:
        f.write(f"; Generated by png2snes.py from {args.input}\n")
        f.write(f"; {tiles_x * tiles_y} tiles, {args.bpp}bpp, {len(all_tile_bytes)} bytes\n\n")
        f.write(f"{args.label}_tiles:\n")
        f.write(format_bytes_as_inc(all_tile_bytes, f"{tiles_x * tiles_y} tiles"))
        f.write("\n")

    # Write palette data
    with open(args.palette, "w") as f:
        f.write(f"; Generated by png2snes.py from {args.input}\n")
        f.write(f"; {len(palette)} colors, SNES CGRAM format (little-endian)\n\n")
        f.write(f"{args.label}_palette:\n")
        pal_bytes = []
        for color in palette:
            pal_bytes.append(color & 0xFF)
            pal_bytes.append((color >> 8) & 0xFF)
        f.write(format_bytes_as_inc(pal_bytes, f"{len(palette)} colors"))
        f.write("\n")

    print(f"Tiles: {tiles_x * tiles_y} ({len(all_tile_bytes)} bytes) → {args.tiles}")
    print(f"Palette: {len(palette)} colors ({len(palette) * 2} bytes) → {args.palette}")


if __name__ == "__main__":
    main()
