import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/transform_validator/transform_validator.dart';

abstract class Validator<T> {
  final bool isSecret;
  const Validator({this.isSecret = false});
  Validator<T> secret();
  ValidationResult<T> validate(dynamic value, {Path path = const []});
  Validator<R> transform<R>(R Function(T value) cb) {
    return TransformValidator<T, R>(this, cb);
  }

  Validator? getFieldSchema(String key) => null;
}
