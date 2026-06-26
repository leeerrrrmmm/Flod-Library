import 'package:flod/src/rules/string/base_string_rule.dart';

class MaxLengthRule extends BaseStringRule {
  final int max;

  MaxLengthRule(this.max, {required super.code});

  @override
  bool check(String value) => value.length <= max;

  @override
  Map<String, dynamic> get params => {'limit': max};
}
