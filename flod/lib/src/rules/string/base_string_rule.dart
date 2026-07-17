import 'package:flod/src/rules/base_rule.dart';

abstract class BaseStringRule extends BaseRule<String> {
  const BaseStringRule({required super.code, super.message});

  Map<String, dynamic> get params => const {};
}
