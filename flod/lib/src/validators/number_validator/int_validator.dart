import 'package:flod/flod.dart';
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
  IntValidator secret() => copyWith(isSecret: true);

  IntValidator copyWith({
    List<BaseNumberRule<int>>? rules,
    List<Transformer<int>>? transformers,
    bool? isSecret,
  }) {
    return IntValidator(
      rules ?? this.rules,
      transformers ?? this.transformers,
      isSecret ?? this.isSecret,
    );
  }

  IntValidator min(int minBound, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        MinValueRule<int>(minBound, code: code ?? FlodErrorCodes.numberMin),
      ],
    );
  }

  IntValidator max(int maxBound, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        MaxValueRule<int>(maxBound, code: code ?? FlodErrorCodes.numberMax),
      ],
    );
  }

  IntValidator multipleOf(int factor, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        MultipleOfRule<int>(
          factor,
          code: code ?? FlodErrorCodes.numberMultipleOf,
        ),
      ],
    );
  }

  IntValidator custom(
    bool Function(int value) predicate, {
    required String code,
    Map<String, dynamic>? metaParams,
  }) {
    return copyWith(
      rules: [
        ...rules,
        CustomNumberRule<int>(predicate, code: code, metaParams: metaParams),
      ],
    );
  }

  IntValidator positive({String? code}) {
    return custom((v) => v > 0, code: code ?? FlodErrorCodes.numberPositive);
  }

  IntValidator nonPositive({String? code}) {
    return custom(
      (v) => v <= 0,
      code: code ?? FlodErrorCodes.numberNonPositive,
    );
  }

  IntValidator negative({String? code}) {
    return custom((v) => v < 0, code: code ?? FlodErrorCodes.numberNegative);
  }

  IntValidator nonNegative({String? code}) {
    return custom(
      (v) => v >= 0,
      code: code ?? FlodErrorCodes.numberNonNegative,
    );
  }

  @override
  ParseResult<int> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    dynamic preparedValue = value;

    try {
      preparedValue = applyTransforms(preparedValue, path);
    } catch (_) {
      return _makeTypeFailure(isSecret ? null : value, path);
    }

    if (preparedValue is! int) {
      return _makeTypeFailure(isSecret ? null : preparedValue, path);
    }

    final int finalValue = preparedValue;
    final errors = <FlodError>[];

    for (final rule in rules) {
      if (!rule.check(finalValue)) {
        errors.add(
          FlodError(
            path: path,
            code: rule.code,
            params: rule.params,
            value: isSecret ? null : finalValue,
            isSecret: isSecret,
          ),
        );
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
