import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/types/path.dart';

class RegexRule extends BaseStringRule {
  final RegExp pattern;

  RegexRule(
    this.pattern, {
    Path path = const [],
    required super.message,
    required super.code,
  });

  @override
  bool check(String value) => pattern.hasMatch(value);
}
