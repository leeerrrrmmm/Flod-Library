import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/nullable_and_optional_validator/optional_validator.dart';

enum ObjectMode { strict, passthrough }

class ObjectValidator extends Validator<Map<String, dynamic>>
    with Transformable<Map<String, dynamic>> {
  final Map<String, Validator> schema;
  final ObjectMode mode;

  @override
  final List<Transformer<Map<String, dynamic>>> transformers;

  const ObjectValidator(
    this.schema, {
    this.mode = ObjectMode.passthrough,
    this.transformers = const [],
    super.isSecret = false,
  });

  // Прямо возвращаем значение из schema для поддержки быстрого O(1) роутинга
  @override
  Validator? getFieldSchema(String key) => schema[key];

  @override
  ObjectValidator secret() => copyWith(isSecret: true);

  ObjectValidator strict() => copyWith(mode: ObjectMode.strict);
  ObjectValidator passthrough() => copyWith(mode: ObjectMode.passthrough);

  ObjectValidator copyWith({
    Map<String, Validator>? schema,
    ObjectMode? mode,
    List<Transformer<Map<String, dynamic>>>? transformers,
    bool? isSecret,
  }) {
    return ObjectValidator(
      schema ?? this.schema,
      mode: mode ?? this.mode,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ValidationResult<Map<String, dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    if (value is! Map<String, dynamic>) {
      return FlodFailure([
        FlodError(
          path,
          'Expected object',
          'invalid_type',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    final dynamic rawTransformed = applyTransforms(value);
    final Map<String, dynamic> transformed = Map<String, dynamic>.from(
      rawTransformed,
    );

    final Map<String, dynamic> outputResult = {};
    final errors = <FlodError>[];

    if (mode == ObjectMode.strict) {
      for (final key in transformed.keys) {
        if (!schema.containsKey(key)) {
          errors.add(
            FlodError(
              [...path, key],
              'Unknown key',
              'strict_mode',
              value: transformed[key],
              isSecret: isSecret,
            ),
          );
        }
      }
    }

    if (mode == ObjectMode.passthrough) {
      transformed.forEach((key, val) {
        if (!schema.containsKey(key)) {
          outputResult[key] = val;
        }
      });
    }

    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (transformed.containsKey(key)) {
        final fieldValue = transformed[key];
        final result = validator.validate(fieldValue, path: [...path, key]);

        if (result is FlodSuccess) {
          outputResult[key] = result.data;
        } else if (result is FlodFailure) {
          if (isSecret) {
            final obfuscatedErrors = result.errors
                .map(
                  (e) => FlodError(
                    e.path,
                    e.message,
                    e.code,
                    value: null,
                    isSecret: true,
                  ),
                )
                .toList();
            errors.addAll(obfuscatedErrors);
          } else {
            errors.addAll(result.errors);
          }
        }
      } else if (validator is! OptionalValidator) {
        errors.add(
          FlodError(
            [...path, key],
            'Field is required',
            'required',
            value: null,
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty ? FlodSuccess(outputResult) : FlodFailure(errors);
  }
}
