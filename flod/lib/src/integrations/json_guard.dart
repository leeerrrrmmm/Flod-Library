import 'dart:convert';

import 'package:flod/flod.dart';

/// Security limits applied before schema validation.
///
/// Rejects oversized or structurally dangerous JSON payloads
/// (prototype pollution keys, excessive depth, etc.).
class JsonGuardOptions {
  const JsonGuardOptions({
    this.maxDepth = 32,
    this.maxKeys = 1000,
    this.maxStringLength = 100000,
    this.maxArrayLength = 10000,
    this.blockPrototypeKeys = true,
  });

  final int maxDepth;
  final int maxKeys;
  final int maxStringLength;
  final int maxArrayLength;
  final bool blockPrototypeKeys;
}

const _prototypeKeys = {'__proto__', 'constructor', 'prototype'};

/// Security layer for inbound JSON — sanitizes structure, then validates.
///
/// Not a renamed [ValidatorExtensions.safeParse]: runs structural security
/// checks (depth, key budget, prototype keys) before the schema sees data.
class JsonGuard {
  const JsonGuard({this.options = const JsonGuardOptions()});

  final JsonGuardOptions options;

  /// Decodes [source], applies security checks, then validates with [schema].
  ParseResult<T> parseJson<T>(String source, Validator<T> schema) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      return FlodFailure<T>([
        FlodError(
          path: const FlodPath.empty(),
          code: FlodErrorCodes.guardInvalidJson,
          params: {'message': e.message},
          value: null,
        ),
      ]);
    }

    return guard(decoded, schema);
  }

  /// Applies security checks to [raw], then validates with [schema].
  ParseResult<T> guard<T>(dynamic raw, Validator<T> schema) {
    final sanitized = _sanitize(raw, const FlodPath([]), _WalkState());
    if (sanitized is FlodFailure<dynamic>) {
      return FlodFailure<T>(sanitized.errors);
    }
    return schema.safeParse((sanitized as FlodSuccess<dynamic>).data);
  }

  /// Like [parseJson] but throws [ValidationException] on any failure.
  T parseJsonOrThrow<T>(String source, Validator<T> schema) {
    final result = parseJson(source, schema);
    if (result is FlodFailure<T>) {
      throw ValidationException(result.errors);
    }
    return (result as FlodSuccess<T>).data;
  }

  ParseResult<dynamic> _sanitize(
    dynamic value,
    FlodPath path,
    _WalkState state,
  ) {
    state.depth++;
    if (state.depth > options.maxDepth) {
      return _fail(FlodErrorCodes.guardMaxDepth, path, {
        'limit': options.maxDepth,
      });
    }

    if (value == null || value is bool || value is num) {
      state.depth--;
      return FlodSuccess(value);
    }

    if (value is String) {
      if (value.length > options.maxStringLength) {
        return _fail(FlodErrorCodes.guardMaxStringLength, path, {
          'limit': options.maxStringLength,
        });
      }
      state.depth--;
      return FlodSuccess(value);
    }

    if (value is List) {
      if (value.length > options.maxArrayLength) {
        return _fail(FlodErrorCodes.guardMaxArrayLength, path, {
          'limit': options.maxArrayLength,
        });
      }
      final copy = <dynamic>[];
      for (var i = 0; i < value.length; i++) {
        final item = _sanitize(value[i], path.append(i), state);
        if (item is FlodFailure<dynamic>) return item;
        copy.add((item as FlodSuccess<dynamic>).data);
      }
      state.depth--;
      return FlodSuccess(copy);
    }

    if (value is Map) {
      final copy = <String, dynamic>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          return _fail(FlodErrorCodes.guardInvalidKeyType, path, {
            'actual': entry.key.runtimeType.toString(),
          });
        }
        final key = entry.key as String;
        if (options.blockPrototypeKeys && _prototypeKeys.contains(key)) {
          return _fail(FlodErrorCodes.guardPrototypeKey, path.append(key), {
            'key': key,
          });
        }
        state.totalKeys++;
        if (state.totalKeys > options.maxKeys) {
          return _fail(FlodErrorCodes.guardMaxKeys, path.append(key), {
            'limit': options.maxKeys,
          });
        }
        final item = _sanitize(entry.value, path.append(key), state);
        if (item is FlodFailure<dynamic>) return item;
        copy[key] = (item as FlodSuccess<dynamic>).data;
      }
      state.depth--;
      return FlodSuccess(copy);
    }

    return _fail(FlodErrorCodes.guardUnsupportedType, path, {
      'actual': value.runtimeType.toString(),
    });
  }

  FlodFailure<dynamic> _fail(
    String code,
    FlodPath path,
    Map<String, dynamic> params,
  ) {
    return FlodFailure([
      FlodError(
        path: path,
        code: code,
        params: params,
        value: null,
      ),
    ]);
  }
}

class _WalkState {
  int depth = 0;
  int totalKeys = 0;
}
