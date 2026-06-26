import 'package:flod/flod.dart';
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

  const StringValidator([
    this.rules = const [],
    this.transformers = const [],
    bool isSecret = false,
  ]) : super(isSecret: isSecret);

  @override
  StringValidator secret() => copyWith(isSecret: true);

  StringValidator trim() => _copyWithTransform((v) => v.trim());
  StringValidator toLowerCase() => _copyWithTransform((v) => v.toLowerCase());
  StringValidator toUpperCase() => _copyWithTransform((v) => v.toUpperCase());

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

  StringValidator min(int length, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        MinLengthRule(length, code: code ?? FlodErrorCodes.stringMin),
      ],
    );
  }

  StringValidator max(int length, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        MaxLengthRule(length, code: code ?? FlodErrorCodes.stringMax),
      ],
    );
  }

  StringValidator fixedLength(int length, {String? code}) {
    return copyWith(
      rules: [
        ...rules,
        FixedLengthRule(length, code: code ?? FlodErrorCodes.stringFixedLength),
      ],
    );
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

  StringValidator creditCard({String? code}) => custom((v) {
    int sum = 0;
    bool alternate = false;
    for (int i = v.length - 1; i >= 0; i--) {
      int n = int.tryParse(v[i]) ?? 0;
      if (alternate) {
        n *= 2;
        if (n > 9) n = (n % 10) + 1;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }, code: code ?? FlodErrorCodes.stringCreditCard);

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
    return copyWith(
      rules: [
        ...rules,
        CustomStringRule(predicate, code: code, metaParams: metaParams),
      ],
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

    final String transformed = applyTransforms(value, path);
    final errors = <FlodError>[];

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
        ? FlodSuccess<String>(transformed)
        : FlodFailure<String>(errors);
  }
}
