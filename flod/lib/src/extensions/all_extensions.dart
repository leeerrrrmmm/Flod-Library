import 'package:flod/flod.dart';
import 'package:flod/src/rules/regexp/regex_rule.dart';

// =========================================================================
// 1. БАЗОВЫЕ МЕТОДЫ (Доступны ВСЕМ валидаторам)
// =========================================================================
extension ValidatorExtensions<T> on Validator<T> {
  ParseResult<T> safeParse(dynamic value) {
    final result = validate(value);
    if (result.isFailure) {
      return ParseResult.failure(result.errors);
    }
    return ParseResult.success(result.data);
  }
}

// =========================================================================
// 2. ЕДИНЫЕ РАСШИРЕНИЯ ДЛЯ СТРОК (Трансформации + Доменные правила)
// =========================================================================
extension StringExtensions on StringValidator {
  // --- Вспомагательный метод (Алгоритм Луна)
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

  // --- Трансформации ---
  StringValidator trim() {
    addTransform((v) => v is String ? v.trim() : v);
    return this;
  }

  StringValidator toLowerCase() {
    addTransform((v) => v is String ? v.toLowerCase() : v);
    return this;
  }

  // --- Базовый метод для регулярных выражений через copyWith ---
  StringValidator regex(
    RegExp pattern, {
    String message = 'Invalid format',
    String code = 'invalid_format',
  }) {
    return copyWith(
      rules: [
        ...rules,
        RegexRule(pattern, message: message, code: code),
      ],
    );
  }

  // --- Доменные правила ---

  StringValidator email({
    String message = 'Invalid email format',
    String code = 'invalid_email',
  }) => regex(
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
    message: message,
    code: code,
  );

  StringValidator creditCard({
    String message = 'Invalid credit card format',
    String code = 'invalid_credit_card',
  }) => custom(
    (value) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (!RegExp(r'^[0-9]{13,19}$').hasMatch(digits)) return false;
      return _isValidLuhn(digits);
    },
    message: message,
    code: code,
  );

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

  StringValidator cvv({
    String message = 'Invalid CVV',
    String code = 'invalid_cvv',
  }) => regex(RegExp(r'^\d{3,4}$'), message: message, code: code);

  StringValidator html5Email({
    String message = 'Invalid email format',
    String code = 'invalid_email',
  }) => regex(
    RegExp(
      r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$''',
    ),
    message: message,
    code: code,
  );

  StringValidator url({
    String message = 'Invalid URL format',
    String code = 'invalid_url',
  }) => regex(
    RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$'),
    message: message,
    code: code,
  );

  StringValidator phoneNumber({
    String message = 'Invalid phone number format',
    String code = 'invalid_phone',
  }) => regex(RegExp(r'^\+?[1-9]\d{6,14}$'), message: message, code: code);

  StringValidator customPattern(
    RegExp pattern, {
    String message = 'Invalid format',
    String code = 'invalid_pattern',
  }) => regex(pattern, message: message, code: code);

  StringValidator uuid({
    String message = 'Invalid UUID format',
    String code = 'invalid_uuid',
  }) => regex(
    RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ),
    message: message,
    code: code,
  );

  StringValidator minUppercase(
    int count, {
    String message = 'Needs uppercase',
    String code = 'min_uppercase',
  }) => regex(RegExp('^(.*?[A-Z]){$count,}'), message: message, code: code);

  StringValidator minNumbers(
    int count, {
    String message = 'Needs numbers',
    String code = 'min_numbers',
  }) => regex(RegExp('^(.*?[0-9]){$count,}'), message: message, code: code);

  StringValidator minSymbols(
    int count, {
    String message = 'Needs symbols',
    String code = 'min_symbols',
  }) => regex(
    RegExp(
      r'^(.*?[!@#\$&*~]){'
      '$count'
      r',}',
    ),
    message: message,
    code: code,
  );
}

// =========================================================================
// 3. РАСШИРЕНИЯ ДЛЯ ЧИСЕЛ И ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ
// =========================================================================
extension NumberExtensions<T extends num> on BaseNumberValidator<T> {
  BaseNumberValidator<T> positive() {
    final zero = (T == double ? 0.0 : 0) as T;
    return min(zero, message: 'Must be positive', code: 'not_positive');
  }

  BaseNumberValidator<T> multipleOf(num base) {
    return custom(
      (value) {
        if (base == 0) return false;

        // Избегаем проблем округления double через эпсилон-проверку
        final double division = value / base;
        final double remainder = (division - division.round()).abs();

        return remainder < 1e-9; // Высокая точность до 9 знака
      },
      message: 'Must be multiple of $base',
      code: 'multiple_of',
    );
  }
}

extension PathExtensions on List {
  List append(dynamic segment) => [...this, segment];
}

extension PathReadable on List<dynamic> {
  String toReadable() {
    // Если путь пустой (например, корень объекта), возвращаем 'root',
    // в остальных случаях — запускаем твою функцию форматирования.
    return isEmpty ? 'root' : formatPath(this);
  }
}
