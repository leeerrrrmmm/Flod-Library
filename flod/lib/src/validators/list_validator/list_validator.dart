import 'package:flod/flod.dart';
import 'package:flod/src/core/performance/chain_utils.dart';
import 'package:flod/src/core/transformer/transformer.dart';

/// Strictly typed list/collection validator.
/// [T] denotes the type of elements inside the list.
class ListValidator<T> extends Validator<List<T>> with Transformable<List<T>> {
  final Validator<T>? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final String? minMessage;
  final String? maxMessage;
  final bool isUnique;

  @override
  final List<Transformer<List<T>>> transformers;

  const ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.minMessage,
    this.maxMessage,
    this.isUnique = false,
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  bool get isPure =>
      schema == null &&
      minItemsLength == null &&
      maxItemsLength == null &&
      !isUnique &&
      transformers.isEmpty &&
      !isSecret;

  @override
  ListValidator<T> secret() => copyWith(isSecret: true);

  ListValidator<T> copyWith({
    Validator<T>? schema,
    int? minItemsLength,
    int? maxItemsLength,
    String? minMessage,
    String? maxMessage,
    bool? isUnique,
    List<Transformer<List<T>>>? transformers,
    bool? isSecret,
  }) {
    final nextSchema = schema ?? this.schema;
    final nextMin = minItemsLength ?? this.minItemsLength;
    final nextMax = maxItemsLength ?? this.maxItemsLength;
    final nextMinMsg = minMessage ?? this.minMessage;
    final nextMaxMsg = maxMessage ?? this.maxMessage;
    final nextUnique = isUnique ?? this.isUnique;
    final nextTransformers = transformers ?? this.transformers;
    final nextSecret = isSecret ?? this.isSecret;
    return ChainUtils.identityCopy(
      unchanged: identical(nextSchema, this.schema) &&
          nextMin == this.minItemsLength &&
          nextMax == this.maxItemsLength &&
          nextMinMsg == this.minMessage &&
          nextMaxMsg == this.maxMessage &&
          nextUnique == this.isUnique &&
          identical(nextTransformers, this.transformers) &&
          nextSecret == this.isSecret,
      current: this,
      create: () => ListValidator<T>(
        schema: nextSchema,
        minItemsLength: nextMin,
        maxItemsLength: nextMax,
        minMessage: nextMinMsg,
        maxMessage: nextMaxMsg,
        isUnique: nextUnique,
        transformers: nextTransformers,
        isSecret: nextSecret,
      ),
    );
  }

  ListValidator<T> min(int n, {String? message}) =>
      copyWith(minItemsLength: n, minMessage: message);

  ListValidator<T> max(int n, {String? message}) =>
      copyWith(maxItemsLength: n, maxMessage: message);

  /// Deprecated — use [min].
  @Deprecated('Use min() instead.')
  ListValidator<T> minItems(int n) => min(n);

  /// Deprecated — use [max].
  @Deprecated('Use max() instead.')
  ListValidator<T> maxItems(int n) => max(n);

  ListValidator<T> uniqueItems() => copyWith(isUnique: true);

  @override
  ParseResult<List<T>> validate(
    dynamic input, {
    FlodPath path = const FlodPath.empty(),
    bool? abortEarly,
  }) {
    // 1. Check base data type
    if (input == null) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.required,
          params: const {},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }

    if (input is! List) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: const {'expected': 'List', 'actual': 'Object'},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }

    final List<dynamic> rawList = input;

    // 12.2 fast path — untyped list passthrough
    if (isPure) {
      try {
        return FlodSuccess<List<T>>(List<T>.from(rawList));
      } catch (_) {
        return FlodFailure([
          FlodError(
            path: path,
            code: FlodErrorCodes.invalidType,
            params: {'expected': 'List<$T>', 'actual': 'List<Dynamic>'},
            value: input,
            isSecret: isSecret,
          ),
        ]);
      }
    }

    // Safe cast to Iterable for running transforms

    // 2. Apply transform pipeline (work with typed list)
    // Convert source list to List<T> before transformers,
    // or map elements if needed.
    List<T> baseList;
    try {
      baseList = List<T>.from(rawList);
    } catch (_) {
      return FlodFailure([
        FlodError(
          path: path,
          code: FlodErrorCodes.invalidType,
          params: {'expected': 'List<$T>', 'actual': 'List<Dynamic>'},
          value: input,
          isSecret: isSecret,
        ),
      ]);
    }

    // Apply registered list-level transformers
    baseList = applyTransforms(baseList, path);

    final errors = <FlodError>[];

    // 3. Check list length constraints
    if (minItemsLength != null && baseList.length < minItemsLength!) {
      errors.add(
        FlodError(
          path: path,
          code: FlodErrorCodes.listMinItems,
          params: {'limit': minItemsLength},
          message: minMessage,
          value: baseList,
          isSecret: isSecret,
        ),
      );
    }

    if (maxItemsLength != null && baseList.length > maxItemsLength!) {
      errors.add(
        FlodError(
          path: path,
          code: FlodErrorCodes.listMaxItems,
          params: {'limit': maxItemsLength},
          message: maxMessage,
          value: baseList,
          isSecret: isSecret,
        ),
      );
    }

    final len = baseList.length;
    final List<T?> outputList = List<T?>.filled(len, null);

    // 4. Per-element validation via nested schema
    // 12.2 — hoist secret schema once per validation
    final effectiveSchema = isSecret && schema != null ? schema!.secret() : schema;

    for (int i = 0; i < len; i++) {
      final nextPath = path.append(i);
      final item = baseList[i];

      if (effectiveSchema != null) {
        final res = effectiveSchema.validate(
          item,
          path: nextPath,
          abortEarly: abortEarly,
        );

        if (res is FlodSuccess<T>) {
          outputList[i] = res.data;
        } else if (res is FlodFailure<T>) {
          errors.addAll(res.errors);
          outputList[i] = item;
        }
      } else {
        outputList[i] = item;
      }
    }

    final validatedList = List<T>.from(outputList);

    // 5. Check uniqueness ONLY if child elements validated successfully.
    if (isUnique && errors.isEmpty) {
      final seen = <T>{};
      for (int i = 0; i < validatedList.length; i++) {
        if (!seen.add(validatedList[i])) {
          errors.add(
            FlodError(
              path: path.append(i),
              code: FlodErrorCodes.listUniqueItems,
              params: {'index': i},
              value: validatedList[i],
              isSecret: isSecret,
            ),
          );
        }
      }
    }

    return errors.isEmpty
        ? FlodSuccess<List<T>>(validatedList)
        : FlodFailure<List<T>>(errors);
  }
}
