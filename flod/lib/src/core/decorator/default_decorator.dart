import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class DefaultDecorator<T> extends Validator<T> with Transformable<T> {
  final Validator<T> _inner;
  final T defaultValue;

  /// Inner validator for [ValidatorCompiler].
  Validator<T> get inner => _inner;

  @override
  final List<Transformer<T>> transformers;

  const DefaultDecorator(
    this._inner,
    this.defaultValue, {
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  bool get isPure => _inner.isPure && transformers.isEmpty && !isSecret;

  @override
  DefaultDecorator<T> secret() {
    return DefaultDecorator<T>(
      _inner.secret(),
      defaultValue,
      transformers: transformers,
      isSecret: true,
    );
  }

  DefaultDecorator<T> copyWith({
    Validator<T>? inner,
    T? defaultValue,
    List<Transformer<T>>? transformers,
    bool? isSecret,
  }) {
    return DefaultDecorator<T>(
      inner ?? _inner,
      defaultValue ?? this.defaultValue,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T> validate(dynamic value, {FlodPath path = const FlodPath([]), bool? abortEarly}) {
    final dynamic transformed = applyTransforms(value, path);

    // Если значение отсутствует (null), возвращаем дефолт
    if (transformed == null) {
      return FlodSuccess(defaultValue);
    }

    // Иначе идем вглубь
    final result = _inner.validate(transformed, path: path, abortEarly: abortEarly);
    return result;
  }
}
