import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';

class DoubleValidator extends BaseNumberValidator<double>
    with Transformable<double> {
  @override
  final List<Transformer<double>> transformers;

  // Константный конструктор с правильным пробросом super-параметров
  const DoubleValidator([
    super.rules = const [],
    this.transformers = const [],
    super.isSecret,
  ]);

  @override
  DoubleValidator secret() => copyWith(rules, isSecret: true);

  /// Иммутабельный метод добавления трансформации для дробных чисел
  DoubleValidator _copyWithTransform(Transformer<double> transform) {
    return copyWith(rules, transformers: [...transformers, transform]);
  }

  // =========================================================================
  // ВСТРОЕННЫЕ ЧИСЛОВЫЕ ТРАНСФОРМЕРЫ
  // =========================================================================

  /// Автоматически берет модуль числа перед валидацией
  DoubleValidator abs() => _copyWithTransform((v) => (v as double).abs());

  // =========================================================================
  // МЕНЕДЖМЕНТ СОСТОЯНИЯ СХЕМЫ (Валидный override сигнатуры)
  // =========================================================================

  @override
  DoubleValidator copyWith(
    List<BaseNumberRule<double>> rules, {
    List<Transformer<double>>? transformers,
    bool? isSecret,
  }) {
    return DoubleValidator(
      rules,
      transformers ?? this.transformers,
      isSecret ?? this.isSecret,
    );
  }

  // =========================================================================
  // ЯДРО ВАЛИДАЦИИ
  // =========================================================================

  @override
  ParseResult<double> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    // ЗАЩИТА 1: Сначала проверяем тип, оберегая конвейер трансформаций от падений
    if (value is! double) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {
            'expected': 'double',
            'actual': value.runtimeType.toString(),
          },
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }

    // EXECUTION ORDER (5.3): Прогоняем число через пайплайн трансформаций
    final dynamic rawTransformed = applyTransforms(value, path);
    final double transformed = rawTransformed as double;

    // ЗАЩИТА 2: Проверяем на Finite / NaN уже трансформированное число
    if (!transformed.isFinite) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidNumber,
          params: {'value': transformed},
          value: isSecret
              ? null
              : transformed, // В лог уходит актуальное состояние
          isSecret: isSecret,
        ),
      ]);
    }

    final errors = <FlodError>[];

    // Валидация по цепочке доменных правил
    for (final rule in rules) {
      if (!rule.check(transformed)) {
        errors.add(
          FlodError(
            path: path,
            code: rule.code,
            params: rule.params,
            value: isSecret ? null : transformed,
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty
        ? FlodSuccess<double>(transformed)
        : FlodFailure<double>(errors);
  }
}
