import 'package:flod/src/rules/numbers/base_number_rule.dart';

class CustomNumberRule<T extends num> extends BaseNumberRule<T> {
  final bool Function(T value) predicate;
  final Map<String, dynamic>? metaParams;

  const CustomNumberRule(
    this.predicate, {
    required super.code,
    super.message,
    this.metaParams,
  });

  @override
  bool check(T value) => predicate(value);

  @override
  Map<String, dynamic> get params => metaParams ?? const {};
}
