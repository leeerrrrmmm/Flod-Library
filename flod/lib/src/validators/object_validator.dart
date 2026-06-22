// lib/src/validators/object_validator.dart
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/optional_validator.dart';

enum ObjectMode { strict, passthrough }

class ObjectValidator extends Validator<Map<String, dynamic>>
    with Transformable<Map<String, dynamic>> {
  final Map<String, Validator> schema;
  final ObjectMode mode;

  ObjectValidator(this.schema, {this.mode = ObjectMode.passthrough});

  ObjectValidator strict() => ObjectValidator(schema, mode: ObjectMode.strict);
  ObjectValidator passthrough() =>
      ObjectValidator(schema, mode: ObjectMode.passthrough);

  @override
  ValidationResult<Map<String, dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! Map<String, dynamic>) {
      return FlodFailure([FlodError(path, 'Expected object', 'invalid_type')]);
    }

    final errors = <FlodError>[];

    // 1. Strict Mode
    if (mode == ObjectMode.strict) {
      for (final key in transformed.keys) {
        if (!schema.containsKey(key)) {
          errors.add(FlodError([...path, key], 'Unknown key', 'strict_mode'));
        }
      }
    }

    // 2. Валидация
    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (transformed.containsKey(key)) {
        final fieldValue = transformed[key];
        final result = validator.validate(fieldValue, path: [...path, key]);

        // Используем твой новый API ValidationResult
        if (result.isFailure) {
          errors.addAll(result.errors);
        }
      } else if (validator is! OptionalValidator) {
        errors.add(FlodError([...path, key], 'Field is required', 'required'));
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
