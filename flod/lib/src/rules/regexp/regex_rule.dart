import 'package:flod/src/rules/string/base_string_rule.dart';

class RegexRule extends BaseStringRule {
  final RegExp pattern;

  const RegexRule(this.pattern, {required super.code, super.message});

  @override
  bool check(String value) => pattern.hasMatch(value);
}
