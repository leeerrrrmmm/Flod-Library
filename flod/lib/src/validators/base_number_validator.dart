// lib/src/validators/base_number_validator.dart
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/rules/numbers/max_value_rule.dart';
import 'package:flod/src/rules/numbers/min_value_rule.dart';

abstract class BaseNumberValidator<T extends num> implements Validator<T> {
  final List<BaseNumberRule<T>> rules;
  const BaseNumberValidator([this.rules = const []]);

  BaseNumberValidator<T> copyWith(List<BaseNumberRule<T>> newRules);

  // ИСПРАВЛЕНИЕ: Параметры теперь именованные и опциональные
  BaseNumberValidator<T> min(
    T minVal, {
    String message = 'Too small',
    String code = 'min_error',
  }) {
    return copyWith([...rules, MinValueRule(minVal, message, code)]);
  }

  BaseNumberValidator<T> max(
    T maxVal, {
    String message = 'Too large',
    String code = 'max_error',
  }) {
    return copyWith([...rules, MaxValueRule(maxVal, message, code)]);
  }
}
