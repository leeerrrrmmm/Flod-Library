import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/number_validator/base_number_validator.dart';

class IntValidator extends BaseNumberValidator<int> with Transformable<int> {
  @override
  final List<Transformer<int>> transformers;

  // Чистый const конструктор, прокидывающий правила и приватность наверх
  const IntValidator([
    super.rules = const [],
    this.transformers = const [],
    super.isSecret,
  ]);

  @override
  IntValidator secret() => copyWith(rules, isSecret: true);

  /// Иммутабельный метод добавления трансформации для чисел
  IntValidator _copyWithTransform(Transformer<int> transform) {
    // Передаем rules позиционно первым аргументом
    return copyWith(rules, transformers: [...transformers, transform]);
  }

  // =========================================================================
  // ВСТРОЕННЫЕ ЧИСЛОВЫЕ ТРАНСФОРМЕРЫ (Пример расширения конвейера)
  // =========================================================================

  /// Автоматически берет модуль числа (абсолютное значение) перед валидацией
  IntValidator abs() => _copyWithTransform((v) => (v as int).abs());

  // =========================================================================
  // МЕНЕДЖМЕНТ СОСТОЯНИЯ СХЕМЫ
  // =========================================================================

  /// Исправленный коoverride сигнатуры базового класса
  @override
  IntValidator copyWith(
    List<BaseNumberRule<int>> rules, {
    List<Transformer<int>>? transformers,
    bool? isSecret,
  }) {
    return IntValidator(
      rules,
      transformers ?? this.transformers,
      isSecret ?? this.isSecret,
    );
  }

  // =========================================================================
  // ЯДРО ВАЛИДАЦИИ
  // =========================================================================

  @override
  ValidationResult<int> validate(dynamic value, {Path path = const []}) {
    // ЗАЩИТА 1: Сначала Guard Clause на тип.
    // Если прилетит строка "123", мы не должны пускать её в интовые трансформеры.
    if (value is! int) {
      return FlodFailure([
        FlodError(
          path,
          'Expected int',
          'invalid_type',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    // EXECUTION ORDER (5.3): Прогоняем число через конвейер трансформаций
    final dynamic rawTransformed = applyTransforms(value);
    final int transformed = rawTransformed as int;

    final errors = <FlodError>[];

    // Валидируем уже трансформированное (например, через .abs()) число
    for (final rule in rules) {
      if (!rule.check(transformed)) {
        errors.add(
          FlodError(
            path,
            rule.message,
            rule.code,
            value: transformed, // В логи летит актуальное измененное число
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
