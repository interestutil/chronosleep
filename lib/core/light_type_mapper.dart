import '../utils/constants.dart';

class LightTypeMapper {

  /// Categories:
  /// - < 3000K: Warm LED (2700K)
  /// - 3000-4500K: Neutral LED (4000K)
  /// - 4500-6000K: Cool LED (5000K)
  /// - >= 6000K: Daylight (6500K)
  static String cctToLightType(double kelvin) {
    if (kelvin < 3000) {
      return 'warm_led_2700k';
    } else if (kelvin < 4500) {
      return 'neutral_led_4000k';
    } else if (kelvin < 6000) {
      return 'cool_led_5000k';
    } else {
      return 'daylight_6500k';
    }
  }
  
  static double getMelanopicRatio(String lightType) {
    return CircadianConstants.melanopicRatios[lightType] ?? 0.6;
  }
  
  static String getLightTypeName(String lightType) {
    final names = {
      'warm_led_2700k': 'Warm LED (2700K)',
      'neutral_led_4000k': 'Neutral LED (4000K)',
      'cool_led_5000k': 'Cool LED (5000K)',
      'daylight_6500k': 'Daylight (6500K)',
      'phone_screen': 'Phone Screen',
      'incandescent': 'Incandescent',
    };
    return names[lightType] ?? lightType;
  }
  
  static double calculateConfidence({
    required double duv,
    required double kelvin,
  }) {
    double confidence = 1.0;
    
    if (duv < 0.02) {
      confidence = 0.95; // Excellent 
    } else if (duv < 0.05) {
      confidence = 0.80; // Good 
    } else if (duv < 0.10) {
      confidence = 0.60; // Fair 
    } else {
      confidence = 0.40; // Poor 
    }
    
    
    if (kelvin < 2500 || kelvin > 10000) {
      confidence *= 0.8; 
    }
    
    return confidence.clamp(0.0, 1.0);
  }
}