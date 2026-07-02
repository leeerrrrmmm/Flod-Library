import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
import 'package:flod/src/core/transformer/transformer.dart';
import 'package:flod/src/validators/object_validator/object_composition.dart';

enum ObjectMode { strict, passthrough }

class ObjectValidator extends Validator<Map<String, dynamic>>
    with Transformable<Map<String, dynamic>> {
  final Map<String, Validator> schema;
  final ObjectMode mode;
  final bool abortEarly;

  @override
  final List<Transformer<Map<String, dynamic>>> transformers;

  const ObjectValidator(
    this.schema, {
    this.mode = ObjectMode.passthrough,
    this.transformers = const [],
    super.isSecret = false,
    this.abortEarly = false,
  });

  @override
  bool get isPure =>
      schema.isEmpty &&
      transformers.isEmpty &&
      mode == ObjectMode.passthrough &&
      !abortEarly &&
      !isSecret;

  @override
  Validator? getFieldSchema(String key) => schema[key];

  @override
  ObjectValidator secret() => copyWith(isSecret: true);
  @override
  ObjectValidator stopOnFirstError() => copyWith(abortEarly: true);
  @override
  ObjectValidator strict() => copyWith(mode: ObjectMode.strict);

  ObjectValidator passthrough() => copyWith(mode: ObjectMode.passthrough);

  /// Adds or overrides keys. Later keys in [shape] win on conflict (Zod `.extend()`).
  ObjectValidator extend(Map<String, Validator> shape) {
    return copyWith(schema: {...schema, ...shape});
  }

  /// Merges another object schema into this one (Zod `.merge()`).
  ObjectValidator merge(ObjectValidator other) => extend(other.schema);

  /// Makes every field optional; [deep] recursively partializes nested objects.
  ObjectValidator partial({bool deep = true}) {
    return copyWith(schema: partializeSchema(schema, deep: deep));
  }

  /// Keeps only the listed keys (Zod `.pick()`).
  ObjectValidator pick(Iterable<String> keys) {
    return copyWith(
      schema: {
        for (final key in keys)
          if (schema.containsKey(key)) key: schema[key]!,
      },
    );
  }

  /// Removes the listed keys (Zod `.omit()`).
  ObjectValidator omit(Iterable<String> keys) {
    final omitted = Map<String, Validator>.from(schema)
      ..removeWhere((key, _) => keys.contains(key));
    return copyWith(schema: omitted);
  }

  ObjectValidator copyWith({
    Map<String, Validator>? schema,
    ObjectMode? mode,
    List<Transformer<Map<String, dynamic>>>? transformers,
    bool? isSecret,
    bool? abortEarly,
  }) {
    final nextSchema = schema ?? this.schema;
    final nextMode = mode ?? this.mode;
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    final nextAbortEarly = abortEarly ?? this.abortEarly;
    return ChainUtils.identityCopy(
      unchanged:
          identical(nextSchema, this.schema) &&
          nextMode == this.mode &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret &&
          nextAbortEarly == this.abortEarly,
      current: this,
      create: () => ObjectValidator(
        nextSchema,
        mode: nextMode,
        transformers: nextTransformers,
        isSecret: nextSecret,
        abortEarly: nextAbortEarly,
      ),
    );
  }

  @override
  ParseResult<Map<String, dynamic>> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly, // Dynamic flag propagation from top-level safeParse
  }) {
    FlodDebug.trace(
      'enter',
      validator: 'ObjectValidator',
      path: path,
      value: value,
      isSecret: isSecret,
    );

    // Dynamic flag takes priority (e.g. from safeParse), otherwise use schema default
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

    // Apply transforms strictly BEFORE validation (Map section 5.3)
    final dynamic rawTransformed = applyTransforms(value, path);
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

    // Read-only access: skip Map.from defensive copy on the hot path.
    final Map source = rawTransformed;
    final Map<String, dynamic> outputResult = {};
    final errors = <FlodError>[];

    // 1. Check for extra keys in .strict() mode (Map section 3.1)
    if (mode == ObjectMode.strict) {
      for (final key in source.keys) {
        if (!schema.containsKey(key)) {
          final error = FlodError(
            path: path.append(key is String ? key : key.toString()),
            code: FlodErrorCodes.objectStrict,
            params: {'key': key},
            value: isSecret ? null : source[key],
            isSecret: isSecret,
          );

          // IMMEDIATE EXIT: Save CPU resources, do not continue
          if (effectiveAbortEarly) return FlodFailure([error]);
          errors.add(error);
        }
      }
    }

    // 2. Main schema field traversal loop
    // 12.2 — pre-resolve secret wrappers once per validation
    final parentSecret = isSecret;
    for (final entry in schema.entries) {
      final key = entry.key;
      final validator = entry.value;
      final effectiveValidator = parentSecret && !validator.isSecret
          ? validator.secret()
          : validator;

      if (source.containsKey(key)) {
        final fieldValue = source[key];

        // Recursively propagate effectiveAbortEarly down the tree
        final result = effectiveValidator.validate(
          fieldValue,
          path: path.append(key),
          abortEarly: effectiveAbortEarly,
        );

        if (result is FlodSuccess) {
          outputResult[key] = result.data;
        } else if (result is FlodFailure) {
          // IMMEDIATE EXIT: If child failed, break the object schema loop!
          if (effectiveAbortEarly) {
            return FlodFailure([result.errors.first]);
          }
          errors.addAll(result.errors);
        }
      } else {
        // Validate missing field via "black box" concept
        final result = effectiveValidator.validate(
          null,
          path: path.append(key),
          abortEarly: effectiveAbortEarly,
        );

        if (result is FlodSuccess) {
          outputResult[key] =
              result.data; // .default() fill or .optional() skip
        } else if (result is FlodFailure) {
          final error = FlodError(
            path: path.append(key),
            code: FlodErrorCodes.required,
            params: {'key': key},
            value: null,
            isSecret: isSecret,
          );

          // IMMEDIATE EXIT: Save CPU cycles when required field is missing
          if (effectiveAbortEarly) return FlodFailure([error]);
          errors.add(error);
        }
      }
    }

    if (errors.isNotEmpty) {
      FlodDebug.trace(
        'fail',
        validator: 'ObjectValidator',
        path: path,
        detail: '${errors.length} error(s)',
        isSecret: isSecret,
      );
      return FlodFailure(errors);
    }

    // On success, merge non-validated keys in passthrough mode
    if (mode == ObjectMode.passthrough) {
      for (final key in source.keys) {
        if (!schema.containsKey(key)) {
          outputResult[key is String ? key : key.toString()] = source[key];
        }
      }
    }

    FlodDebug.trace(
      'ok',
      validator: 'ObjectValidator',
      path: path,
      value: outputResult,
      isSecret: isSecret,
    );

    return FlodSuccess<Map<String, dynamic>>(outputResult);
  }
}
