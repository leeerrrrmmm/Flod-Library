import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';

extension DefaultExtension<T> on Validator<T> {
  /// Zod-compatible default when input is missing/`null`.
  ///
  /// **Mutable defaults:** `List` / `Map` values are shallow-cloned on each
  /// parse so mutations do not leak across calls. For nested mutables prefer
  /// [withDefaultFactory]:
  /// ```dart
  /// Flod.list(schema: Flod.string()).withDefaultFactory(() => <String>[]);
  /// ```
  DefaultDecorator<T> withDefault(T value) =>
      DefaultDecorator.value(this, value);

  /// Factory default — [create] runs on every missing/`null` input.
  ///
  /// Use this for nested mutable structures you fully control:
  /// ```dart
  /// Flod.object({...}).withDefaultFactory(() => {'tags': <String>[]});
  /// ```
  DefaultDecorator<T> withDefaultFactory(T Function() create) =>
      DefaultDecorator.factory(this, create);

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

  /// Async parse — required for schemas with [refineAsync] / [superRefineAsync]
  /// / [LazyValidator] wrapping async inners.
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
