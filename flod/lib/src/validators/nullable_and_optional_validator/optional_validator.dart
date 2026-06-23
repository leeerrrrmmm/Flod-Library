import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

// ИСПРАВЛЕНИЕ: Наследуемся от Validator<T?> и подмешиваем Transformable<T?>
class OptionalValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  OptionalValidator(this._inner, {super.isSecret});

  @override
  OptionalValidator<T> secret() => copyWith(isSecret: true);

  OptionalValidator<T> copyWith({Validator<T>? inner, bool? isSecret}) {
    return OptionalValidator<T>(
      inner ?? _inner,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  // ИСПРАВЛЕНИЕ: Возвращаем ValidationResult<T?>
  @override
  ValidationResult<T?> validate(dynamic value, {Path path = const []}) {
    final dynamic transformed = applyTransforms(value);

    if (transformed == null) {
      return FlodSuccess(null); // Теперь этот вызов абсолютно легален!
    }

    final result = _inner.validate(transformed, path: path);

    if (result.isFailure) {
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

extension OptionalExtension<T> on Validator<T> {
  // ИСПРАВЛЕНИЕ: Возвращаем OptionalValidator<T>, который работает с T?
  OptionalValidator<T> optional() => OptionalValidator<T>(this);
}
