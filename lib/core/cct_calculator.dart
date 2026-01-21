import 'dart:math';
import 'cie_color_space.dart';

class CCT_Calc {
  static double CCT_CalculatingHernandez(CIE_Chromaticity xy) {
    if (!xy.isValid) {
      throw ArgumentError('Invalid xy coordinates: $xy');
    }

    const xe = 0.3320;
    const ye = 0.1858;

    final denominator = xy.y - ye;

    if (denominator == 0 || !denominator.isFinite) {
      return 4000.0;
    }

    final n = (xy.x - xe) / denominator;

    if (!n.isFinite || n.isNaN) {
      return 4000.0;
    }

    //* Hernández-Andrés formula
    final cct = 449 * pow(n, 3) + 3525 * pow(n, 2) + 6823.3 * n + 5520.33;

    return cct.clamp(2000.0, 20000.0);
  }

  static double calculateDUV(CIE_Chromaticity xy) {
    return xy.distanceFromD65() * 0.1; 
  }

  static double chromaticityToCCT(CIE_Chromaticity xy) {   
      return CCT_CalculatingHernandez(xy);    
  }
}
