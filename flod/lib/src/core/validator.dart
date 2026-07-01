import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/validator_compiler.dart';
import 'package:flod/src/validators/transform_validator/transform_validator.dart';

abstract class Validator<T> {
  final bool isSecret;
  const Validator({this.isSecret = false});

  /// True when this validator was produced by [compile] / [ValidatorCompiler].
  bool get isCompiled => false;

  /// True when no rules, transforms, or wrappers are attached.
  bool get isPure => !isSecret;

  Validator<T> secret();
  Validator<T> strict() => this;
  Validator<T> stopOnFirstError() => this;

  /// 12.3 — compiles into a cached, optimized validator tree.
  Validator<T> compile() => ValidatorCompiler.instance.compile(this);

  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  });

  Validator<R> transform<R>(R Function(T value) cb) {
    return TransformValidator<T, R>(this, cb);
  }

  Validator? getFieldSchema(String key) => null;
}
