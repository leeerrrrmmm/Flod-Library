import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

abstract class Validator<T> {
  ValidationResult<T> validate(dynamic value, {Path path = const []});
}
