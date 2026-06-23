import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/number_validator/base_number_validator.dart';

class DoubleValidator extends BaseNumberValidator<double>
    with Transformable<double> {
  DoubleValidator([super.rules, super.isSecret]);

  @override
  DoubleValidator secret() {
    return copyWith(rules, isSecret: true);
  }

  @override
  DoubleValidator copyWith(
    List<BaseNumberRule<double>> newRules, {
    bool? isSecret,
  }) {
    return DoubleValidator(newRules, isSecret ?? this.isSecret);
  }

  @override
  ValidationResult<double> validate(dynamic value, {Path path = const []}) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! double) {
      return FlodFailure([
        FlodError(
          path,
          'Expected double',
          'invalid_type',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    if (!transformed.isFinite) {
      return FlodFailure([
        FlodError(
          path,
          'Value must be finite and not NaN',
          'invalid_number',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    final errors = <FlodError>[];

    for (final rule in rules) {
      if (!rule.check(transformed)) {
        errors.add(
          FlodError(
            path,
            rule.message,
            rule.code,
            value: transformed,
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
