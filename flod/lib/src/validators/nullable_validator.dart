import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

class NullableValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  NullableValidator(this._inner);

  @override
  ValidationResult<T?> validate(dynamic value, {Path path = const []}) {
    // 1. Применяем трансформации (из Mixin)
    final dynamic transformed = applyTransforms(value);

    // 2. Логика nullability
    if (transformed == null) {
      return FlodSuccess(null);
    }

    final result = _inner.validate(transformed, path: path);

    if (result.isFailure) {
      return FlodFailure(result.errors);
    }

    // Теперь это выглядит очень чисто:
    return FlodSuccess(result.data);
  }
}

extension NullableExtension<T> on Validator<T> {
  NullableValidator nullable() => NullableValidator(this);
}

