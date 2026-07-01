import 'package:flod/flod.dart';

class RefineValidator<T> extends Validator<T> {
  final Validator<T> _inner;
  final bool Function(T value) _predicate;
  final List<String>? _customPath;
  final String _code;
  final Map<String, dynamic>? _params;

  RefineValidator(
    this._inner,
    this._predicate,
    this._customPath,
    this._code,
    this._params, {
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
      isSecret: true,
    );
  }

  // Прокидываем управляющие методы вглубь матрешки
  @override
  Validator<T> strict() => RefineValidator<T>(
    _inner.strict(),
    _predicate,
    _customPath,
    _code,
    _params,
    isSecret: isSecret,
  );

  @override
  Validator<T> stopOnFirstError() => RefineValidator<T>(
    _inner.stopOnFirstError(),
    _predicate,
    _customPath,
    _code,
    _params,
    isSecret: isSecret,
  );

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    //Сначала проверяем внутренний валидатор
    final result = _inner.validate(value, path: path, abortEarly: abortEarly);

    //Сразу проверяем на ошибки
    if (result is FlodFailure) {
      return result;
    }

    final T data = (result as FlodSuccess<T>).data;

    try {
      final isValid = _predicate(data);

      if (!isValid) {
        // Формируем целевой путь. Если передан локальный path: ['confirmPassword'],
        // склеиваем его с текущим родительским контекстом.
        final targetPath = _customPath != null
            ? FlodPath([...path.segments, ..._customPath])
            : path;

        return FlodFailure([
          FlodError(
            path: targetPath,
            code: _code,
            params: {'value': isSecret ? null : data, ...?_params},
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
          value: data,
          isSecret: isSecret,
        ),
      ]);
    }
    return result;
  }
}

extension RefineExtension<T> on Validator<T> {
  Validator<T> refine(
    bool Function(T value) predicate, {
    List<String>? path,
    String? code,
    Map<String, dynamic>? params,
  }) {
    return RefineValidator<T>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      isSecret: isSecret,
    );
  }
}

extension RefineObjectExtension on ObjectValidator {
  Validator<Map<String, dynamic>> refine(
    bool Function(Map<String, dynamic> value) predicate, {
    List<String>? path,
    String? code,
    Map<String, dynamic>? params,
  }) {
    return RefineValidator<Map<String, dynamic>>(
      this,
      predicate,
      path,
      code ?? 'custom_refine',
      params,
      isSecret: isSecret,
    );
  }
}
