import 'package:flod/src/rules/numbers/base_number_rule.dart';

class MaxValueRule<T extends num> extends BaseNumberRule<T> {
  final num max;

  const MaxValueRule(this.max, {required super.code, super.message});

  @override
  bool check(num value) => value <= max;

  @override
  Map<String, dynamic> get params => {'limit': max};
}
