import 'package:flod/src/rules/string/base_string_rule.dart';

class CustomRegexpRule extends BaseStringRule {
  final bool Function(String value) predicate;

  CustomRegexpRule(
    this.predicate, {
    required super.message,
    required super.code,
  });

  @override
  bool check(String value) => predicate(value);
}
