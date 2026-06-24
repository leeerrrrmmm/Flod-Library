import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';

class LiteralValidator<T> extends Validator<T> {
  final T expectedValue;
  final String? customMessage;
  final String? customCode;

  const LiteralValidator(
    this.expectedValue, {
    this.customMessage,
    this.customCode,
    super.isSecret = false,
  });

  @override
  LiteralValidator<T> secret() => copyWith(isSecret: true);

  LiteralValidator<T> copyWith({
    T? expectedValue,
    String? customMessage,
    String? customCode,
    bool? isSecret,
  }) {
    return LiteralValidator<T>(
      expectedValue ?? this.expectedValue,
      customMessage: customMessage ?? this.customMessage,
      customCode: customCode ?? this.customCode,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ValidationResult<T> validate(dynamic value, {Path path = const []}) {
    if (value == expectedValue) {
      return FlodSuccess(value as T);
    }

    return FlodFailure([
      FlodError(
        path,
        customMessage ?? "Expected literal value '$expectedValue'",
        customCode ?? "invalid_literal",
        value: value,
        isSecret: isSecret,
      ),
    ]);
  }
}
