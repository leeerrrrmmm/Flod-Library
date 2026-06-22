import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/base_number_validator.dart';

class IntValidator extends BaseNumberValidator<int> with Transformable<int> {
  IntValidator([super.rules]);

  @override
  IntValidator copyWith(List<BaseNumberRule<int>> newRules) {
    return IntValidator(newRules);
  }

  @override
  ValidationResult<int> validate(dynamic value, {Path path = const []}) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! int) {
      return FlodFailure([FlodError(path, 'Expected int', 'invalid_type')]);
    }

    final errors = <FlodError>[];

    for (final rule in rules) {
      if (!rule.check(transformed)) {
        errors.add(FlodError(path, rule.message, rule.code));
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
