import 'package:flod/src/rules/numbers/base_number_rule.dart';

class MaxValueRule<T extends num> extends BaseNumberRule<T> {
  final num max;

  MaxValueRule(this.max, String message, String code)
    : super(message: message, code: code);

  @override
  bool check(num value) => value <= max;
}
