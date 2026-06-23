import 'package:flod/src/rules/numbers/base_number_rule.dart';

class CustomNumberRule<T extends num> extends BaseNumberRule<T> {
  final bool Function(T value) predicate;

  CustomNumberRule(
    this.predicate, {
    required super.message,
    required super.code,
  });

  @override
  bool check(T value) => predicate(value);
}
