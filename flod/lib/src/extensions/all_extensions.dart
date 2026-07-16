import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';

extension DefaultExtension<T> on Validator<T> {
  /// Zod-compatible default value (Dart keyword prevents `.default()`).
  DefaultDecorator<T> withDefault(T value) => DefaultDecorator<T>(this, value);

  /// Deprecated — use [withDefault].
  @Deprecated('Use withDefault() instead.')
  DefaultDecorator<T> defaultValue(T value) => withDefault(value);
}

extension ValidatorExtensions<T> on Validator<T> {
  /// Validates [value] without throwing.
  ///
  /// When [abortEarly] is `true`, stops after the first error (faster invalid
  /// paths). Prefer [Validator.stopOnFirstError] to bake this into the schema.
  ParseResult<T> safeParse(dynamic value, {bool? abortEarly}) {
    final result = validate(value, abortEarly: abortEarly);
    if (result is FlodFailure<T>) {
      return FlodFailure<T>(result.errors);
    }
    return FlodSuccess<T>((result as FlodSuccess<T>).data);
  }

  /// Validates [value] and returns data, or throws [ValidationException].
  ///
  /// See [safeParse] for [abortEarly] semantics.
  T parse(dynamic value, {bool? abortEarly}) {
    final result = validate(value, abortEarly: abortEarly);
    if (result is FlodFailure<T>) {
      throw ValidationException(result.errors);
    }
    return (result as FlodSuccess<T>).data;
  }

  /// Async parse — required for schemas with [refineAsync] / [superRefineAsync].
  Future<ParseResult<T>> safeParseAsync(
    dynamic value, {
    bool? abortEarly,
  }) async {
    if (this is AsyncValidator<T>) {
      return (this as AsyncValidator<T>).validateAsync(
        value,
        abortEarly: abortEarly,
      );
    }
    return safeParse(value, abortEarly: abortEarly);
  }

  Future<T> parseAsync(dynamic value, {bool? abortEarly}) async {
    final result = await safeParseAsync(value, abortEarly: abortEarly);
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
