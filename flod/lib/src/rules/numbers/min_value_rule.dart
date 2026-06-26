import 'package:flod/src/rules/numbers/base_number_rule.dart';

class MinValueRule<T extends num> extends BaseNumberRule<T> {
  final num min;

  const MinValueRule(this.min, {required super.code});

  @override
  bool check(num value) => value >= min;

  @override
  Map<String, dynamic> get params => {'limit': min};
}
