import 'package:flod/flod.dart';

class FlodError {
  /// Path to the field where the error occurred
  final FlodPath path;

  /// String i18n error code (e.g. 'string.min')
  final String code;

  /// Dynamic rule parameters (e.g. {'limit': 5})
  final Map<String, dynamic> params;

  /// Raw value that failed validation (internal field)
  final dynamic _rawValue;

  /// Data confidentiality flag
  final bool isSecret;

  const FlodError({
    required this.path,
    required this.code,
    required this.params,
    required dynamic value,
    this.isSecret = false,
  }) : _rawValue = value;

  /// Safe getter for the value.
  /// If the field is marked secret, it is strictly masked for external consumers.
  dynamic get value => isSecret ? '[HIDDEN]' : _rawValue;

  /// Helper to access the real value inside the library
  /// (if needed for internal non-log computations)
  dynamic get rawValue => _rawValue;

  /// Serializes to Map with automatic masking of private data
  Map<String, dynamic> toMap() {
    return {
      'path': path
          .toString(), // Or path.segments, depending on FlodPath implementation
      'code': code,
      'params': params,
      'value': value, // Uses the safe getter with masking!
    };
  }

  @override
  String toString() {
    final pathStr = path.toString().isEmpty ? '_root_' : path.toString();
    // Fully prevent raw value leakage when isSecret = true
    final displayValue = value;
    return "FlodError(path: '$pathStr', code: '$code', params: $params, value: $displayValue)";
  }
}
