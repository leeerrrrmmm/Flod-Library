import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flod/flod.dart';
import 'package:flod/src/integrations/json_guard.dart';

/// Dio middleware that validates JSON response bodies against a Flod schema.
///
/// On success, replaces [Response.data] with the typed, validated output.
/// On failure, rejects with [DioException] wrapping [ValidationException].
class FlodValidateInterceptor extends Interceptor {
  FlodValidateInterceptor({
    required this.schema,
    this.guard,
    this.extractData,
  });

  final Validator schema;
  final JsonGuard? guard;

  /// Optional extractor when the payload lives under a nested key
  /// (e.g. `(r) => r.data['data']`).
  final dynamic Function(Response response)? extractData;

  /// Validates a raw response payload — usable without Dio for unit tests.
  static ParseResult<T> validatePayload<T>({
    required dynamic raw,
    required Validator<T> schema,
    JsonGuard? guard,
  }) {
    if (guard != null) return guard.guard(raw, schema);
    return schema.safeParse(raw);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final raw = extractData?.call(response) ?? response.data;
    final result = validatePayload(
      raw: raw,
      schema: schema,
      guard: guard,
    );

    switch (result) {
      case FlodSuccess(data: final data):
        handler.next(
          Response(
            requestOptions: response.requestOptions,
            data: _toResponseData(data),
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            headers: response.headers,
            isRedirect: response.isRedirect,
            redirects: response.redirects,
            extra: response.extra,
          ),
        );
      case FlodFailure(errors: final errors):
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: ValidationException(errors),
            message: 'Response validation failed (${errors.length} error(s))',
          ),
        );
    }
  }
}

dynamic _toResponseData(Object? data) {
  return jsonDecode(jsonEncode(data));
}
