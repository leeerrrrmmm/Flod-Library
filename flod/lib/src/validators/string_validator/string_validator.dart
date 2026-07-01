import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/rules/regexp/regex_rule.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/rules/string/custom_string_rule.dart';
import 'package:flod/src/rules/string/fixed_length_rule.dart';
import 'package:flod/src/rules/string/max_length_rule.dart';
import 'package:flod/src/rules/string/min_length_rule.dart';

class StringValidator extends Validator<String> with Transformable<String> {
  final List<BaseStringRule> rules;

  @override
  final List<Transformer<String>> transformers;

  static String _trim(dynamic v) => (v as String).trim();
  static String _toLower(dynamic v) => (v as String).toLowerCase();
  static String _toUpper(dynamic v) => (v as String).toUpperCase();

  const StringValidator([
    this.rules = const [],
    this.transformers = const [],
    bool isSecret = false,
  ]) : super(isSecret: isSecret);

  @override
  bool get isPure => rules.isEmpty && transformers.isEmpty && !isSecret;

  @override
  StringValidator secret() => isSecret ? this : copyWith(isSecret: true);

  StringValidator trim() => _copyWithTransform(_trim);
  StringValidator toLowerCase() => _copyWithTransform(_toLower);
  StringValidator toUpperCase() => _copyWithTransform(_toUpper);

  StringValidator copyWith({
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
      create: () => StringValidator(nextRules, nextTransformers, nextSecret),
    );
  }

  StringValidator _copyWithTransform(Transformer<String> transform) {
    return copyWith(transformers: ChainUtils.append(transformers, transform));
  }

  StringValidator _withRule(BaseStringRule rule) =>
      copyWith(rules: ChainUtils.append(rules, rule));

  StringValidator min(int length, {String? code}) {
    return _withRule(
      MinLengthRule(length, code: code ?? FlodErrorCodes.stringMin),
    );
  }

  StringValidator max(int length, {String? code}) {
    return _withRule(
      MaxLengthRule(length, code: code ?? FlodErrorCodes.stringMax),
    );
  }

  StringValidator length(int length, {String? code}) {
    return _withRule(
      FixedLengthRule(length, code: code ?? FlodErrorCodes.stringFixedLength),
    );
  }

  /// Deprecated — use [length].
  @Deprecated('Use length() instead.')
  StringValidator fixedLength(int len, {String? code}) =>
      length(len, code: code);

  StringValidator regex(RegExp pattern, {String? code}) {
    return _withRule(
      RegexRule(pattern, code: code ?? FlodErrorCodes.stringRegex),
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

  StringValidator uuid({String? code}) => regex(
    RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ),
    code: code ?? FlodErrorCodes.stringUuid,
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

  StringValidator minUppercase(int limit, {String? code}) => custom(
    (v) => v.replaceAll(RegExp(r'[^A-Z]'), '').length >= limit,
    code: code ?? FlodErrorCodes.stringMinUppercase,
    metaParams: {'limit': limit},
  );

  StringValidator minNumbers(int limit, {String? code}) => custom(
    (v) => v.replaceAll(RegExp(r'[^0-9]'), '').length >= limit,
    code: code ?? FlodErrorCodes.stringMinNumbers,
    metaParams: {'limit': limit},
  );

  StringValidator minSymbols(int limit, {String? code}) => custom(
    (v) => v.replaceAll(RegExp(r'[A-Za-z0-9]'), '').length >= limit,
    code: code ?? FlodErrorCodes.stringMinSymbols,
    metaParams: {'limit': limit},
  );

  StringValidator custom(
    bool Function(String value) predicate, {
    required String code,
    Map<String, dynamic>? metaParams,
  }) {
    return _withRule(
      CustomStringRule(predicate, code: code, metaParams: metaParams),
    );
  }

  @override
  ParseResult<String> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    if (value is! String) {
      return FlodFailure<String>([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {
            'expected': 'String',
            'actual': value == null ? 'null' : value.runtimeType.toString(),
          },
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }

    // 12.2 fast path — pure string type check only
    if (isPure) return FlodSuccess<String>(value);

    final String transformed = transformers.isEmpty
        ? value
        : applyTransforms(value, path);

    if (rules.isEmpty) return FlodSuccess<String>(transformed);

    final errors = <FlodError>[];
    final shouldAbort = abortEarly ?? false;

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
        if (shouldAbort) return FlodFailure<String>(errors);
      }
    }

    return errors.isEmpty
        ? FlodSuccess<String>(transformed)
        : FlodFailure<String>(errors);
  }
}
