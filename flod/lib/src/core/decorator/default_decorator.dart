import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class DefaultDecorator<T> extends Validator<T> with Transformable<T> {
  final Validator<T> _inner;
  final T defaultValue;

  @override
  final List<Transformer<T>> transformers;

  const DefaultDecorator(
    this._inner,
    this.defaultValue, {
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  DefaultDecorator<T> secret() => copyWith(isSecret: true);

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
  ValidationResult<T> validate(dynamic value, {Path path = const []}) {
    final dynamic transformed = applyTransforms(value);

    // Если значение отсутствует (null), возвращаем дефолт
    if (transformed == null) {
      return FlodSuccess(defaultValue);
    }

    // Иначе идем вглубь
    final result = _inner.validate(transformed, path: path);
    return result;
  }
}
