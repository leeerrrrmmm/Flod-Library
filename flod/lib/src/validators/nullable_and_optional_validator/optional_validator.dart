import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class OptionalValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  @override
  final List<Transformer<T?>> transformers;

  const OptionalValidator(
    this._inner, {
    this.transformers = const [],
    super.isSecret = false,
  });

  /// Inner validator wrapped by this optional layer.
  Validator<T> get inner => _inner;

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
  ParseResult<T?> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    // 1. EXECUTION ORDER: Применяем трансформации уровня Optional
    final dynamic transformed = applyTransforms(value, path);

    // 2. Если значение null — успешный выход
    if (transformed == null) {
      return FlodSuccess<T?>(null);
    }

    // 3. Делегируем глубокую валидацию и внутренние трансформации дочернему валидатору
    final result = _inner.validate(
      transformed,
      path: path,
      abortEarly: abortEarly,
    );

    if (result is FlodFailure) {
      if (isSecret) {
        final obfuscatedErrors = (result as FlodFailure<T?>).errors
            .map(
              (e) => FlodError(
                path: e.path,
                code: e.code,
                params: e.params,
                value: null,
                isSecret: true,
              ),
            )
            .toList();
        return FlodFailure(obfuscatedErrors);
      }

      return FlodFailure<T?>((result as FlodFailure<T?>).errors);
    }

    // Безопасно вытаскиваем данные из FlodSuccess
    return FlodSuccess<T?>((result as FlodSuccess<T?>).data);
  }
}

extension OptionalExtension<T> on Validator<T> {
  OptionalValidator<T> optional() => OptionalValidator<T>(this);
}
