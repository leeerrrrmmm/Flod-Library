import 'package:flod/src/rules/string/base_string_rule.dart';

/// Custom string validation rule with optional [metaParams] for i18n context.
class CustomStringRule extends BaseStringRule {
  final bool Function(String value) predicate;
  final Map<String, dynamic>? metaParams;

  const CustomStringRule(
    this.predicate, {
    required super.code,
    this.metaParams,
  });

  @override
  bool check(String value) => predicate(value);

  @override
  Map<String, dynamic> get params => metaParams ?? const {};
}
