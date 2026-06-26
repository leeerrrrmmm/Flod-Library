import 'package:flod/src/rules/numbers/base_number_rule.dart';

class MultipleOfRule<T extends num> extends BaseNumberRule<T> {
  final T factor;

  const MultipleOfRule(this.factor, {required super.code});

  @override
  bool check(T value) {
    if (factor == 0) return false;
    return value % factor == 0;
  }

  @override
  Map<String, dynamic> get params => {'limit': factor};
}
