import 'dart:math';

class XYZ {
  final double x;
  final double y;
  final double z;

  const XYZ({
    required this.x,
    required this.y,
    required this.z,
  });

  double get luminnace =>
      y; //* this to get the luminnace according to the physics law
  bool get isValid =>
      x.isFinite && y.isFinite && z.isFinite && x >= 0 && y >= 0 && z >= 0;
}
//________________________________________________________

class CIE_Chromaticity {
  //* this here to get the new data in 2D
  final double x;
  final double y;

  const CIE_Chromaticity({
    required this.x,
    required this.y,
  });
  double get z => 1 - x - y; //* to get the z
  bool get isValid {
    //! it has to be between 0 & 1 (look up the law)
    return x.isFinite &&
        y.isFinite &&
        x >= 0 &&
        x <= 1 &&
        y >= 0 &&
        y <= 1 &&
        (x + y) <= 1.0;
  }

  double distanceFromD65() {
    const D65X = 0.3127;
    const D65y = 0.3290;
    return sqrt(pow(x - D65X, 2) + pow(y - D65y, 2));
  }
  //! don't change
}
//________________________________________________________

class RGB {
  final double r;
  final double g;
  final double b;

  const RGB({
    required this.r,
    required this.g,
    required this.b,
  });
  bool get isValid =>
      r.isFinite &&
      g.isFinite &&
      b.isFinite &&
      r >= 0 &&
      r <= 1 &&
      g >= 0 &&
      g <= 1 &&
      b >= 0 &&
      b <= 1;
}
//________________________________________________________

