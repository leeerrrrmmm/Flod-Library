import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

enum ObjectMode { strict, passthrough }

class ObjectValidator extends Validator<Map<String, dynamic>>
    with Transformable<Map<String, dynamic>> {
  final Map<String, Validator> schema;
  final ObjectMode mode;
  final bool abortEarly;

  @override
  final List<Transformer<Map<String, dynamic>>> transformers;

  const ObjectValidator(
    this.schema, {
    this.mode = ObjectMode.passthrough,
    this.transformers = const [],
    super.isSecret = false,
    this.abortEarly = false,
  });

  @override
  Validator? getFieldSchema(String key) => schema[key];

  @override
  ObjectValidator secret() => copyWith(isSecret: true);
  ObjectValidator strict() => copyWith(mode: ObjectMode.strict);
  ObjectValidator passthrough() => copyWith(mode: ObjectMode.passthrough);
  ObjectValidator stopOnFirstError() => copyWith(abortEarly: true);

  ObjectValidator copyWith({
    Map<String, Validator>? schema,
    ObjectMode? mode,
    List<Transformer<Map<String, dynamic>>>? transformers,
    bool? isSecret,
    bool? abortEarly,
  }) {
    return ObjectValidator(
      schema ?? this.schema,
      mode: mode ?? this.mode,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
      abortEarly: abortEarly ?? this.abortEarly,
    );
  }

  @override
  ValidationResult<Map<String, dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    if (value is! Map) {
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

    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (transformed.containsKey(key)) {
        // --- КЛЮЧ ПРИСУТСТВУЕТ: Обычная валидация ---
        final fieldValue = transformed[key];
        final result = validator.validate(fieldValue, path: [...path, key]);

        if (result is FlodSuccess) {
          outputResult[key] = result.data;
        } else if (result is FlodFailure) {
          final errorsToReport = isSecret
              ? result.errors
                    .map(
                      (e) => FlodError(
                        e.path,
                        e.message,
                        e.code,
                        value: null,
                        isSecret: true,
                      ),
                    )
                    .toList()
              : result.errors;
          errors.addAll(errorsToReport);

          if (abortEarly) break;
        }
      } else {
        // --- КЛЮЧА НЕТ: Функциональный опрос дочернего валидатора через null ---
        final result = validator.validate(null, path: [...path, key]);

        if (result is FlodSuccess) {
          // Если это был Default или Optional, мы берем результат.
          // Если значение null и поле просто опциональное, можно сохранить или опустить
          // (в Dart map['key'] все равно вернет null, но явная запись чище).
          outputResult[key] = result.data;
        } else {
          // Если валидатор вернул ошибку на null, значит поле обязательное и отсутствует!
          errors.add(
            FlodError(
              [...path, key],
              'Field is required',
              'required',
              value: null,
              isSecret: isSecret,
            ),
          );

          if (abortEarly) break;
        }
      }
    }

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

    return errors.isEmpty ? FlodSuccess(outputResult) : FlodFailure(errors);
  }
}
