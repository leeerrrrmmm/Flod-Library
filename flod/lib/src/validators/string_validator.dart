import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/rules/string/max_length_rule.dart';
import 'package:flod/src/rules/string/min_length_rule.dart';
import 'package:flod/src/rules/string/regex_rule.dart';
import 'package:flod/src/types/path.dart';

class StringValidator extends Validator<String> with Transformable<String> {
  final List<BaseStringRule> rules;

  // Храним трансформеры с жестким типом Transformer<String>
  final List<Transformer<String>> _capturedTransformers;

  StringValidator([
    this.rules = const [],
    List<Transformer<String>> capturedTransformers = const [],
  ]) : _capturedTransformers = List.from(capturedTransformers) {
    for (final transform in _capturedTransformers) {
      super.addTransform(transform);
    }
  }

  // Строгая сигнатура Transformer<String> заставляет Dart правильно выводить типы в расширениях
  @override
  void addTransform(Transformer<String> transform) {
    _capturedTransformers.add(transform);
    super.addTransform(transform);
  }

  /// Метод для безопасного копирования валидатора по цепочке без потери трансформеров
  StringValidator copyWith({List<BaseStringRule>? rules}) {
    return StringValidator(rules ?? this.rules, _capturedTransformers);
  }

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

  @override
  ValidationResult<String> validate(dynamic value, {Path path = const []}) {
    // ВАЖНО: Сначала проверяем тип. Если это не строка (например, int 123),
    // мы сразу возвращаем ошибку, не пуская данные в трансформеры строк.
    if (value is! String) {
      return FlodFailure([
        FlodError(path, 'Expected a string', 'invalid_type'),
      ]);
    }

    // Теперь вызов безопасен — тут гарантированно String
    final String transformed = applyTransforms(value);
    final errors = <FlodError>[];

    for (final rule in rules) {
      final result = rule.check(transformed);

      if (!result) {
        errors.add(FlodError(path, rule.message, rule.code));
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
