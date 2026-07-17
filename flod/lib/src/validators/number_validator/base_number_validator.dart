import 'package:flod/src/core/validator.dart';
import 'package:flod/src/i18n/errors/errors_codes.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/rules/numbers/custom_number_rule.dart';
import 'package:flod/src/rules/numbers/max_value_rule.dart';
import 'package:flod/src/rules/numbers/min_value_rule.dart';

abstract class BaseNumberValidator<T extends num> extends Validator<T> {
  final List<BaseNumberRule<T>> rules;

  const BaseNumberValidator([this.rules = const [], bool isSecret = false])
    : super(isSecret: isSecret);

  BaseNumberValidator<T> copyWith(
    List<BaseNumberRule<T>> newRules, {
    bool? isSecret,
  });

  BaseNumberValidator<T> custom(
    bool Function(T value) predicate, {
    required String code,
    String? message,
    Map<String, dynamic>? metaParams,
  }) {
    return copyWith([
      ...rules,
      CustomNumberRule<T>(
        predicate,
        code: code,
        message: message,
        metaParams: metaParams,
      ),
    ], isSecret: isSecret);
  }

  BaseNumberValidator<T> min(T minVal, {String? code, String? message}) {
    return copyWith([
      ...rules,
      MinValueRule(
        minVal,
        code: code ?? FlodErrorCodes.numberMin,
        message: message,
      ),
    ], isSecret: isSecret);
  }

  BaseNumberValidator<T> max(T maxVal, {String? code, String? message}) {
    return copyWith([
      ...rules,
      MaxValueRule(
        maxVal,
        code: code ?? FlodErrorCodes.numberMax,
        message: message,
      ),
    ], isSecret: isSecret);
  }

  BaseNumberValidator<T> positive({String? code, String? message}) {
    return custom(
      (v) => v > 0,
      code: code ?? FlodErrorCodes.numberPositive,
      message: message,
    );
  }

  BaseNumberValidator<T> nonPositive({String? code, String? message}) {
    return custom(
      (v) => v <= 0,
      code: code ?? FlodErrorCodes.numberNonPositive,
      message: message,
    );
  }

  BaseNumberValidator<T> negative({String? code, String? message}) {
    return custom(
      (v) => v < 0,
      code: code ?? FlodErrorCodes.numberNegative,
      message: message,
    );
  }

  BaseNumberValidator<T> nonNegative({String? code, String? message}) {
    return custom(
      (v) => v >= 0,
      code: code ?? FlodErrorCodes.numberNonNegative,
      message: message,
    );
  }
}
