import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

class OptionalValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  @override
  final List<Transformer<T?>> transformers;

  const OptionalValidator(
    this._inner, {
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  OptionalValidator<T> secret() => copyWith(isSecret: true);

  OptionalValidator<T> copyWith({
    Validator<T>? inner,
    List<Transformer<T?>>? transformers,
    bool? isSecret,
  }) {
    return OptionalValidator<T>(
      inner ?? _inner,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ValidationResult<T?> validate(dynamic value, {Path path = const []}) {
    // 1. EXECUTION ORDER: Применяем трансформации уровня Optional
    final dynamic transformed = applyTransforms(value);

    // 2. Если значение null — успешный выход
    if (transformed == null) {
      return FlodSuccess(null);
    }

    // 3. Делегируем глубокую валидацию и внутренние трансформации дочернему валидатору
    final result = _inner.validate(transformed, path: path);

    if (result is FlodFailure) {
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

    // Безопасно вытаскиваем данные из FlodSuccess
    return FlodSuccess(result.data);
  }
}

extension OptionalExtension<T> on Validator<T> {
  OptionalValidator<T> optional() => OptionalValidator<T>(this);
}
