import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';
import 'package:flod/src/validators/exception_validator/validator_exception.dart';

extension DefaultExtension<T> on Validator<T> {
  /// Zod-compatible default value (Dart keyword prevents `.default()`).
  DefaultDecorator<T> withDefault(T value) => DefaultDecorator<T>(this, value);

  /// Deprecated — use [withDefault].
  @Deprecated('Use withDefault() instead.')
  DefaultDecorator<T> defaultValue(T value) => withDefault(value);
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

  /// Async parse — required for schemas with [refineAsync] / [superRefineAsync].
  Future<ParseResult<T>> safeParseAsync(dynamic value) async {
    if (this is AsyncValidator<T>) {
      return (this as AsyncValidator<T>).validateAsync(value);
    }
    return safeParse(value);
  }

  Future<T> parseAsync(dynamic value) async {
    final result = await safeParseAsync(value);
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
