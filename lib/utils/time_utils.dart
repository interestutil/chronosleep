// lib/utils/time_utils.dart

class TimeUtils {
  /// Convert DateTime to hours since midnight
  static double toHoursSinceMidnight(DateTime dt) {
    return dt.hour + dt.minute / 60.0 + dt.second / 3600.0;
  }
  
  /// Determine if time is in morning (4-10 AM)
  static bool isMorning(DateTime dt) {
    final hour = dt.hour;
    return hour >= 4 && hour < 10;
  }
  
  /// Determine if time is in evening (7 PM - 1 AM)
  static bool isEvening(DateTime dt) {
    final hour = dt.hour;
    return hour >= 19 || hour < 1;
  }
  
  /// Determine if time is midday (10 AM - 5 PM)
  static bool isMidday(DateTime dt) {
    final hour = dt.hour;
    return hour >= 10 && hour < 17;
  }
  
  /// Get time category for PRC
  static String getTimeCategory(DateTime dt) {
    if (isMorning(dt)) return 'morning';
    if (isEvening(dt)) return 'evening';
    if (isMidday(dt)) return 'midday';
    return 'night';
  }
  
  /// Calculate duration in hours between two timestamps
  static double durationInHours(DateTime start, DateTime end) {
    return end.difference(start).inSeconds / 3600.0;
  }
}