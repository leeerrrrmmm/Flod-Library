import 'package:flod/src/res/parse_result.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/validator_exception.dart';

abstract class Validator<T> {
  ValidationResult<T> validate(dynamic value, {Path path = const []});
}

extension ValidatorExtensions<T> on Validator<T> {
  T parse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      throw ValidationException(result.errors);
    }
    return value;
  }

  ParseResult<T> safeParse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      return ParseResult.failure(result.errors);
    }
    return ParseResult.success(value);
  }
}
