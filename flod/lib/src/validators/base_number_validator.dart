import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/rules/numbers/max_value_rule.dart';
import 'package:flod/src/rules/numbers/min_value_rule.dart';
import 'package:flod/src/validators/validator.dart';

abstract class BaseNumberValidator<T extends num> implements Validator<T> {
  final List<BaseNumberRule<T>> rules;
  const BaseNumberValidator([this.rules = const []]);

  // Абстрактный метод, который каждый подкласс (Int/Double) реализует сам
  BaseNumberValidator<T> copyWith(List<BaseNumberRule<T>> newRules);

  BaseNumberValidator<T> min(T min, String message, String code) {
    return copyWith([...rules, MinValueRule(min, message, code)]);
  }

  BaseNumberValidator<T> max(T max, String message, String code) {
    return copyWith([...rules, MaxValueRule(max, message, code)]);
  }
}
