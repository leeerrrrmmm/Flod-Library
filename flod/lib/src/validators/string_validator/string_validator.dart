import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/regexp/custom_regexp_rule.dart';
import 'package:flod/src/rules/regexp/regex_rule.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/rules/string/fixed_length_rule.dart';
import 'package:flod/src/rules/string/max_length_rule.dart';
import 'package:flod/src/rules/string/min_length_rule.dart';
import 'package:flod/src/types/path.dart';

class StringValidator extends Validator<String> with Transformable<String> {
  final List<BaseStringRule> rules;

  @override
  final List<Transformer<String>> transformers;

  // Теперь конструктор может быть полностью const, что идеально для производительности
  const StringValidator([
    this.rules = const [],
    this.transformers = const [],
    bool isSecret = false,
  ]) : super(isSecret: isSecret);

  @override
  StringValidator secret() => copyWith(isSecret: true);

  // =========================================================================
  // ВСТРОЕННЫЕ УТИЛИТЫ НОРМАЛИЗАЦИИ (БЛОК 5.2 DONE)
  // =========================================================================

  /// Удаляет пробелы по краям строки перед валидацией
  StringValidator trim() => _copyWithTransform((v) => v.trim());

  /// Приводит строку к нижнему регистру перед валидацией
  StringValidator toLowerCase() => _copyWithTransform((v) => v.toLowerCase());

  /// Приводит строку к верхнему регистру перед валидацией
  StringValidator toUpperCase() => _copyWithTransform((v) => v.toUpperCase());

  // =========================================================================
  // МЕНЕДЖМЕНТ СОСТОЯНИЯ СХЕМЫ
  // =========================================================================

  StringValidator copyWith({
    List<BaseStringRule>? rules,
    List<Transformer<String>>? transformers,
    bool? isSecret,
  }) {
    return StringValidator(
      rules ?? this.rules,
      transformers ?? this.transformers,
      isSecret ?? this.isSecret,
    );
  }

  StringValidator _copyWithTransform(Transformer<String> transform) {
    return copyWith(transformers: [...transformers, transform]);
  }

  // =========================================================================
  // ПРАВИЛА ВАЛИДАЦИИ
  // =========================================================================

  StringValidator min(int length, String message, String code) {
    return copyWith(
      rules: [
        ...rules,
        MinLengthRule(length, message: message, code: code),
      ],
    );
  }

  StringValidator max(int length, String message, String code) {
    return copyWith(rules: [...rules, MaxLengthRule(length, message, code)]);
  }

  StringValidator regex(RegExp pattern, String message, String code) {
    return copyWith(
      rules: [
        ...rules,
        RegexRule(pattern, message: message, code: code),
      ],
    );
  }

  StringValidator custom(
    bool Function(String value) predicate, {
    required String message,
    required String code,
  }) {
    return copyWith(
      rules: [
        ...rules,
        CustomRegexpRule(predicate, message: message, code: code),
      ],
    );
  }

  StringValidator fixedLength(int length, String message, String code) {
    return copyWith(
      rules: [
        ...rules,
        FixedLengthRule(length, message: message, code: code),
      ],
    );
  }

  // =========================================================================
  // ЯДРО ВАЛИДАЦИИ
  // =========================================================================

  @override
  ValidationResult<String> validate(dynamic value, {Path path = const []}) {
    // 1. Проверка типа (Guard Clause) ДО каких-либо мутаций
    if (value is! String) {
      return FlodFailure([
        FlodError(
          path,
          'Expected a string',
          'invalid_type',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    // 2. EXECUTION ORDER (5.3): Сначала полностью трансформируем данные
    final dynamic rawTransformed = applyTransforms(value);
    final String transformed = rawTransformed as String;

    final errors = <FlodError>[];

    // 3. Валидируем уже очищенную, нормализованную строку
    for (final rule in rules) {
      final result = rule.check(transformed);

      if (!result) {
        errors.add(
          FlodError(
            path,
            rule.message,
            rule.code,
            value: transformed, // В логи летит уже трансформированное значение!
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
