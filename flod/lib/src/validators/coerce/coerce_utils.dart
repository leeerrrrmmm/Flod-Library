/// Shared coercion helpers for [Flod.coerce].
abstract final class CoerceUtils {
  /// `String` / `num` / `bool` → `int`. Returns `null` if coercion is impossible.
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  /// `String` / `num` / `bool` / `int` → `double`. Returns `null` if impossible.
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  /// Common truthy/falsy strings and nums → `bool`. Returns `null` if impossible.
  static bool? toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) {
      if (value == 1 || value == 1.0) return true;
      if (value == 0 || value == 0.0) return false;
      return null;
    }
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
        default:
          return null;
      }
    }
    return null;
  }

  /// Any non-null value → `String` via [Object.toString] (trimmed for String).
  static String? toStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
