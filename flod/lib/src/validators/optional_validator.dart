import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/validator.dart';

class OptionalValidator<T> implements Validator<T> {
  final Validator<T> _inner;

  OptionalValidator(this._inner);

  @override
  ValidationResult<T> validate(dynamic value, {Path path = const []}) =>
      _inner.validate(value, path: path);
}

extension OptionalExtension<T> on Validator<T> {
  OptionalValidator optional() => OptionalValidator(this);
}
