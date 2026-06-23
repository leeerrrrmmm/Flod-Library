import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart'; // Нужен для пересборки ошибок
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

class NullableValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  NullableValidator(this._inner, {super.isSecret});

  @override
  NullableValidator<T> secret() => copyWith(isSecret: true);

  NullableValidator<T> copyWith({Validator<T>? inner, bool? isSecret}) {
    return NullableValidator<T>(
      inner ?? _inner,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ValidationResult<T?> validate(dynamic value, {Path path = const []}) {
    // 1. Применяем трансформации
    final dynamic transformed = applyTransforms(value);

    // 2. Логика nullability
    if (transformed == null) {
      return FlodSuccess(null);
    }

    final result = _inner.validate(transformed, path: path);

    if (result.isFailure) {
      // Защита данных. Если обертка секретна, маскируем ошибки вложенного валидатора
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
        return FlodFailure(obfuscatedErrors);
      }

      return FlodFailure(result.errors);
    }

    return FlodSuccess(result.data);
  }
}

extension NullableExtension<T> on Validator<T> {
  NullableValidator<T> nullable() => NullableValidator<T>(this);
}
