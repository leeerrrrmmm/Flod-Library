import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/number_validator/base_number_validator.dart';

class IntValidator extends BaseNumberValidator<int> with Transformable<int> {
  // Идеальный синтаксис Dart: оба параметра автоматически летят в родительский класс
  IntValidator([super.rules, super.isSecret]);

  @override
  IntValidator secret() {
    return copyWith(rules, isSecret: true);
  }

  @override
  IntValidator copyWith(List<BaseNumberRule<int>> newRules, {bool? isSecret}) {
    return IntValidator(newRules, isSecret ?? this.isSecret);
  }

  @override
  ValidationResult<int> validate(dynamic value, {Path path = const []}) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! int) {
      return FlodFailure([
        FlodError(
          path,
          'Expected int',
          'invalid_type',
          value: value, // Ошибки уйдут, как только обновим FlodError ниже
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
