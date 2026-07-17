import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class TransformValidator<In, Out> extends Validator<Out> {
  final Validator<In> _parent;
  final Out Function(In value) _transformer;

  /// Parent validator for [ValidatorCompiler].
  Validator<In> get parent => _parent;

  /// Transform callback for [ValidatorCompiler].
  Out Function(In value) get callback => _transformer;

  TransformValidator(this._parent, this._transformer, {super.isSecret});

  @override
  Validator<Out> secret() {
    // Recursively propagate privacy up the entire transform chain
    return TransformValidator<In, Out>(
      _parent.secret(),
      _transformer,
      isSecret: true,
    );
  }

  @override
  ParseResult<Out> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    final parentResult = _parent.validate(
      value,
      path: path,
      abortEarly: abortEarly,
    );

    // Compute resulting layer privacy
    final bool currentSecret = isSecret || _parent.isSecret;

    switch (parentResult) {
      case FlodFailure<In>(errors: final errs):
        // If parent failed and layer is secret — mask its errors on output
        if (currentSecret) {
          final obfuscated = errs
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
          return FlodFailure<Out>(obfuscated);
        }
        return FlodFailure<Out>(errs);

      case FlodSuccess<In>(data: final data):
        try {
          final transformed = _transformer(data);
          return _resolveTransformOutput(
            transformed,
            path: path,
            currentSecret: currentSecret,
            fallbackValue: value,
          );
        } on FlodTransformerException catch (e) {
          final errors = currentSecret
              ? e.errors
                    .map(
                      (err) => FlodError(
                        path: err.path,
                        code: err.code,
                        params: err.params,
                        message: err.message,
                        value: null,
                        isSecret: true,
                      ),
                    )
                    .toList()
              : e.errors;
          return FlodFailure<Out>(errors);
        } catch (e) {
          final transformError = FlodError(
            path: path,
            code: FlodErrorCodes.transformError,
            params: {},
            value: currentSecret ? null : value,
            isSecret: currentSecret,
          );

          return FlodFailure<Out>([transformError]);
        }
    }
  }

  /// Unwraps nested [ParseResult] values returned from transform callbacks.
  ParseResult<Out> _resolveTransformOutput(
    dynamic transformed, {
    required FlodPath path,
    required bool currentSecret,
    required dynamic fallbackValue,
  }) {
    if (transformed is ParseResult) {
      switch (transformed) {
        case FlodFailure(errors: final errs):
          if (currentSecret) {
            final obfuscated = errs
                .map(
                  (e) => FlodError(
                    path: e.path.segments.isEmpty ? path : e.path,
                    code: e.code,
                    params: e.params,
                    message: e.message,
                    value: null,
                    isSecret: true,
                  ),
                )
                .toList();
            return FlodFailure<Out>(obfuscated);
          }
          final propagated = errs
              .map(
                (e) => FlodError(
                  path: e.path.segments.isEmpty ? path : e.path,
                  code: e.code,
                  params: e.params,
                  message: e.message,
                  value: e.isSecret ? null : e.rawValue,
                  isSecret: e.isSecret || currentSecret,
                ),
              )
              .toList();
          return FlodFailure<Out>(propagated);
        case FlodSuccess(data: final outData):
          return FlodSuccess<Out>(outData as Out);
      }
    }

    return FlodSuccess<Out>(transformed as Out);
  }
}
