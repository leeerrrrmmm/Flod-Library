import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/rules/numbers/custom_number_rule.dart';
import 'package:flod/src/rules/numbers/max_value_rule.dart';
import 'package:flod/src/rules/numbers/min_value_rule.dart';
import 'package:flod/src/rules/numbers/multiplie_of_rule.dart';

class IntValidator extends Validator<int> with Transformable<int> {
  final List<BaseNumberRule<int>> rules;

  @override
  final List<Transformer<int>> transformers;

  const IntValidator([
    this.rules = const [],
    this.transformers = const [],
    bool isSecret = false,
  ]) : super(isSecret: isSecret);

  @override
  bool get isPure => rules.isEmpty && transformers.isEmpty && !isSecret;

  @override
  IntValidator secret() => isSecret ? this : copyWith(isSecret: true);

  IntValidator copyWith({
    List<BaseNumberRule<int>>? rules,
    List<Transformer<int>>? transformers,
    bool? isSecret,
  }) {
    final nextRules = rules ?? this.rules;
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged: identical(nextRules, this.rules) &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () => IntValidator(nextRules, nextTransformers, nextSecret),
    );
  }

  IntValidator _withRule(BaseNumberRule<int> rule) =>
      copyWith(rules: ChainUtils.append(rules, rule));

  IntValidator min(int minBound, {String? code, String? message}) {
    return _withRule(
      MinValueRule<int>(
        minBound,
        code: code ?? FlodErrorCodes.numberMin,
        message: message,
      ),
    );
  }

  IntValidator max(int maxBound, {String? code, String? message}) {
    return _withRule(
      MaxValueRule<int>(
        maxBound,
        code: code ?? FlodErrorCodes.numberMax,
        message: message,
      ),
    );
  }

  IntValidator multipleOf(int factor, {String? code, String? message}) {
    return _withRule(
      MultipleOfRule<int>(
        factor,
        code: code ?? FlodErrorCodes.numberMultipleOf,
        message: message,
      ),
    );
  }

  IntValidator custom(
    bool Function(int value) predicate, {
    required String code,
    String? message,
    Map<String, dynamic>? metaParams,
  }) {
    return _withRule(
      CustomNumberRule<int>(
        predicate,
        code: code,
        message: message,
        metaParams: metaParams,
      ),
    );
  }

  IntValidator positive({String? code, String? message}) {
    return custom(
      (v) => v > 0,
      code: code ?? FlodErrorCodes.numberPositive,
      message: message,
    );
  }

  IntValidator nonPositive({String? code, String? message}) {
    return custom(
      (v) => v <= 0,
      code: code ?? FlodErrorCodes.numberNonPositive,
      message: message,
    );
  }

  IntValidator negative({String? code, String? message}) {
    return custom(
      (v) => v < 0,
      code: code ?? FlodErrorCodes.numberNegative,
      message: message,
    );
  }

  IntValidator nonNegative({String? code, String? message}) {
    return custom(
      (v) => v >= 0,
      code: code ?? FlodErrorCodes.numberNonNegative,
      message: message,
    );
  }

  @override
  ParseResult<int> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    dynamic preparedValue = value;

    if (transformers.isNotEmpty) {
      try {
        preparedValue = applyTransforms(preparedValue, path);
      } catch (_) {
        return _makeTypeFailure(isSecret ? null : value, path);
      }
    }

    if (preparedValue is! int) {
      return _makeTypeFailure(isSecret ? null : preparedValue, path);
    }

    // 12.2 fast path
    if (isPure) return FlodSuccess<int>(preparedValue);

    final int finalValue = preparedValue;
    final errors = <FlodError>[];
    final shouldAbort = abortEarly ?? false;

    for (final rule in rules) {
      if (!rule.check(finalValue)) {
        errors.add(
          FlodError(
            path: path,
            code: rule.code,
            params: rule.params,
            message: rule.message,
            value: isSecret ? null : finalValue,
            isSecret: isSecret,
          ),
        );
        if (shouldAbort) return FlodFailure<int>(errors);
      }
    }

    return errors.isEmpty
        ? FlodSuccess<int>(finalValue)
        : FlodFailure<int>(errors);
  }

  ParseResult<int> _makeTypeFailure(dynamic val, FlodPath path) {
    return FlodFailure<int>([
      FlodError(
        path: path,
        code: FlodErrorCodes.invalidType,
        params: {
          'expected': 'int',
          'actual': val == null ? 'null' : val.runtimeType.toString(),
        },
        value: val,
        isSecret: isSecret,
      ),
    ]);
  }
}
