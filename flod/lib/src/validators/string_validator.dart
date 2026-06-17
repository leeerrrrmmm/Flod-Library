import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/rules/string/max_length_rule.dart';
import 'package:flod/src/rules/string/min_length_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/validator.dart';

class StringValidator implements Validator<String> {
  final List<BaseStringRule> _rules;

  const StringValidator([this._rules = const []]);

  StringValidator min(int length, String message, String code) {
    return StringValidator([
      ..._rules,
      MinLengthRule(length, message: message, code: code),
    ]);
  }

  StringValidator max(int length, String message, String code) {
    return StringValidator([..._rules, MaxLengthRule(length, message, code)]);
  }

  @override
  ValidationResult<String> validate(dynamic value, {Path path = const []}) {
    if (value is! String) {
      return FlodFailure([
        FlodError(path, 'Expected a string', 'invalid_type'),
      ]);
    }
    final errors = <FlodError>[];

    for (final rule in _rules) {
      final result = rule.check(value);

      if (!result) {
        errors.add(FlodError(path, rule.message, rule.code));
      }
    }

    return errors.isEmpty ? FlodSuccess(value) : FlodFailure(errors);
  }
}
