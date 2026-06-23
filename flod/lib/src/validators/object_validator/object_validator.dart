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

  // Конструктор принимает super.isSecret и передает его наверх
  ObjectValidator(
    this.schema, {
    this.mode = ObjectMode.passthrough,
    super.isSecret,
  });

  // Контракт Fluent API с правильной типизацией
  @override
  ObjectValidator secret() => copyWith(isSecret: true);

  // Добавляем copyWith для сохранения всех флагов при чейнинге
  ObjectValidator copyWith({
    Map<String, Validator>? schema,
    ObjectMode? mode,
    bool? isSecret,
  }) {
    return ObjectValidator(
      schema ?? this.schema,
      mode: mode ?? this.mode,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  ObjectValidator strict() => copyWith(mode: ObjectMode.strict);
  ObjectValidator passthrough() => copyWith(mode: ObjectMode.passthrough);

  @override
  ValidationResult<Map<String, dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! Map<String, dynamic>) {
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

    final errors = <FlodError>[];

    // 1. Strict Mode
    if (mode == ObjectMode.strict) {
      for (final key in transformed.keys) {
        if (!schema.containsKey(key)) {
          errors.add(
            FlodError(
              [...path, key],
              'Unknown key',
              'strict_mode',
              value: transformed[key],
              isSecret:
                  isSecret, // Скрываем значение лишнего ключа, если объект секретный
            ),
          );
        }
      }
    }

    // 2. Валидация полей
    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;

      if (transformed.containsKey(key)) {
        final fieldValue = transformed[key];
        final result = validator.validate(fieldValue, path: [...path, key]);

        if (result.isFailure) {
          // Если весь объект секретный, принудительно обфусцируем ошибки вложенных полей
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

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
