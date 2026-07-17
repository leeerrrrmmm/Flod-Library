import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/rules/numbers/base_number_rule.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/validators/coerce/coerce_utils.dart';

/// Entry point for Zod-style coercion: [Flod.coerce].
///
/// Coercion runs **before** type checks and rule chains, so form/API string
/// payloads can feed the same schema as typed JSON.
final class FlodCoerce {
  const FlodCoerce();

  /// Coerce → [int], then apply [IntValidator] rules (`.min`, `.positive`, …).
  ///
  /// Accepts: `int`, other `num`, numeric `String` (`"42"`), `bool` (`true`→1).
  CoerceIntValidator int() => const CoerceIntValidator();

  /// Coerce → [double], then apply [DoubleValidator] rules.
  ///
  /// Accepts: `double`, `int`/`num`, numeric `String` (`"3.14"`), `bool`.
  CoerceDoubleValidator double() => const CoerceDoubleValidator();

  /// Coerce → [bool].
  ///
  /// Accepts: `bool`; `0`/`1`; strings `true`/`false`/`1`/`0`/`yes`/`no`/`on`/`off`
  /// (case-insensitive).
  CoerceBoolValidator boolean() => const CoerceBoolValidator();

  /// Coerce → [String] via [Object.toString] (Strings pass through).
  CoerceStringValidator string() => const CoerceStringValidator();
}

/// [IntValidator] that coerces input before validation.
class CoerceIntValidator extends IntValidator {
  const CoerceIntValidator([
    super.rules = const [],
    super.transformers = const [],
    super.isSecret = false,
  ]);

  @override
  CoerceIntValidator secret() =>
      isSecret ? this : copyWith(isSecret: true);

  @override
  CoerceIntValidator copyWith({
    List<BaseNumberRule<int>>? rules,
    List<Transformer<int>>? transformers,
    bool? isSecret,
  }) {
    final nextRules = rules ?? this.rules;
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged:
          identical(nextRules, this.rules) &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () => CoerceIntValidator(nextRules, nextTransformers, nextSecret),
    );
  }

  @override
  ParseResult<int> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    if (value == null) {
      return super.validate(null, path: path, abortEarly: abortEarly);
    }
    final coerced = CoerceUtils.toInt(value);
    if (coerced == null) {
      return FlodFailure<int>([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {
            'expected': 'int',
            'actual': value.runtimeType.toString(),
          },
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }
    return super.validate(coerced, path: path, abortEarly: abortEarly);
  }
}

/// [DoubleValidator] that coerces input before validation.
class CoerceDoubleValidator extends DoubleValidator {
  const CoerceDoubleValidator([
    super.rules = const [],
    super.transformers = const [],
    super.isSecret = false,
  ]);

  @override
  CoerceDoubleValidator secret() =>
      isSecret ? this : copyWith(rules, isSecret: true);

  @override
  CoerceDoubleValidator copyWith(
    List<BaseNumberRule<double>> rules, {
    List<Transformer<double>>? transformers,
    bool? isSecret,
  }) {
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged:
          identical(rules, this.rules) &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () =>
          CoerceDoubleValidator(rules, nextTransformers, nextSecret),
    );
  }

  @override
  ParseResult<double> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    if (value == null) {
      return super.validate(null, path: path, abortEarly: abortEarly);
    }
    final coerced = CoerceUtils.toDouble(value);
    if (coerced == null) {
      return FlodFailure<double>([
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
    return super.validate(coerced, path: path, abortEarly: abortEarly);
  }
}

/// [BoolValidator] that coerces input before validation.
class CoerceBoolValidator extends BoolValidator {
  const CoerceBoolValidator({super.isSecret = false});

  @override
  CoerceBoolValidator secret() =>
      isSecret ? this : const CoerceBoolValidator(isSecret: true);

  @override
  ParseResult<bool> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    if (value == null) {
      return super.validate(null, path: path, abortEarly: abortEarly);
    }
    final coerced = CoerceUtils.toBool(value);
    if (coerced == null) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {
            'expected': 'bool',
            'actual': value.runtimeType.toString(),
          },
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }
    return super.validate(coerced, path: path, abortEarly: abortEarly);
  }
}

/// [StringValidator] that coerces non-strings via [Object.toString].
class CoerceStringValidator extends StringValidator {
  const CoerceStringValidator([
    super.rules = const [],
    super.transformers = const [],
    super.isSecret = false,
  ]);

  @override
  CoerceStringValidator secret() =>
      isSecret ? this : copyWith(isSecret: true);

  @override
  CoerceStringValidator copyWith({
    List<BaseStringRule>? rules,
    List<Transformer<String>>? transformers,
    bool? isSecret,
  }) {
    final nextRules = rules ?? this.rules;
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged:
          identical(nextRules, this.rules) &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () =>
          CoerceStringValidator(nextRules, nextTransformers, nextSecret),
    );
  }

  @override
  ParseResult<String> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    if (value == null) {
      return super.validate(null, path: path, abortEarly: abortEarly);
    }
    final coerced = CoerceUtils.toStringValue(value);
    if (coerced == null) {
      return super.validate(value, path: path, abortEarly: abortEarly);
    }
    return super.validate(coerced, path: path, abortEarly: abortEarly);
  }
}
