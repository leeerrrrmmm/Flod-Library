import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';
import 'package:flod/src/rules/regexp/regex_rule.dart';
import 'package:flod/src/validators/exception_validator/validator_exception.dart';

extension DefaultExtension<T> on Validator<T> {
  DefaultDecorator<T> defaultValue(T value) => DefaultDecorator<T>(this, value);
}

extension ValidatorExtensions<T> on Validator<T> {
  ParseResult<T> safeParse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      return FlodFailure<T>(result.errors);
    }
    return FlodSuccess<T>((result as FlodSuccess<T>).data);
  }

  T parse(dynamic value) {
    final result = validate(value);
    if (result is FlodFailure<T>) {
      throw ValidationException(result.errors);
    }
    return (result as FlodSuccess<T>).data;
  }
}

extension StringExtensions on StringValidator {
  bool isValidLuhn(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  StringValidator regex(RegExp pattern, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        RegexRule(pattern, code: code ?? FlodErrorCodes.stringRegex),
      ],
    );
  }

  StringValidator email({String? code}) => regex(
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
    code: code ?? FlodErrorCodes.stringEmail,
  );

  StringValidator creditCard({String? code}) => custom((value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(digits)) return false;
    return _isValidLuhn(digits);
  }, code: code ?? FlodErrorCodes.stringCreditCard);

  bool _isValidLuhn(String digits) {
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  StringValidator cvv({String? code}) =>
      regex(RegExp(r'^\d{3,4}$'), code: code ?? FlodErrorCodes.stringCvv);

  StringValidator html5Email({String? code}) => regex(
    RegExp(
      r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$''',
    ),
    code: code ?? FlodErrorCodes.stringEmail,
  );

  StringValidator url({String? code}) => regex(
    RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$'),
    code: code ?? FlodErrorCodes.stringUrl,
  );

  StringValidator phoneNumber({String? code}) => regex(
    RegExp(r'^\+?[1-9]\d{6,14}$'),
    code: code ?? FlodErrorCodes.stringPhoneNumber,
  );

  StringValidator customPattern(RegExp pattern, {String? code}) =>
      regex(pattern, code: code ?? FlodErrorCodes.stringRegex);

  StringValidator uuid({String? code}) => regex(
    RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ),
    code: code ?? FlodErrorCodes.stringUuid,
  );

  StringValidator minUppercase(int count, {String? code}) => custom(
    (value) => RegExp('^(.*?[A-Z]){$count,}').hasMatch(value),
    code: code ?? FlodErrorCodes.stringMinUppercase,
    metaParams: {'limit': count},
  );

  StringValidator minNumbers(int count, {String? code}) => custom(
    (value) => RegExp('^(.*?[0-9]){$count,}').hasMatch(value),
    code: code ?? FlodErrorCodes.stringMinNumbers,
    metaParams: {'limit': count},
  );

  StringValidator minSymbols(int count, {String? code}) => custom(
    (value) => RegExp(
      r'^(.*?[!@#\$&*~]){'
      '$count'
      r',}',
    ).hasMatch(value),
    code: code ?? FlodErrorCodes.stringMinSymbols,
    metaParams: {'limit': count},
  );
}

extension IntValidatorExtensions on IntValidator {
  IntValidator positive({String? code}) {
    return custom((v) => v > 0, code: code ?? FlodErrorCodes.numberPositive);
  }

  IntValidator nonPositive({String? code}) {
    return custom(
      (v) => v <= 0,
      code: code ?? FlodErrorCodes.numberNonPositive,
    );
  }

  IntValidator negative({String? code}) {
    return custom((v) => v < 0, code: code ?? FlodErrorCodes.numberNegative);
  }

  IntValidator nonNegative({String? code}) {
    return custom(
      (v) => v >= 0,
      code: code ?? FlodErrorCodes.numberNonNegative,
    );
  }
}

extension DoubleValidatorExtensions on DoubleValidator {
  DoubleValidator positive({String? code}) {
    return custom((v) => v > 0, code: code ?? FlodErrorCodes.numberPositive)
        as DoubleValidator;
  }

  DoubleValidator nonPositive({String? code}) {
    return custom((v) => v <= 0, code: code ?? FlodErrorCodes.numberNonPositive)
        as DoubleValidator;
  }

  DoubleValidator negative({String? code}) {
    return custom((v) => v < 0, code: code ?? FlodErrorCodes.numberNegative)
        as DoubleValidator;
  }

  DoubleValidator nonNegative({String? code}) {
    return custom((v) => v >= 0, code: code ?? FlodErrorCodes.numberNonNegative)
        as DoubleValidator;
  }
}

extension PathExtensions on List {
  List append(dynamic segment) => [...this, segment];
}

extension PathConversion on List<Object> {
  FlodPath toFlodPath() => FlodPath(this);
  String toReadable() => toFlodPath().toReadable();
}
