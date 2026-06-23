import 'package:flod/src/rules/string/base_string_rule.dart';

class FixedLengthRule extends BaseStringRule {
  final int length;

  FixedLengthRule(this.length, {required super.message, required super.code});

  @override
  bool check(String value) => value.length == length;
}
