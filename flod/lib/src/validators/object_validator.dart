import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/optional_validator.dart';
import 'package:flod/src/validators/validator.dart';

class ObjectValidator implements Validator<Map<String, dynamic>> {
  final Map<String, Validator> schema;

  const ObjectValidator(this.schema);

  @override
  ValidationResult<Map<String, dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    final errors = <FlodError>[];

    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (value.containsKey(key)) {
        final fieldValue = value[key];
        final result = validator.validate(fieldValue, path: [...path, key]);

        if (result is FlodFailure) {
          errors.addAll(result.errors);
        }
      } else if (validator is! OptionalValidator) {
        errors.add(FlodError([...path, key], 'required', 'Field is required'));
      }
    }

    return errors.isEmpty ? FlodSuccess(value) : FlodFailure(errors);
  }
}
