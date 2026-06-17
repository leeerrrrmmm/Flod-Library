import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/base_number_validator.dart';

class DoubleValidator extends BaseNumberValidator<double> {
  const DoubleValidator([super.rules]);

  @override
  DoubleValidator copyWith(List<BaseNumberRule<double>> newRules) {
    return DoubleValidator(newRules);
  }

  @override
  ValidationResult<double> validate(dynamic value, {Path path = const []}) {
    if (value is! double) {
      return FlodFailure([FlodError(path, 'Expected double', 'invalid_type')]);
    }

    if (!value.isFinite) {
      return FlodFailure([
        FlodError(path, 'Value must be finite and not NaN', 'invalid_number'),
      ]);
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
