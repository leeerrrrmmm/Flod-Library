import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';
import 'package:flod/src/validators/exception_validator/validator_exception.dart';

extension DefaultExtension<T> on Validator<T> {
  DefaultDecorator<T> defaultValue(T value) => DefaultDecorator<T>(this, value);

  /// Zod-compatible alias for [defaultValue].
  DefaultDecorator<T> withDefault(T value) => defaultValue(value);
}

extension ValidatorExtensions<T> on Validator<T> {
  ParseResult<T> safeParse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      return FlodFailure<T>(result.errors);
    }
    return FlodSuccess<T>((result as FlodSuccess<T>).data);
  }

  T parse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      throw ValidationException(result.errors);
    }
    return (result as FlodSuccess<T>).data;
  }
}

extension PathExtensions on List {
  List append(dynamic segment) => [...this, segment];
}

extension PathConversion on List<Object> {
  FlodPath toFlodPath() => FlodPath(this);
  String toReadable() => toFlodPath().toReadable();
}
