import 'package:flod/flod.dart';

class RefineValidator<T> extends Validator<T> {
  final Validator<T> _inner;
  final bool Function(T value) _predicate;
  final List<String>? _customPath;
  final String _code;
  final Map<String, dynamic>? _params;
  final String? _message;

  /// Inner validator wrapped by this refine layer.
  Validator<T> get inner => _inner;

  @override
  bool get isCompiled => _inner.isCompiled;

  /// Predicate for [ValidatorCompiler].
  bool Function(T value) get predicate => _predicate;

  /// Custom error path for [ValidatorCompiler].
  List<String>? get customPath => _customPath;

  /// Error code for [ValidatorCompiler].
  String get errorCode => _code;

  /// Error params for [ValidatorCompiler].
  Map<String, dynamic>? get errorParams => _params;

  /// Inline message for [ValidatorCompiler].
  String? get errorMessage => _message;

  RefineValidator(
    this._inner,
    this._predicate,
    this._customPath,
    this._code,
    this._params, {
    this._message,
    super.isSecret = false,
  });

  @override
  Validator? getFieldSchema(String key) => _inner.getFieldSchema(key);

  @override
  RefineValidator<T> secret() {
    return RefineValidator<T>(
      _inner.secret(),
      _predicate,
      _customPath,
      _code,
      _params,
      message: _message,
      isSecret: true,
    );
  }

  // Propagate control methods into nested wrappers
  @override
  Validator<T> strict() => RefineValidator<T>(
    _inner.strict(),
    _predicate,
    _customPath,
    _code,
    _params,
    message: _message,
    isSecret: isSecret,
  );

  @override
  Validator<T> stopOnFirstError() => RefineValidator<T>(
    _inner.stopOnFirstError(),
    _predicate,
    _customPath,
    _code,
    _params,
    message: _message,
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
      validator: 'RefineValidator',
      path: path,
      value: value,
      isSecret: isSecret,
    );

    // First validate the inner validator
    final result = _inner.validate(value, path: path, abortEarly: abortEarly);

    // Immediately check for errors
    if (result is FlodFailure) {
      FlodDebug.trace(
        'fail',
        validator: 'RefineValidator',
        path: path,
        detail: 'inner failure',
        isSecret: isSecret,
      );
      return result;
    }

    final T data = (result as FlodSuccess<T>).data;

    try {
      final isValid = _predicate(data);

      if (!isValid) {
        // Build target path. If local path: ['confirmPassword'] is passed,
        // merge it with the current parent context.
        final targetPath = _customPath != null
            ? FlodPath([...path.segments, ..._customPath])
            : path;

        FlodDebug.trace(
          'fail',
          validator: 'RefineValidator',
          path: targetPath,
          detail: _code,
          isSecret: isSecret,
        );

        return FlodFailure([
          FlodError(
            path: targetPath,
            code: _code,
            params: {'value': isSecret ? null : data, ...?_params},
            message: _message,
            value: isSecret ? null : data,
            isSecret: isSecret,
          ),
        ]);
      }
    } catch (e) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.refineException,
          params: _params ?? {},
          message: _message,
          value: data,
          isSecret: isSecret,
        ),
      ]);
    }

    FlodDebug.trace(
      'ok',
      validator: 'RefineValidator',
      path: path,
      value: data,
      isSecret: isSecret,
    );
    return result;
  }
}

/// Async refine layer — requires [ValidatorExtensions.safeParseAsync].
class AsyncRefineValidator<T> extends Validator<T>
    implements AsyncValidator<T> {
  final Validator<T> _inner;
  final Future<bool> Function(T value) _predicate;
  final List<String>? _customPath;
  final String _code;
  final Map<String, dynamic>? _params;
  final String? _message;

  Validator<T> get inner => _inner;

  @override
  bool get isCompiled => _inner.isCompiled;

  Future<bool> Function(T value) get predicate => _predicate;
  List<String>? get customPath => _customPath;
  String get errorCode => _code;
  Map<String, dynamic>? get errorParams => _params;
  String? get errorMessage => _message;

  AsyncRefineValidator(
    this._inner,
    this._predicate,
    this._customPath,
    this._code,
    this._params, {
    this._message,
    super.isSecret = false,
  });

  @override
  Validator? getFieldSchema(String key) => _inner.getFieldSchema(key);

  @override
  AsyncRefineValidator<T> secret() => AsyncRefineValidator(
    _inner.secret(),
    _predicate,
    _customPath,
    _code,
    _params,
    message: _message,
    isSecret: true,
  );

  @override
  Validator<T> strict() => AsyncRefineValidator(
    _inner.strict(),
    _predicate,
    _customPath,
    _code,
    _params,
    message: _message,
    isSecret: isSecret,
  );

  @override
  Validator<T> stopOnFirstError() => AsyncRefineValidator(
    _inner.stopOnFirstError(),
    _predicate,
    _customPath,
    _code,
    _params,
    message: _message,
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
    final result = await _resolveInner(
      value,
      path: path,
      abortEarly: abortEarly,
    );
    if (result is FlodFailure) return result;

    final T data = (result as FlodSuccess<T>).data;

    try {
      final isValid = await _predicate(data);
      if (!isValid) {
        final targetPath = _customPath != null
            ? FlodPath([...path.segments, ..._customPath])
            : path;

        return FlodFailure([
          FlodError(
            path: targetPath,
            code: _code,
            params: {'value': isSecret ? null : data, ...?_params},
            message: _message,
            value: isSecret ? null : data,
            isSecret: isSecret,
          ),
        ]);
      }
    } catch (e) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.refineException,
          params: _params ?? {},
          message: _message,
          value: data,
          isSecret: isSecret,
        ),
      ]);
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

extension RefineExtension<T> on Validator<T> {
  /// Custom predicate on any schema (objects **and** leaf primitives).
  ///
  /// ```dart
  /// Flod.string().email().refine(
  ///   (v) => !v.endsWith('@tempmail.com'),
  ///   message: 'Disposable emails are not allowed',
  /// );
  /// ```
  Validator<T> refine(
    bool Function(T value) predicate, {
    List<String>? path,
    String? code,
    String? message,
    Map<String, dynamic>? params,
  }) {
    return RefineValidator<T>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      message: message,
      isSecret: isSecret,
    );
  }

  /// Async variant of [refine]; use with [safeParseAsync].
  AsyncRefineValidator<T> refineAsync(
    Future<bool> Function(T value) predicate, {
    List<String>? path,
    String? code,
    String? message,
    Map<String, dynamic>? params,
  }) {
    return AsyncRefineValidator<T>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      message: message,
      isSecret: isSecret,
    );
  }
}

extension RefineObjectExtension on ObjectValidator {
  Validator<Map<String, dynamic>> refine(
    bool Function(Map<String, dynamic> value) predicate, {
    List<String>? path,
    String? code,
    String? message,
    Map<String, dynamic>? params,
  }) {
    return RefineValidator<Map<String, dynamic>>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      message: message,
      isSecret: isSecret,
    );
  }

  AsyncRefineValidator<Map<String, dynamic>> refineAsync(
    Future<bool> Function(Map<String, dynamic> value) predicate, {
    List<String>? path,
    String? code,
    String? message,
    Map<String, dynamic>? params,
  }) {
    return AsyncRefineValidator<Map<String, dynamic>>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      message: message,
      isSecret: isSecret,
    );
  }
}
