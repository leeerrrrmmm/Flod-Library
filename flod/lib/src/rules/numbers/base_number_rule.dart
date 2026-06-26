import 'package:flod/src/rules/base_rule.dart';

abstract class BaseNumberRule<T extends num> extends BaseRule<T> {
  const BaseNumberRule({required super.code});

  Map<String, dynamic> get params => const {};
}
