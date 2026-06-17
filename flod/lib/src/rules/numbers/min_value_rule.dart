import 'package:flod/src/rules/numbers/base_number_rule.dart';

class MinValueRule<T extends num> extends BaseNumberRule<T> {
  final num min;

  MinValueRule(this.min, String message, String code)
    : super(message: message, code: code);

  @override
  bool check(num value) => value >= min;
}
