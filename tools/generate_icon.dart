import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// Pure Dart script to generate ClassPulse icon PNG
// Run: dart run tools/generate_icon.dart
// Uses dart:ui through a Flutter tool approach

void main() async {
  // We'll generate the PNG manually using raw pixel data
  // The icon is: blue gradient bg + 3 white bars + blue dot
  
  const int size = 1024;
  
  // Create RGBA pixel buffer
  final pixels = Uint8List(size * size * 4);
  
  // Helper: set pixel
  void setPixel(int x, int y, int r, int g, int b, int a) {
    if (x < 0 || x >= size || y < 0 || y >= size) return;
    final idx = (y * size + x) * 4;
    // Alpha blend over existing
    final srcA = a / 255.0;
    final dstA = pixels[idx + 3] / 255.0;
    final outA = srcA + dstA * (1 - srcA);
    if (outA == 0) return;
    pixels[idx]     = ((r * srcA + pixels[idx]     * dstA * (1 - srcA)) / outA).round().clamp(0, 255);
    pixels[idx + 1] = ((g * srcA + pixels[idx + 1] * dstA * (1 - srcA)) / outA).round().clamp(0, 255);
    pixels[idx + 2] = ((b * srcA + pixels[idx + 2] * dstA * (1 - srcA)) / outA).round().clamp(0, 255);
    pixels[idx + 3] = (outA * 255).round().clamp(0, 255);
  }

  // Helper: draw filled circle with AA approximation
  void fillCircle(double cx, double cy, double r, int red, int grn, int blu, double alpha) {
    final x0 = (cx - r - 1).floor();
    final x1 = (cx + r + 1).ceil();
    final y0 = (cy - r - 1).floor();
    final y1 = (cy + r + 1).ceil();
    for (int py = y0; py <= y1; py++) {
      for (int px = x0; px <= x1; px++) {
        final dist = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
        double coverage = (r - dist + 0.5).clamp(0.0, 1.0);
        if (coverage > 0) {
          setPixel(px, py, red, grn, blu, (alpha * coverage * 255).round());
        }
      }
    }
  }

  // Helper: draw rounded rect
  void fillRoundedRect(int x, int y, int w, int h, int rx, int red, int grn, int blu, double alpha) {
    for (int py = y; py < y + h; py++) {
      for (int px = x; px < x + w; px++) {
        // Check if inside rounded rect
        double nearX = px.toDouble();
        double nearY = py.toDouble();
        
        // Corner circles
        double cornerCX = -1, cornerCY = -1;
        if (px < x + rx && py < y + rx) {
          cornerCX = x + rx; cornerCY = y + rx;
        } else if (px > x + w - rx - 1 && py < y + rx) {
          cornerCX = x + w - rx - 1; cornerCY = y + rx;
        } else if (px < x + rx && py > y + h - rx - 1) {
          cornerCX = x + rx; cornerCY = y + h - rx - 1;
        } else if (px > x + w - rx - 1 && py > y + h - rx - 1) {
          cornerCX = x + w - rx - 1; cornerCY = y + h - rx - 1;
        }
        
        double coverage = 1.0;
        if (cornerCX >= 0) {
          final dist = math.sqrt((px - cornerCX) * (px - cornerCX) + (py - cornerCY) * (py - cornerCY));
          coverage = (rx - dist + 0.5).clamp(0.0, 1.0);
        }
        
        if (coverage > 0) {
          setPixel(px, py, red, grn, blu, (alpha * coverage * 255).round());
        }
      }
    }
  }

  // ─── 1. BACKGROUND: Blue gradient rounded square ───
  // Gradient from #1247C8 (top-left) to #2979FF (bottom-right)
  const bgCorner = 230;
  for (int py = 0; py < size; py++) {
    for (int px = 0; px < size; px++) {
      // Gradient t = diagonal blend
      final t = (px + py) / (size * 2.0);
      final r = (0x12 + (0x29 - 0x12) * t).round();
      final g = (0x47 + (0x79 - 0x47) * t).round();
      final b = (0xC8 + (0xFF - 0xC8) * t).round();
      setPixel(px, py, r, g, b, 255);
    }
  }

  // Rounded corner masking (clear pixels outside rounded rect)
  for (int py = 0; py < size; py++) {
    for (int px = 0; px < size; px++) {
      double cornerCX = -1.0, cornerCY = -1.0;
      if (px < bgCorner && py < bgCorner) {
        cornerCX = bgCorner; cornerCY = bgCorner;
      } else if (px > size - bgCorner - 1 && py < bgCorner) {
        cornerCX = size - bgCorner - 1; cornerCY = bgCorner.toDouble();
      } else if (px < bgCorner && py > size - bgCorner - 1) {
        cornerCX = bgCorner.toDouble(); cornerCY = size - bgCorner - 1;
      } else if (px > size - bgCorner - 1 && py > size - bgCorner - 1) {
        cornerCX = size - bgCorner - 1; cornerCY = size - bgCorner - 1;
      }
      
      if (cornerCX >= 0) {
        final dist = math.sqrt((px - cornerCX) * (px - cornerCX) + (py - cornerCY) * (py - cornerCY));
        if (dist > bgCorner) {
          final idx = (py * size + px) * 4;
          pixels[idx + 3] = 0; // clear
        }
      }
    }
  }

  // ─── 2. THREE BARS ───
  // Layout:
  //   All bars: x=224, width=652 (equal width — not a chart!)
  //   Bar1: y=304, h=104, rx=52, opacity=0.38
  //   Bar2: y=448, h=128, rx=64, opacity=1.0 (active)
  //   Bar3: y=620, h=104, rx=52, opacity=0.38

  fillRoundedRect(224, 304, 652, 104, 52,  255, 255, 255, 0.38);
  fillRoundedRect(224, 448, 652, 128, 64,  255, 255, 255, 1.0);
  fillRoundedRect(224, 620, 652, 104, 52,  255, 255, 255, 0.38);

  // ─── 3. TIMELINE DOTS (left side, x=176) ───
  // Dot1 & Dot3: white semi-transparent, r=22
  // Dot2 (active): blue filled with white ring, r=30

  fillCircle(176, 356, 22, 255, 255, 255, 0.40); // dot1 (bar1 center = 304+52=356)
  fillCircle(176, 672, 22, 255, 255, 255, 0.38); // dot3 (bar3 center = 620+52=672)

  // Active dot (bar2 center = 448+64=512)
  fillCircle(176, 512, 30, 0x1E, 0x6A, 0xF9, 1.0);  // blue outer
  fillCircle(176, 512, 16, 255, 255, 255, 1.0);      // white ring
  fillCircle(176, 512,  6, 0x60, 0xA5, 0xFA, 1.0);  // light blue center

  // ─── 4. VERTICAL TIMELINE LINE ───
  // Thin line x=176, from y=304 to y=724, white opacity 0.25
  for (int py = 304; py <= 724; py++) {
    for (int px = 173; px <= 179; px++) { // 6px wide
      setPixel(px, py, 255, 255, 255, (0.22 * 255).round());
    }
  }

  // ─── 5. ENCODE AS PNG ───
  final pngBytes = _encodePng(pixels, size, size);
  
  final outputPath = 'assets/icons/classpulse_icon.png';
  await File(outputPath).writeAsBytes(pngBytes);
  print('✓ Icon saved to $outputPath (${pngBytes.length} bytes)');
}

