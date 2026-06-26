import 'package:flod/flod.dart';

class BoolValidator extends Validator<bool> {
  const BoolValidator({super.isSecret = false});

  @override
  BoolValidator secret() => BoolValidator(isSecret: true);

  @override
  ParseResult<bool> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    if (value is bool) {
      return FlodSuccess<bool>(value);
    }

    return FlodFailure([
      FlodError(
        path: path,
        code: FlodErrorCodes.invalidType,
        params: {
          'expected': 'bool',
          'actual': value == null ? 'null' : value.runtimeType.toString(),
        },
        value: isSecret ? null : value,
        isSecret: isSecret,
      ),
    ]);
  }
}
