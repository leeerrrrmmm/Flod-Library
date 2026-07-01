import 'package:flod/flod.dart';
import 'package:flod/src/validators/transform_validator/transform_validator.dart';

abstract class Validator<T> {
  final bool isSecret;
  const Validator({this.isSecret = false});

  Validator<T> secret();
  Validator<T> strict() => this;
  Validator<T> stopOnFirstError() => this;

  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  });

  Validator<R> transform<R>(R Function(T value) cb) {
    return TransformValidator<T, R>(this, cb);
  }

  Validator? getFieldSchema(String key) => null;
}
