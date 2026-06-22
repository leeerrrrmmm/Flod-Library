// lib/src/validators/optional_validator.dart
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

class OptionalValidator<T> extends Validator<T> with Transformable<T> {
  final Validator<T> _inner;

  OptionalValidator(this._inner);

  @override
  ValidationResult<T> validate(dynamic value, {Path path = const []}) {
    if (value == null) {
      return FlodSuccess(applyTransforms(value) as T);
    }
    return _inner.validate(applyTransforms(value), path: path);
  }
}

extension OptionalExtension<T> on Validator<T> {
  OptionalValidator optional() => OptionalValidator(this);
}
