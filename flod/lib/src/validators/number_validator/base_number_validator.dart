import 'package:flod/src/core/validator.dart';
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
    required String message,
    required String code,
  }) {
    return copyWith([
      ...rules,
      CustomNumberRule<T>(predicate, message: message, code: code),
    ], isSecret: isSecret);
  }

  BaseNumberValidator<T> min(
    T minVal, {
    String message = 'Too small',
    String code = 'min_error',
  }) {
    return copyWith([
      ...rules,
      MinValueRule(minVal, message, code),
    ], isSecret: isSecret);
  }

  BaseNumberValidator<T> max(
    T maxVal, {
    String message = 'Too large',
    String code = 'max_error',
  }) {
    return copyWith([
      ...rules,
      MaxValueRule(maxVal, message, code),
    ], isSecret: isSecret);
  }
}
