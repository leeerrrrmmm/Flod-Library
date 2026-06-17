import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/validator.dart';

class NullableValidator<T> implements Validator<T?> {
  final Validator<T> _inner;

  NullableValidator(this._inner);

  @override
  ValidationResult<T?> validate(dynamic value, {Path path = const []}) {
    if (value == null) {
      return FlodSuccess(null);
    }
    return _inner.validate(value, path: path);
  }
}

extension NullableExtension<T> on Validator<T> {
  NullableValidator nullable() => NullableValidator(this);
}
