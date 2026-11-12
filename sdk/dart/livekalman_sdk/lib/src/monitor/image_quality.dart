import 'dart:math' as math;
import 'dart:typed_data';

/// Image-quality metrics with the same definitions as shared/quality (Go):
/// MSE and PSNR over all 8-bit RGB samples (peak 255); SSIM on BT.601 luma
/// with an 11x11 Gaussian window (sigma 1.5), K1 = 0.01, K2 = 0.03, L = 255,
/// averaged over every full window position (Wang et al., 2004).
final class ImageMetrics {
  const ImageMetrics({
    required this.width,
    required this.height,
    required this.mse,
    required this.psnr,
    required this.ssim,
    required this.preprocessing,
  });

  final int width, height;
  final double mse;

  /// `double.infinity` when the images are identical.
  final double psnr;
  final double ssim;
  final String preprocessing;
}

/// An 8-bit RGB image, row-major and top-down.
final class RgbImage {
  RgbImage(this.width, this.height, this.rgb)
    : assert(rgb.length == width * height * 3);
  final int width, height;
  final Uint8List rgb;

  Float64List luma() {
    final out = Float64List(width * height);
    for (var i = 0; i < out.length; i++) {
      out[i] =
          0.299 * rgb[3 * i] + 0.587 * rgb[3 * i + 1] + 0.114 * rgb[3 * i + 2];
    }
    return out;
  }
}

/// Pixel geometry of an uncompressed 24/32-bit BMP.
final class BmpLayout {
  const BmpLayout(
    this.width,
    this.height,
    this.bitsPerPixel,
    this.pixelOffset,
    this.rowStride,
    this.topDown,
  );
  final int width, height, bitsPerPixel, pixelOffset, rowStride;
  final bool topDown;

  static BmpLayout parse(Uint8List b) {
    if (b.length < 54 || b[0] != 0x42 || b[1] != 0x4D) {
      throw const FormatException('not a BMP file');
    }
    final d = ByteData.sublistView(b);
    final offset = d.getUint32(10, Endian.little);
    final width = d.getInt32(18, Endian.little);
    var height = d.getInt32(22, Endian.little);
    final bpp = d.getUint16(28, Endian.little);
    final compression = d.getUint32(30, Endian.little);
    if (compression != 0 && compression != 3) {
      throw FormatException(
        'compressed BMP (type $compression) is not supported',
      );
    }
    if (bpp != 24 && bpp != 32) {
      throw FormatException('$bpp-bit BMP is not supported (24 or 32 only)');
    }
    final topDown = height < 0;
    if (topDown) height = -height;
    if (width <= 0 || height <= 0 || width > 16384 || height > 16384) {
      throw FormatException('invalid BMP size ${width}x$height');
    }
    final stride = ((width * bpp ~/ 8 + 3) ~/ 4) * 4;
    return BmpLayout(width, height, bpp, offset, stride, topDown);
  }

  /// Decodes the pixels of [b] with this layout; [b]'s own header is ignored.
  RgbImage decode(Uint8List b) {
    final need = pixelOffset + rowStride * height;
    if (b.length < need) {
      throw FormatException(
        'pixel data incomplete: have ${b.length} bytes, need $need',
      );
    }
    final bytesPP = bitsPerPixel ~/ 8;
    final rgb = Uint8List(width * height * 3);
    for (var y = 0; y < height; y++) {
      final srcRow = topDown ? y : height - 1 - y;
      final row = pixelOffset + srcRow * rowStride;
      for (var x = 0; x < width; x++) {
        final p = row + x * bytesPP;
        final o = 3 * (y * width + x);
        rgb[o] = b[p + 2];
        rgb[o + 1] = b[p + 1];
        rgb[o + 2] = b[p];
      }
    }
    return RgbImage(width, height, rgb);
  }
}

/// Compares two BMP files, reading both with the ORIGINAL's header geometry
/// because bit errors may corrupt the reconstructed header.
ImageMetrics compareBmp(Uint8List original, Uint8List reconstructed) {
  final layout = BmpLayout.parse(original);
  final a = layout.decode(original);
  final RgbImage b;
  try {
    b = layout.decode(reconstructed);
  } on FormatException catch (e) {
    throw FormatException('reconstructed: ${e.message}');
  }
  final m = compareImages(a, b);
  return ImageMetrics(
    width: m.width,
    height: m.height,
    mse: m.mse,
    psnr: m.psnr,
    ssim: m.ssim,
    preprocessing:
        'BMP ${layout.width}x${layout.height}, ${layout.bitsPerPixel}-bit, uint8 RGB; '
        'reconstructed pixels read with the original header geometry; SSIM on BT.601 luma',
  );
}

ImageMetrics compareImages(RgbImage a, RgbImage b) {
  if (a.width != b.width || a.height != b.height) {
    throw FormatException(
      'image sizes differ: ${a.width}x${a.height} vs ${b.width}x${b.height}',
    );
  }
  if (a.width < 11 || a.height < 11) {
    throw const FormatException('images must be at least 11x11 for SSIM');
  }
  var se = 0.0;
  for (var i = 0; i < a.rgb.length; i++) {
    final d = a.rgb[i].toDouble() - b.rgb[i];
    se += d * d;
  }
  final mse = se / a.rgb.length;
  final psnr = mse == 0
      ? double.infinity
      : 10 * math.log(255 * 255 / mse) / math.ln10;
  return ImageMetrics(
    width: a.width,
    height: a.height,
    mse: mse,
    psnr: psnr,
    ssim: ssim(a.luma(), b.luma(), a.width, a.height),
    preprocessing: 'uint8 RGB; SSIM on BT.601 luma',
  );
}

double ssim(Float64List x, Float64List y, int width, int height) {
  const size = 11, sigma = 1.5;
  const c1 = (0.01 * 255) * (0.01 * 255), c2 = (0.03 * 255) * (0.03 * 255);
  final w = Float64List(size * size);
  var sum = 0.0;
  for (var i = 0; i < size; i++) {
    for (var j = 0; j < size; j++) {
      final di = (i - size ~/ 2).toDouble(), dj = (j - size ~/ 2).toDouble();
      w[i * size + j] = math.exp(-(di * di + dj * dj) / (2 * sigma * sigma));
      sum += w[i * size + j];
    }
  }
  for (var i = 0; i < w.length; i++) {
    w[i] /= sum;
  }
  var total = 0.0;
  var count = 0;
  for (var top = 0; top + size <= height; top++) {
    for (var left = 0; left + size <= width; left++) {
      var mx = 0.0, my = 0.0;
      for (var i = 0; i < size; i++) {
        for (var j = 0; j < size; j++) {
          final k = w[i * size + j], p = (top + i) * width + left + j;
          mx += k * x[p];
          my += k * y[p];
        }
      }
      var sxx = 0.0, syy = 0.0, sxy = 0.0;
      for (var i = 0; i < size; i++) {
        for (var j = 0; j < size; j++) {
          final k = w[i * size + j], p = (top + i) * width + left + j;
          final dx = x[p] - mx, dy = y[p] - my;
          sxx += k * dx * dx;
          syy += k * dy * dy;
          sxy += k * dx * dy;
        }
      }
      total +=
          ((2 * mx * my + c1) * (2 * sxy + c2)) /
          ((mx * mx + my * my + c1) * (sxx + syy + c2));
      count++;
    }
  }
  return total / count;
}
