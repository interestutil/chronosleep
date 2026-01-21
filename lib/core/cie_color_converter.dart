import 'dart:math';
import 'cie_color_space.dart';

class ColorConverter {
  //* this is the standerd values
  static const List<List<double>> _sRGBToXYZMatrix = [
    [0.4124564, 0.3575761, 0.1804375],
    [0.2126729, 0.7151522, 0.0721750],
    [0.0193339, 0.1191920, 0.9503041],
  ];
  //! static values
  static double gammaCorrection(double value) {
    if (value <= 0.0) return 0.0;
    if (value >= 1.0) return 1.0;

    //* sRGB gamma correction
    if (value <= 0.04045) {
      return value / 12.92;
    } else {
      return pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  static double inverseGammaCorrection(double value) {
    if (value <= 0.0) return 0.0;
    if (value >= 1.0) return 1.0;

    if (value <= 0.0031308) {
      return 12.92 * value;
    } else {
      return 1.055 * pow(value, 1.0 / 2.4).toDouble() - 0.055;
    }
  }

  //* Convert sRGB (0-1) to linear RGB
  static RGB linearizeRGB(RGB srgb) {
    return RGB(
      r: gammaCorrection(srgb.r),
      g: gammaCorrection(srgb.g),
      b: gammaCorrection(srgb.b),
    );
  }

  //* Convert linear RGB to CIE XYZ using sRGB color matrix
  static XYZ rgbToXYZ(RGB linearRGB) {
    if (!linearRGB.isValid) {
      throw ArgumentError('Invalid RGB values: $linearRGB');
    }

    final r = linearRGB.r;
    final g = linearRGB.g;
    final b = linearRGB.b;

    //! Matrix multiplication
    final x = _sRGBToXYZMatrix[0][0] * r +
        _sRGBToXYZMatrix[0][1] * g +
        _sRGBToXYZMatrix[0][2] * b;

    final y = _sRGBToXYZMatrix[1][0] * r +
        _sRGBToXYZMatrix[1][1] * g +
        _sRGBToXYZMatrix[1][2] * b;

    final z = _sRGBToXYZMatrix[2][0] * r +
        _sRGBToXYZMatrix[2][1] * g +
        _sRGBToXYZMatrix[2][2] * b;

    return XYZ(x: x, y: y, z: z);
  }

  //* Convert CIE XYZ to xy chromaticity coordinates
  static CIE_Chromaticity xyzToChromaticity(XYZ xyz) {
    if (!xyz.isValid) {
      throw ArgumentError('Invalid XYZ values: $xyz');
    }

    final sum = xyz.x + xyz.y + xyz.z;

    if (sum == 0 || !sum.isFinite) {
      return const CIE_Chromaticity(x: 0.3127, y: 0.3290);
    }

    final x = xyz.x / sum;
    final y = xyz.y / sum;

    return CIE_Chromaticity(x: x, y: y);
  }

  static CIE_Chromaticity rgbToChromaticity(RGB srgb) {
    final linearRGB = linearizeRGB(srgb);
    final xyz = rgbToXYZ(linearRGB);
    return xyzToChromaticity(xyz);
  }
}
