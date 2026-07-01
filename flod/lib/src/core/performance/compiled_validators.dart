import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/core/validator.dart';
import 'package:flod/src/validators/object_validator/object_validator.dart';

/// Pre-resolved object field for fast iteration without per-call [secret] wrapping.
final class CompiledObjectField {
  final String key;
  final Validator validator;

  const CompiledObjectField(this.key, this.validator);
}

/// 12.3 — compiled object validator with pre-resolved field validators.
final class CompiledObjectValidator extends Validator<Map<String, dynamic>> {
  final List<CompiledObjectField> fields;
  final Set<String> schemaKeys;
  final ObjectMode mode;
  final bool abortEarly;
  final List<Transformer<Map<String, dynamic>>> transformers;

  const CompiledObjectValidator({
    required this.fields,
    required this.schemaKeys,
    required this.mode,
    required this.abortEarly,
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  bool get isCompiled => true;

  @override
  bool get isPure =>
      fields.isEmpty && transformers.isEmpty && mode == ObjectMode.passthrough;

  @override
  CompiledObjectValidator secret() {
    if (isSecret) return this;
    return CompiledObjectValidator(
      fields: fields
          .map((f) => CompiledObjectField(f.key, f.validator.secret()))
          .toList(growable: false),
      schemaKeys: schemaKeys,
      mode: mode,
      abortEarly: abortEarly,
      transformers: transformers,
      isSecret: true,
    );
  }

  @override
  CompiledObjectValidator stopOnFirstError() {
    if (abortEarly) return this;
    return CompiledObjectValidator(
      fields: fields,
      schemaKeys: schemaKeys,
      mode: mode,
      abortEarly: true,
      transformers: transformers,
      isSecret: isSecret,
    );
  }

  @override
  CompiledObjectValidator strict() {
    if (mode == ObjectMode.strict) return this;
    return CompiledObjectValidator(
      fields: fields,
      schemaKeys: schemaKeys,
      mode: ObjectMode.strict,
      abortEarly: abortEarly,
      transformers: transformers,
      isSecret: isSecret,
    );
  }

  @override
  Validator? getFieldSchema(String key) {
    for (final field in fields) {
      if (field.key == key) return field.validator;
    }
    return null;
  }

  @override
  ParseResult<Map<String, dynamic>> validate(
    dynamic value, {
    FlodPath path = const FlodPath.empty(),
    bool? abortEarly,
  }) {
    final effectiveAbortEarly = abortEarly ?? this.abortEarly;

    if (value is! Map) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {'expected': 'Map', 'actual': value.runtimeType.toString()},
          value: isSecret ? null : value,
          isSecret: isSecret,
        ),
      ]);
    }

    dynamic rawTransformed = value;
    if (transformers.isNotEmpty) {
      rawTransformed = _applyTransforms(value, path);
    }
    if (rawTransformed is! Map) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {
            'expected': 'Map',
            'actual': rawTransformed.runtimeType.toString(),
          },
          value: isSecret ? null : rawTransformed,
          isSecret: isSecret,
        ),
      ]);
    }

    final Map<String, dynamic> transformed = Map<String, dynamic>.from(
      rawTransformed,
    );
    final Map<String, dynamic> outputResult = {};
    List<FlodError>? errors;

    if (mode == ObjectMode.strict) {
      for (final key in transformed.keys) {
        if (!schemaKeys.contains(key)) {
          errors ??= [];
          errors.add(
            FlodError(
              path: path.append(key),
              code: FlodErrorCodes.objectStrict,
              params: {'key': key},
              value: isSecret ? null : transformed[key],
              isSecret: isSecret,
            ),
          );
          if (effectiveAbortEarly) return FlodFailure(errors);
        }
      }
    }

    for (final field in fields) {
      final key = field.key;
      final hasKey = transformed.containsKey(key);
      final fieldValue = hasKey ? transformed[key] : null;

      final result = field.validator.validate(
        fieldValue,
        path: path.append(key),
        abortEarly: effectiveAbortEarly,
      );

      if (result is FlodSuccess) {
        if (result.data != null || hasKey) {
          outputResult[key] = result.data;
        }
      } else {
        errors ??= [];
        errors.addAll((result as FlodFailure).errors);
        if (effectiveAbortEarly) return FlodFailure(errors);
      }
    }

    if (errors != null && errors.isNotEmpty) return FlodFailure(errors);

    if (mode == ObjectMode.passthrough) {
      transformed.forEach((key, val) {
        if (!schemaKeys.contains(key)) {
          outputResult[key.toString()] = val;
        }
      });
    }

    return FlodSuccess(outputResult);
  }

  dynamic _applyTransforms(dynamic initialValue, FlodPath path) {
    dynamic current = initialValue;
    for (final transformer in transformers) {
      current = transformer(current);
    }
    return current;
  }
}