// Minimal PNG encoder (no external deps)
Uint8List _encodePng(Uint8List rgba, int width, int height) {
  // PNG signature
  final sig = [137, 80, 78, 71, 13, 10, 26, 10];
  
  // IHDR chunk
  final ihdr = _makeChunk('IHDR', [
    ..._int32(width),
    ..._int32(height),
    8,  // bit depth
    6,  // color type: RGBA
    0, 0, 0, // compression, filter, interlace
  ]);
  
  // IDAT chunk (compressed image data)
  // Apply filter type 0 (None) for each scanline
  final raw = <int>[];
  for (int y = 0; y < height; y++) {
    raw.add(0); // filter type None
    final rowStart = y * width * 4;
    for (int x = 0; x < width * 4; x++) {
      raw.add(rgba[rowStart + x]);
    }
  }
  
  final compressed = _zlibCompress(Uint8List.fromList(raw));
  final idat = _makeChunk('IDAT', compressed);
  
  // IEND chunk
  final iend = _makeChunk('IEND', []);
  
  return Uint8List.fromList([...sig, ...ihdr, ...idat, ...iend]);
}

List<int> _int32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> _makeChunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final crcData = [...typeBytes, ...data];
  final crc = _crc32(crcData);
  return [
    ..._int32(data.length),
    ...typeBytes,
    ...data,
    ..._int32(crc),
  ];
}

// CRC32
int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      if (crc & 1 != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}

// Simple zlib deflate (store method - no compression, but valid)
Uint8List _zlibCompress(Uint8List data) {
  // zlib header (deflate, no dict, low compression)
  // CMF=0x78 (deflate, 32KB window), FLG=0x01 (check bits, no dict, level 0)
  // Actually use 0x78 0x9C for default compression
  // We'll use stored blocks (BTYPE=00) for simplicity
  
  final out = <int>[];
  // zlib header
  out.add(0x78);
  out.add(0x9C);
  
  // Deflate stored blocks
  int offset = 0;
  while (offset < data.length) {
    final blockSize = math.min(65535, data.length - offset);
    final isLast = (offset + blockSize) >= data.length;
    
    // Block header: BFINAL | BTYPE=00
    out.add(isLast ? 1 : 0);
    // LEN and NLEN
    out.add(blockSize & 0xFF);
    out.add((blockSize >> 8) & 0xFF);
    out.add((~blockSize) & 0xFF);
    out.add(((~blockSize) >> 8) & 0xFF);
    
    // Block data
    for (int i = 0; i < blockSize; i++) {
      out.add(data[offset + i]);
    }
    offset += blockSize;
  }
  
  // Adler-32 checksum
  int s1 = 1, s2 = 0;
  for (final b in data) {
    s1 = (s1 + b) % 65521;
    s2 = (s2 + s1) % 65521;
  }
  final adler = (s2 << 16) | s1;
  out.addAll(_int32(adler));
  
  return Uint8List.fromList(out);
}
