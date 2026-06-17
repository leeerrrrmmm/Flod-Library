import 'package:flod/src/rules/base_rule.dart';

abstract class BaseStringRule extends BaseRule<String> {
  BaseStringRule({required super.message, required super.code});
}