/// 12.3 — compiled list validator with hoisted item schema.
final class CompiledListValidator<T> extends Validator<List<T>> {
  final Validator<T>? itemSchema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool isUnique;
  final List<Transformer<List<T>>> transformers;

  const CompiledListValidator({
    this.itemSchema,
    this.minItemsLength,
    this.maxItemsLength,
    this.isUnique = false,
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  bool get isCompiled => true;

  @override
  bool get isPure =>
      itemSchema == null &&
      minItemsLength == null &&
      maxItemsLength == null &&
      !isUnique &&
      transformers.isEmpty &&
      !isSecret;

  @override
  CompiledListValidator<T> secret() {
    if (isSecret) return this;
    return CompiledListValidator<T>(
      itemSchema: itemSchema?.secret(),
      minItemsLength: minItemsLength,
      maxItemsLength: maxItemsLength,
      isUnique: isUnique,
      transformers: transformers,
      isSecret: true,
    );
  }

  @override
  ParseResult<List<T>> validate(
    dynamic input, {
    FlodPath path = const FlodPath.empty(),
    bool? abortEarly,
  }) {
    final shouldAbort = abortEarly ?? false;

    if (input == null) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.required,
          params: const {},
          value: null,
          isSecret: isSecret,
        ),
      ]);
    }

    if (input is! List) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {'expected': 'List', 'actual': input.runtimeType.toString()},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }

    final len = input.length;

    if (minItemsLength != null && len < minItemsLength!) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.listMinItems,
          params: {'limit': minItemsLength},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }
    if (maxItemsLength != null && len > maxItemsLength!) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.listMaxItems,
          params: {'limit': maxItemsLength},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }

    final schema = itemSchema;
    final List<T?> outputList = List<T?>.filled(len, null);
    List<FlodError>? errors;

    for (var i = 0; i < len; i++) {
      final item = input[i];
      final currentPath = path.append(i);

      if (schema != null) {
        final res = schema.validate(
          item,
          path: currentPath,
          abortEarly: abortEarly,
        );
        if (res is FlodSuccess<T>) {
          outputList[i] = res.data;
        } else {
          errors ??= [];
          errors.addAll((res as FlodFailure).errors);
          if (shouldAbort) return FlodFailure(errors);
          if (item is T) outputList[i] = item;
        }
      } else if (item is T) {
        outputList[i] = item;
      } else {
        errors ??= [];
        errors.add(
          FlodError(
            path: currentPath,
            code: FlodErrorCodes.invalidType,
            params: const {},
            value: item,
          ),
        );
        if (shouldAbort) return FlodFailure(errors);
      }
    }

    if (isUnique && (errors == null || errors.isEmpty)) {
      final seen = <T?>{};
      for (var i = 0; i < len; i++) {
        if (!seen.add(outputList[i])) {
          errors ??= [];
          errors.add(
            FlodError(
              path: path.append(i),
              code: FlodErrorCodes.listUniqueItems,
              params: {'index': i},
              value: outputList[i],
              isSecret: isSecret,
            ),
          );
          if (shouldAbort) break;
        }
      }
    }

    if (errors != null && errors.isNotEmpty) {
      return FlodFailure(errors);
    }

    var validatedList = List<T>.from(outputList);
    if (transformers.isNotEmpty) {
      for (final transformer in transformers) {
        validatedList = transformer(validatedList);
      }
    }

    return FlodSuccess(validatedList);
  }
}

/// Generic compiled wrapper that marks a validator tree as optimized.
final class CompiledValidator<T> extends Validator<T> {
  final Validator<T> _inner;

  const CompiledValidator(this._inner, {super.isSecret = false});

  @override
  bool get isCompiled => true;

  @override
  bool get isPure => _inner.isPure;

  Validator<T> get inner => _inner;

  @override
  CompiledValidator<T> secret() {
    if (isSecret) return this;
    return CompiledValidator(_inner.secret(), isSecret: true);
  }

  @override
  Validator? getFieldSchema(String key) => _inner.getFieldSchema(key);

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath.empty(),
    bool? abortEarly,
  }) {
    return _inner.validate(value, path: path, abortEarly: abortEarly);
  }
}

