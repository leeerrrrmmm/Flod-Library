import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class DefaultDecorator<T> extends Validator<T> with Transformable<T> {
  final Validator<T> _inner;
  final T Function() _factory;

  /// Inner validator for [ValidatorCompiler].
  Validator<T> get inner => _inner;

  /// Produces a fresh default for this parse (may allocate).
  T Function() get factory => _factory;

  /// Snapshot of one factory invocation — useful for compilers / debugging.
  /// Prefer [factory] when applying defaults at parse time.
  T get defaultValue => _factory();

  @override
  final List<Transformer<T>> transformers;

  DefaultDecorator(
    this._inner,
    this._factory, {
    this.transformers = const [],
    super.isSecret = false,
  });

  /// Constant / immutable default (safe for `0`, `'guest'`, etc.).
  ///
  /// For mutable values (`List`, `Map`), prefer [DefaultDecorator.factory]
  /// or pass a value that will be shallow-cloned on each use (see
  /// [DefaultExtension.withDefault]).
  factory DefaultDecorator.value(
    Validator<T> inner,
    T value, {
    List<Transformer<T>> transformers = const [],
    bool isSecret = false,
  }) {
    return DefaultDecorator<T>(
      inner,
      () => _cloneIfMutable(value),
      transformers: transformers,
      isSecret: isSecret,
    );
  }

  /// Factory default — called on every missing/`null` input.
  factory DefaultDecorator.factory(
    Validator<T> inner,
    T Function() create, {
    List<Transformer<T>> transformers = const [],
    bool isSecret = false,
  }) {
    return DefaultDecorator<T>(
      inner,
      create,
      transformers: transformers,
      isSecret: isSecret,
    );
  }

  @override
  bool get isPure => _inner.isPure && transformers.isEmpty && !isSecret;

  @override
  DefaultDecorator<T> secret() {
    return DefaultDecorator<T>(
      _inner.secret(),
      _factory,
      transformers: transformers,
      isSecret: true,
    );
  }

  DefaultDecorator<T> copyWith({
    Validator<T>? inner,
    T Function()? factory,
    List<Transformer<T>>? transformers,
    bool? isSecret,
  }) {
    return DefaultDecorator<T>(
      inner ?? _inner,
      factory ?? _factory,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    final dynamic transformed = applyTransforms(value, path);

    if (transformed == null) {
      return FlodSuccess(_factory());
    }

    return _inner.validate(transformed, path: path, abortEarly: abortEarly);
  }

  /// Shallow-clones [List]/[Map] so `withDefault([])` is not shared across parses.
  static T _cloneIfMutable<T>(T value) {
    // Preserve runtime type args — bare `Map.from` becomes Map<dynamic,dynamic>.
    if (value is List) {
      return value.toList() as T;
    }
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value) as T;
    }
    if (value is Map) {
      return Map.from(value) as T;
    }
    return value;
  }
}
