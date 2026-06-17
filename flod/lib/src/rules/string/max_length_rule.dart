import 'package:flod/src/rules/string/base_string_rule.dart';

class MaxLengthRule extends BaseStringRule {
  final int max;

  MaxLengthRule(this.max, String message, String code)
    : super(message: message, code: code);

  @override
  bool check(String value) => value.length <= max;

  // @override
  // ValidationResult<String> validate(String value, {Path path = const []}) {
  //   if (value.length > max) {
  //     return FlodFailure([FlodError(path, message, code)]);
  //   }
  //   return FlodSuccess(value);
  // }
}
