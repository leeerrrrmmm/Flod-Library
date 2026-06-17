import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/base_number_validator.dart';

class IntValidator extends BaseNumberValidator<int> {
  const IntValidator([super.rules]);

  @override
  IntValidator copyWith(List<BaseNumberRule<int>> newRules) {
    return IntValidator(newRules);
  }

  @override
  ValidationResult<int> validate(dynamic value, {Path path = const []}) {
    if (value is! int) {
      return FlodFailure([FlodError(path, 'Expected int', 'invalid_type')]);
    }

    final errors = <FlodError>[];

    for (final rule in rules) {
      if (!rule.check(value)) {
        errors.add(FlodError(path, rule.message, rule.code));
      }
    }

    return errors.isEmpty ? FlodSuccess(value) : FlodFailure(errors);
  }
}
