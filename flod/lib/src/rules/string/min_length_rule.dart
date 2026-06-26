import 'package:flod/src/rules/string/base_string_rule.dart';

class MinLengthRule extends BaseStringRule {
  final int length;

  MinLengthRule(this.length, {required super.code});

  @override
  bool check(String value) => value.length >= length;

  @override
  Map<String, dynamic> get params => {'limit': length};
}
