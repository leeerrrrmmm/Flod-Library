import 'package:flod/src/rules/string/base_string_rule.dart';

// lib/src/rules/string/min_length_rule.dart
class MinLengthRule extends BaseStringRule {
  final int min;

  MinLengthRule(this.min, {required super.message, required super.code});

  @override
  bool check(String value) => value.length >= min;
}

// ValidationResult<String> validate(String value, {Path path = const []}) {
//   if (value.length < min) {
//     return FlodFailure([FlodError(path, message, code)]);
//   }
//   return FlodSuccess(value);
// }
