import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class NullableValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  @override
  final List<Transformer<T?>> transformers;

  // Const constructor to preserve immutability of the entire schema tree
  const NullableValidator(
    this._inner, {
    this.transformers = const [],
    super.isSecret = false,
  });

  /// Inner validator wrapped by this nullable layer.
  Validator<T> get inner => _inner;

  @override
  NullableValidator<T> secret() => copyWith(isSecret: true);

  // transform removed here to avoid breaking Validator<T> base class polymorphism.
  // .transform<R>() is now inherited from above and can change data types.

  // Updated copyWith that correctly preserves and forwards transformers
  NullableValidator<T> copyWith({
    Validator<T>? inner,
    List<Transformer<T?>>? transformers,
    bool? isSecret,
  }) {
    return NullableValidator<T>(
      inner ?? _inner,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T?> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    // 1. EXECUTION ORDER (5.3): Apply Nullable-level transforms first
    final dynamic transformed = applyTransforms(value, path);

    // 2. Nullability logic — if value is null, exit chain with success
    if (transformed == null) {
      return FlodSuccess<T?>(null);
    }

    // 3. Delegate to inner validator for type and rule checks
    final result = _inner.validate(
      transformed,
      path: path,
      abortEarly: abortEarly,
    );

    if (result is FlodFailure) {
      // Error obfuscation: if wrapper is secret, wipe raw data from logs
      if (isSecret) {
        final obfuscatedErrors = (result as FlodFailure<T?>).errors
            .map(
              (e) => FlodError(
                path: e.path,
                code: e.code,
                params: e.params,
                message: e.message,
                value: null,
                isSecret: true,
              ),
            )
            .toList();
        return FlodFailure(obfuscatedErrors);
      }

      return FlodFailure<T?>((result as FlodFailure<T?>).errors);
    }

    // Safe data extraction via .data getter
    return FlodSuccess<T?>((result as FlodSuccess<T?>).data);
  }
}

extension NullableExtension<T> on Validator<T> {
  /// Makes the validator nullable, allowing null values
  NullableValidator<T> nullable() => NullableValidator<T>(this);
}
