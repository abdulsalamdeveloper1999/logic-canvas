#!/usr/bin/env python3
"""
Generates a simple "AlgoSketch" style app icon as a PNG (no external deps).

Outputs:
  - assets/icons/app_icon.png (1024x1024)
"""

from __future__ import annotations

import struct
import zlib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Color:
    r: int
    g: int
    b: int
    a: int = 255


def _clamp_u8(v: int) -> int:
    if v < 0:
        return 0
    if v > 255:
        return 255
    return v


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _blend_over(dst: tuple[int, int, int, int], src: Color) -> tuple[int, int, int, int]:
    """Alpha blend src over dst. Returns opaque RGBA (a=255)."""
    if src.a >= 255:
        return (src.r, src.g, src.b, 255)
    if src.a <= 0:
        return dst
    a = src.a
    inv = 255 - a
    dr, dg, db, _da = dst
    r = (src.r * a + dr * inv) // 255
    g = (src.g * a + dg * inv) // 255
    b = (src.b * a + db * inv) // 255
    return (r, g, b, 255)


class Raster:
    def __init__(self, w: int, h: int) -> None:
        self.w = w
        self.h = h
        # PNG scanlines with filter byte per row (filter=0).
        self.data = bytearray(h * (1 + w * 4))
        stride = 1 + w * 4
        for y in range(h):
            self.data[y * stride] = 0

    def _idx(self, x: int, y: int) -> int:
        return y * (1 + self.w * 4) + 1 + x * 4

    def get(self, x: int, y: int) -> tuple[int, int, int, int]:
        i = self._idx(x, y)
        d = self.data
        return (d[i], d[i + 1], d[i + 2], d[i + 3])

    def set(self, x: int, y: int, c: Color) -> None:
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        i = self._idx(x, y)
        d = self.data
        d[i] = c.r
        d[i + 1] = c.g
        d[i + 2] = c.b
        d[i + 3] = c.a

    def blend(self, x: int, y: int, c: Color) -> None:
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        i = self._idx(x, y)
        d = self.data
        dst = (d[i], d[i + 1], d[i + 2], d[i + 3])
        r, g, b, a = _blend_over(dst, c)
        d[i] = r
        d[i + 1] = g
        d[i + 2] = b
        d[i + 3] = a


def _draw_circle(r: Raster, cx: int, cy: int, radius: int, c: Color) -> None:
    rr = radius * radius
    y0 = cy - radius
    y1 = cy + radius
    x0 = cx - radius
    x1 = cx + radius
    for y in range(y0, y1 + 1):
        dy = y - cy
        dy2 = dy * dy
        for x in range(x0, x1 + 1):
            dx = x - cx
            if dx * dx + dy2 <= rr:
                r.blend(x, y, c)


def _draw_line(r: Raster, x0: int, y0: int, x1: int, y1: int, thickness: int, c: Color) -> None:
    # Bresenham with circular stamping for thickness.
    radius = max(1, thickness // 2)
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    x, y = x0, y0
    while True:
        _draw_circle(r, x, y, radius, c)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy


def _fill_rounded_rect(r: Raster, x0: int, y0: int, x1: int, y1: int, radius: int, c: Color) -> None:
    # Inclusive coords.
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            # Find the nearest corner center and check if we are outside.
            cx = x0 + radius if x < x0 + radius else (x1 - radius if x > x1 - radius else x)
            cy = y0 + radius if y < y0 + radius else (y1 - radius if y > y1 - radius else y)
            dx = x - cx
            dy = y - cy
            if dx * dx + dy * dy <= radius * radius:
                r.blend(x, y, c)


def _write_png(path: Path, w: int, h: int, scanlines: bytes) -> None:
    def chunk(typ: bytes, payload: bytes) -> bytes:
        crc = zlib.crc32(typ)
        crc = zlib.crc32(payload, crc) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + typ + payload + struct.pack(">I", crc)

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)  # 8-bit RGBA
    compressed = zlib.compress(scanlines, level=9)

    png = bytearray()
    png += signature
    png += chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", compressed)
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def main() -> int:
    out = Path(__file__).resolve().parents[1] / "assets" / "icons" / "app_icon.png"
    out.parent.mkdir(parents=True, exist_ok=True)

    w = h = 1024
    ras = Raster(w, h)

    # Background gradient + subtle radial highlight.
    top = (10, 20, 35)
    bottom = (0, 140, 160)
    cx, cy = w // 2, h // 2
    max_r2 = (cx * cx + cy * cy)
    for y in range(h):
        t = y / (h - 1)
        br = int(_lerp(top[0], bottom[0], t))
        bg = int(_lerp(top[1], bottom[1], t))
        bb = int(_lerp(top[2], bottom[2], t))
        for x in range(w):
            dx = x - cx
            dy = y - cy
            r2 = dx * dx + dy * dy
            # Highlight stronger near top-left.
            hl = 0.10 * (1.0 - min(1.0, r2 / max_r2))
            if x < cx and y < cy:
                hl *= 1.6
            r = _clamp_u8(int(br + (255 - br) * hl))
            g = _clamp_u8(int(bg + (255 - bg) * hl))
            b = _clamp_u8(int(bb + (255 - bb) * hl))
            ras.set(x, y, Color(r, g, b, 255))

    # Glassy "board" inset.
    margin = 140
    board = Color(255, 255, 255, 26)
    _fill_rounded_rect(ras, margin, margin, w - margin, h - margin, radius=120, c=board)

    # Board border (drawn as thick lines).
    border = Color(255, 255, 255, 80)
    thick = 14
    x0, y0 = margin, margin
    x1, y1 = w - margin, h - margin
    _draw_line(ras, x0 + 120, y0, x1 - 120, y0, thick, border)
    _draw_line(ras, x0 + 120, y1, x1 - 120, y1, thick, border)
    _draw_line(ras, x0, y0 + 120, x0, y1 - 120, thick, border)
    _draw_line(ras, x1, y0 + 120, x1, y1 - 120, thick, border)
    for (px, py) in ((x0 + 120, y0 + 120), (x1 - 120, y0 + 120), (x0 + 120, y1 - 120), (x1 - 120, y1 - 120)):
        _draw_circle(ras, px, py, 70, border)

    # Code mark: </> in the middle.
    code = Color(245, 250, 255, 255)
    code_thick = 28
    midx, midy = 512, 540
    # Left chevron
    _draw_line(ras, midx - 120, midy - 110, midx - 190, midy, code_thick, code)
    _draw_line(ras, midx - 190, midy, midx - 120, midy + 110, code_thick, code)
    # Right chevron
    _draw_line(ras, midx + 120, midy - 110, midx + 190, midy, code_thick, code)
    _draw_line(ras, midx + 190, midy, midx + 120, midy + 110, code_thick, code)
    # Slash
    _draw_line(ras, midx - 35, midy + 140, midx + 35, midy - 140, code_thick, code)

    # Accent stroke (teal) to hint "sketch".
    accent = Color(0, 245, 225, 200)
    _draw_line(ras, 260, 760, 790, 690, 18, accent)
    _draw_circle(ras, 790, 690, 16, Color(255, 255, 255, 160))

    # Small sparkles.
    sparkle = Color(255, 255, 255, 180)
    for (sx, sy, sr) in ((320, 320, 8), (740, 320, 10), (690, 820, 7), (360, 820, 6)):
        _draw_circle(ras, sx, sy, sr, sparkle)
        _draw_circle(ras, sx, sy, sr // 2, Color(0, 245, 225, 160))

    _write_png(out, w, h, ras.data)
    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

