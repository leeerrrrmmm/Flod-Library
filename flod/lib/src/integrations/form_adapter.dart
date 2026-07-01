import 'package:flod/flod.dart';

/// Bridges [FlodFailure.getFieldsMap] to form-style field validation.
///
/// Pure Dart — no Flutter dependency. Wire [fieldValidator] into
/// `TextFormField.validator` or bind [validate] to your form state.
class FlodFormAdapter {
  const FlodFormAdapter(this.schema);

  final Validator<Map<String, dynamic>> schema;

  /// Validates [values] and returns the first error message per field path.
  Map<String, String> validate(Map<String, dynamic> values) {
    return _failureOrEmpty(values).getFieldsMap();
  }

  /// Validates [values] and returns all error messages grouped by field path.
  Map<String, List<String>> validateGrouped(Map<String, dynamic> values) {
    return _failureOrEmpty(values).getGroupedFieldsMap();
  }

  /// Returns the first error message for [fieldPath], or `null` if valid.
  String? errorFor(String fieldPath, Map<String, dynamic> values) {
    return validate(values)[fieldPath];
  }

  /// Builds a single-field validator for Flutter `TextFormField.validator`.
  ///
  /// [readValues] should return the current full form snapshot so cross-field
  /// rules (e.g. password confirmation) can run correctly.
  String? Function(String?) fieldValidator(
    String fieldPath,
    Map<String, dynamic> Function() readValues,
  ) {
    return (_) => errorFor(fieldPath, readValues());
  }

  FlodFailure<Map<String, dynamic>> _failureOrEmpty(
    Map<String, dynamic> values,
  ) {
    final result = schema.safeParse(values);
    if (result is FlodFailure<Map<String, dynamic>>) {
      return result;
    }
    return const FlodFailure([]);
  }
}
