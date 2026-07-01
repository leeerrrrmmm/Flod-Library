import 'package:flod/flod.dart';

/// Sync super-refine layer — multiple custom issues via [SuperRefineContext].
class SuperRefineValidator<T> extends Validator<T> {
  final Validator<T> _inner;
  final void Function(T value, SuperRefineContext ctx) _callback;

  Validator<T> get inner => _inner;

  @override
  bool get isCompiled => _inner.isCompiled;

  void Function(T value, SuperRefineContext ctx) get callback => _callback;

  SuperRefineValidator(this._inner, this._callback, {super.isSecret = false});

  @override
  Validator? getFieldSchema(String key) => _inner.getFieldSchema(key);

  @override
  SuperRefineValidator<T> secret() =>
      SuperRefineValidator(_inner.secret(), _callback, isSecret: true);

  @override
  Validator<T> strict() =>
      SuperRefineValidator(_inner.strict(), _callback, isSecret: isSecret);

  @override
  Validator<T> stopOnFirstError() => SuperRefineValidator(
    _inner.stopOnFirstError(),
    _callback,
    isSecret: isSecret,
  );

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    FlodDebug.trace(
      'enter',
      validator: 'SuperRefineValidator',
      path: path,
      value: value,
      isSecret: isSecret,
    );

    final result = _inner.validate(value, path: path, abortEarly: abortEarly);
    if (result is FlodFailure) {
      FlodDebug.trace(
        'fail',
        validator: 'SuperRefineValidator',
        path: path,
        detail: 'inner failure',
        isSecret: isSecret,
      );
      return result;
    }

    final T data = (result as FlodSuccess<T>).data;
    final ctx = SuperRefineContext(
      basePath: path,
      isSecret: isSecret,
      value: data,
    );

    try {
      _callback(data, ctx);
    } catch (e) {
      FlodDebug.trace(
        'fail',
        validator: 'SuperRefineValidator',
        path: path,
        detail: 'callback exception',
        isSecret: isSecret,
      );
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.refineException,
          params: {'message': e.toString()},
          value: isSecret ? null : data,
          isSecret: isSecret,
        ),
      ]);
    }

    if (ctx.hasIssues) {
      FlodDebug.trace(
        'fail',
        validator: 'SuperRefineValidator',
        path: path,
        detail: '${ctx.issues.length} issue(s)',
        isSecret: isSecret,
      );
      return FlodFailure(ctx.issues);
    }

    FlodDebug.trace(
      'ok',
      validator: 'SuperRefineValidator',
      path: path,
      value: data,
      isSecret: isSecret,
    );
    return result;
  }
}

/// Async super-refine layer — requires [ValidatorExtensions.safeParseAsync].
class AsyncSuperRefineValidator<T> extends Validator<T>
    implements AsyncValidator<T> {
  final Validator<T> _inner;
  final Future<void> Function(T value, SuperRefineContext ctx) _callback;

  Validator<T> get inner => _inner;

  @override
  bool get isCompiled => _inner.isCompiled;

  Future<void> Function(T value, SuperRefineContext ctx) get callback =>
      _callback;

  AsyncSuperRefineValidator(
    this._inner,
    this._callback, {
    super.isSecret = false,
  });

  @override
  Validator? getFieldSchema(String key) => _inner.getFieldSchema(key);

  @override
  AsyncSuperRefineValidator<T> secret() =>
      AsyncSuperRefineValidator(_inner.secret(), _callback, isSecret: true);

  @override
  Validator<T> strict() =>
      AsyncSuperRefineValidator(_inner.strict(), _callback, isSecret: isSecret);

  @override
  Validator<T> stopOnFirstError() => AsyncSuperRefineValidator(
    _inner.stopOnFirstError(),
    _callback,
    isSecret: isSecret,
  );

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    return FlodFailure([
      FlodError(
        path: path,
        code: FlodErrorCodes.asyncParseRequired,
        params: const {},
        value: value,
        isSecret: isSecret,
      ),
    ]);
  }

  @override
  Future<ParseResult<T>> validateAsync(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) async {
    FlodDebug.trace(
      'enter',
      validator: 'AsyncSuperRefineValidator',
      path: path,
      value: value,
      isSecret: isSecret,
    );

    final result = await _resolveInner(
      value,
      path: path,
      abortEarly: abortEarly,
    );
    if (result is FlodFailure) return result;

    final T data = (result as FlodSuccess<T>).data;
    final ctx = SuperRefineContext(
      basePath: path,
      isSecret: isSecret,
      value: data,
    );

    try {
      await _callback(data, ctx);
    } catch (e) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.refineException,
          params: {'message': e.toString()},
          value: isSecret ? null : data,
          isSecret: isSecret,
        ),
      ]);
    }

    if (ctx.hasIssues) {
      return FlodFailure(ctx.issues);
    }

    return result;
  }

  Future<ParseResult<T>> _resolveInner(
    dynamic value, {
    required FlodPath path,
    bool? abortEarly,
  }) {
    if (_inner is AsyncValidator<T>) {
      return (_inner as AsyncValidator<T>).validateAsync(
        value,
        path: path,
        abortEarly: abortEarly,
      );
    }
    return Future.value(
      _inner.validate(value, path: path, abortEarly: abortEarly),
    );
  }
}

extension SuperRefineExtension<T> on Validator<T> {
  /// Zod-compatible `.superRefine()` — attach multiple custom issues.
  Validator<T> superRefine(
    void Function(T value, SuperRefineContext ctx) callback,
  ) {
    return SuperRefineValidator(this, callback, isSecret: isSecret);
  }

  /// Async variant of [superRefine]; use with [safeParseAsync].
  AsyncSuperRefineValidator<T> superRefineAsync(
    Future<void> Function(T value, SuperRefineContext ctx) callback,
  ) {
    return AsyncSuperRefineValidator(this, callback, isSecret: isSecret);
  }
}

extension SuperRefineObjectExtension on ObjectValidator {
  Validator<Map<String, dynamic>> superRefine(
    void Function(Map<String, dynamic> value, SuperRefineContext ctx) callback,
  ) {
    return SuperRefineValidator(this, callback, isSecret: isSecret);
  }

  AsyncSuperRefineValidator<Map<String, dynamic>> superRefineAsync(
    Future<void> Function(Map<String, dynamic> value, SuperRefineContext ctx)
    callback,
  ) {
    return AsyncSuperRefineValidator(this, callback, isSecret: isSecret);
  }
}
