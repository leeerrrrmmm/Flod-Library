import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/error.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/rules/string/base_string_rule.dart';
import 'package:flod/src/rules/regexp/custom_regexp_rule.dart';
import 'package:flod/src/rules/string/fixed_length_rule.dart';
import 'package:flod/src/rules/string/max_length_rule.dart';
import 'package:flod/src/rules/string/min_length_rule.dart';
import 'package:flod/src/rules/regexp/regex_rule.dart';
import 'package:flod/src/types/path.dart';

class StringValidator extends Validator<String> with Transformable<String> {
  final List<BaseStringRule> rules;
  final List<Transformer<String>> _capturedTransformers;

  StringValidator([
    this.rules = const [],
    List<Transformer<String>> capturedTransformers = const [],
    bool isSecret = false,
  ]) : _capturedTransformers = List.from(capturedTransformers),
       super(isSecret: isSecret) {
    for (final transform in _capturedTransformers) {
      super.addTransform(transform);
    }
  }

  @override
  StringValidator secret() => copyWith(isSecret: true);

  @override
  void addTransform(Transformer<String> transform) {
    _capturedTransformers.add(transform);
    super.addTransform(transform);
  }

  StringValidator copyWith({List<BaseStringRule>? rules, bool? isSecret}) {
    return StringValidator(
      rules ?? this.rules,
      _capturedTransformers,
      isSecret ?? this.isSecret,
    );
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

  @override
  ValidationResult<String> validate(dynamic value, {Path path = const []}) {
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

    final String transformed = applyTransforms(value);
    final errors = <FlodError>[];

    for (final rule in rules) {
      final result = rule.check(transformed);

      if (!result) {
        errors.add(
          FlodError(
            path,
            rule.message,
            rule.code,
            value: transformed,
            isSecret: isSecret,
          ),
        );
      }
    }

    return errors.isEmpty ? FlodSuccess(transformed) : FlodFailure(errors);
  }
}
