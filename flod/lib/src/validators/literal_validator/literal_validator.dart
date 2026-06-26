import 'package:flod/flod.dart';

class LiteralValidator<T> extends Validator<T> {
  final T expectedValue;
  final String? customCode;

  const LiteralValidator(
    this.expectedValue, {
    this.customCode,
    super.isSecret = false,
  });

  @override
  LiteralValidator<T> secret() => copyWith(isSecret: true);

  LiteralValidator<T> copyWith({
    T? expectedValue,
    String? customCode,
    bool? isSecret,
  }) {
    return LiteralValidator<T>(
      expectedValue ?? this.expectedValue,
      customCode: customCode ?? this.customCode,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    if (value == expectedValue) {
      return FlodSuccess<T>(value as T);
    }

    return FlodFailure([
      FlodError(
        path: path,
        code: customCode ?? FlodErrorCodes.invalidLiteral,
        params: const {},
        value: value,
        isSecret: isSecret,
      ),
    ]);
  }
}
