"""
Generate ClassPulse app icon as PNG using only Pillow (no Cairo/SVG needed).
Draws the icon directly: gradient bg + timeline bars + dots.
Run: python tools/gen_icon.py
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = "assets/icons/classpulse_icon.png"


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_rounded_rect(draw, x, y, w, h, r, fill, alpha=255):
    """Draw a filled rounded rectangle with given alpha."""
    # We'll draw on a temp RGBA image and paste
    tmp = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    color = fill + (alpha,) if len(fill) == 3 else fill
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=color)
    return tmp


def draw_circle(draw_img, cx, cy, r, fill, alpha=255):
    tmp = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    color = fill + (alpha,) if len(fill) == 3 else fill
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    return tmp


def composite(base, layer):
    return Image.alpha_composite(base, layer)


# ── 1. Base canvas ──────────────────────────────────────────────────────────
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# ── 2. Gradient background ───────────────────────────────────────────────────
# #1247C8 top-left → #2979FF bottom-right
grad = Image.new("RGBA", (SIZE, SIZE))
px = grad.load()
c1 = (0x12, 0x47, 0xC8)
c2 = (0x29, 0x79, 0xFF)
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (SIZE * 2)
        r, g, b = lerp_color(c1, c2, t)
        px[x, y] = (r, g, b, 255)

# Apply rounded-square mask (corner radius 230)
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=230, fill=255)
grad.putalpha(mask)
img = composite(img, grad)

# ── 3. Vertical timeline line ─────────────────────────────────────────────
# x=176, y=304→724, width=5px, white opacity 0.22
line_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ld = ImageDraw.Draw(line_layer)
ld.rectangle([173, 304, 179, 724], fill=(255, 255, 255, 56))  # 56 ≈ 0.22*255
img = composite(img, line_layer)

# ── 4. THREE BARS (all same width = not a bar chart!) ───────────────────────
# Bar 1: y=304 h=104 rx=52  white 38%
bar1 = draw_rounded_rect(None, 224, 304, 652, 104, 52, (255, 255, 255), 97)   # 97 ≈ 0.38*255
img = composite(img, bar1)

# Bar 2 (active): y=448 h=128 rx=64  white 100%
bar2 = draw_rounded_rect(None, 224, 448, 652, 128, 64, (255, 255, 255), 255)
img = composite(img, bar2)

# Bar 3: y=620 h=104 rx=52  white 36%
bar3 = draw_rounded_rect(None, 224, 620, 652, 104, 52, (255, 255, 255), 92)   # 92 ≈ 0.36*255
img = composite(img, bar3)

# ── 5. TIMELINE DOTS ─────────────────────────────────────────────────────────
# Dot 1 (bar1 center = 304+52=356): white 40%
d1 = draw_circle(None, 176, 356, 22, (255, 255, 255), 102)
img = composite(img, d1)

# Dot 3 (bar3 center = 620+52=672): white 38%
d3 = draw_circle(None, 176, 672, 22, (255, 255, 255), 97)
img = composite(img, d3)

# Dot 2 — ACTIVE dot (bar2 center = 448+64=512): blue filled
# Outer ring: brand blue
d2_outer = draw_circle(None, 176, 512, 30, (0x1E, 0x6A, 0xF9), 255)
img = composite(img, d2_outer)
# White ring
d2_white = draw_circle(None, 176, 512, 16, (255, 255, 255), 255)
img = composite(img, d2_white)
# Light blue center
d2_center = draw_circle(None, 176, 512, 6, (0x60, 0xA5, 0xFA), 255)
img = composite(img, d2_center)

# ── 6. Save ──────────────────────────────────────────────────────────────────
img.save(OUT, "PNG")
print(f"✓  Saved {OUT}  ({SIZE}×{SIZE} px)")
