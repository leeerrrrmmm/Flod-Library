import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
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
  bool get isPure => rules.isEmpty && transformers.isEmpty && !isSecret;

  @override
  DoubleValidator secret() => isSecret ? this : copyWith(rules, isSecret: true);

  DoubleValidator _copyWithTransform(Transformer<double> transform) {
    return copyWith(rules, transformers: ChainUtils.append(transformers, transform));
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
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged: identical(rules, this.rules) &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () => DoubleValidator(rules, nextTransformers, nextSecret),
    );
  }

  @override
  DoubleValidator positive({String? code}) =>
      super.positive(code: code) as DoubleValidator;

  @override
  DoubleValidator nonPositive({String? code}) =>
      super.nonPositive(code: code) as DoubleValidator;

  @override
  DoubleValidator negative({String? code}) =>
      super.negative(code: code) as DoubleValidator;

  @override
  DoubleValidator nonNegative({String? code}) =>
      super.nonNegative(code: code) as DoubleValidator;

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

    if (!value.isFinite) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidNumber,
          params: {'value': value},
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }

    // 12.2 fast path — pure double type check only (after finite guard)
    if (isPure) return FlodSuccess<double>(value);

    final dynamic rawTransformed = transformers.isEmpty
        ? value
        : applyTransforms(value, path);
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
