import 'package:flod/flod.dart';

/// Defers schema construction until the first validation (Zod `.lazy()`).
///
/// Enables recursive / mutually-recursive schemas:
/// ```dart
/// late final Validator<Map<String, dynamic>> category;
/// category = Flod.object({
///   'name': Flod.string(),
///   'children': Flod.list(schema: Flod.lazy(() => category)),
/// });
/// ```
///
/// The factory result is cached after the first resolve. [compile] leaves
/// lazy wrappers in place so recursive graphs do not stack-overflow.
class LazyValidator<T> extends Validator<T> implements AsyncValidator<T> {
  final Validator<T> Function() _schemaFactory;
  Validator<T>? _cached;

  LazyValidator(this._schemaFactory, {super.isSecret = false});

  /// Resolved inner schema (cached).
  Validator<T> get resolved {
    final existing = _cached;
    if (existing != null) return existing;
    final built = _schemaFactory();
    final effective = isSecret && !built.isSecret ? built.secret() : built;
    return _cached = effective;
  }

  @override
  bool get isPure => false;

  @override
  bool get isCompiled => false;

  @override
  LazyValidator<T> secret() {
    return LazyValidator<T>(
      () => _schemaFactory().secret(),
      isSecret: true,
    );
  }

  @override
  Validator<T> strict() => LazyValidator<T>(
    () => _schemaFactory().strict(),
    isSecret: isSecret,
  );

  @override
  Validator<T> stopOnFirstError() => LazyValidator<T>(
    () => _schemaFactory().stopOnFirstError(),
    isSecret: isSecret,
  );

  @override
  Validator? getFieldSchema(String key) => resolved.getFieldSchema(key);

  @override
  Validator<T> compile() {
    // Do not eagerly compile through the factory — recursive schemas would loop.
    return this;
  }

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    return resolved.validate(value, path: path, abortEarly: abortEarly);
  }

  @override
  Future<ParseResult<T>> validateAsync(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) async {
    final inner = resolved;
    if (inner is AsyncValidator<T>) {
      return (inner as AsyncValidator<T>).validateAsync(
        value,
        path: path,
        abortEarly: abortEarly,
      );
    }
    return inner.validate(value, path: path, abortEarly: abortEarly);
  }
}
