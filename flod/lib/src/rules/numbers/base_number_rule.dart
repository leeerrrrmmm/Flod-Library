import 'package:flod/src/rules/base_rule.dart';

abstract class BaseNumberRule<T extends num> extends BaseRule<T> {
  BaseNumberRule({required super.message, required super.code});
}
