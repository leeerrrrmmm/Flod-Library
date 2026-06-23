import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class ListValidator extends Validator<List<dynamic>>
    with Transformable<List<dynamic>> {
  final Validator? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool isUnique;

  @override
  final List<Transformer<List<dynamic>>> transformers;

  const ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.isUnique = false,
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  ListValidator secret() => copyWith(isSecret: true);

  // Метод _copyWithTransform удален, так как встроенных трансформаторов списка пока нет

  ListValidator copyWith({
    Validator? schema,
    int? minItemsLength,
    int? maxItemsLength,
    bool? isUnique,
    List<Transformer<List<dynamic>>>? transformers,
    bool? isSecret,
  }) {
    return ListValidator(
      schema: schema ?? this.schema,
      minItemsLength: minItemsLength ?? this.minItemsLength,
      maxItemsLength: maxItemsLength ?? this.maxItemsLength,
      isUnique: isUnique ?? this.isUnique,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  ListValidator minItems(int n) => copyWith(minItemsLength: n);

  ListValidator maxItems(int n) => copyWith(maxItemsLength: n);

  ListValidator uniqueItems() => copyWith(isUnique: true);

  @override
  ValidationResult<List<dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    if (value is! List) {
      return FlodFailure<List<dynamic>>([
        FlodError(
          path,
          'Expected a list',
          'invalid_type',
          value: value,
          isSecret: isSecret,
        ),
      ]);
    }

    final dynamic rawTransformed = applyTransforms(value);
    final List<dynamic> baseList = List<dynamic>.from(rawTransformed);

    final errors = <FlodError>[];

    if (minItemsLength != null && baseList.length < minItemsLength!) {
      errors.add(
        FlodError(
          path,
          'Expected at least $minItemsLength items',
          'min_items',
          value: baseList,
          isSecret: isSecret,
        ),
      );
    }

    if (maxItemsLength != null && baseList.length > maxItemsLength!) {
      errors.add(
        FlodError(
          path,
          'Expected at most $maxItemsLength items',
          'max_items',
          value: baseList,
          isSecret: isSecret,
        ),
      );
    }

    final List<dynamic> outputList = [];

    for (int i = 0; i < baseList.length; i++) {
      final nextPath = path.append(i);
      final item = baseList[i];

      if (schema != null) {
        final res = schema!.validate(item, path: nextPath);

        if (res is FlodSuccess) {
          outputList.add(res.data);
        } else if (res is FlodFailure) {
          if (isSecret) {
            final obfuscatedErrors = res.errors
                .map(
                  (e) => FlodError(
                    e.path,
                    e.message,
                    e.code,
                    value: null,
                    isSecret: true,
                  ),
                )
                .toList();
            errors.addAll(obfuscatedErrors);
          } else {
            errors.addAll(res.errors);
          }
          outputList.add(item);
        }
      } else {
        outputList.add(item);
      }
    }

    // Проверяем уникальность ТОЛЬКО если дочерние элементы успешно свалидировались.
    // Это исключает каскад ложных ошибок дубликатов на невалидных данных.
    if (isUnique && errors.isEmpty) {
      final seen = <dynamic>{};
      for (int i = 0; i < outputList.length; i++) {
        if (!seen.add(outputList[i])) {
          errors.add(
            FlodError(
              path.append(i),
              'Duplicate item found at index $i',
              'unique_items',
              value: outputList[i],
              isSecret: isSecret,
            ),
          );
        }
      }
    }

    return errors.isEmpty
        ? FlodSuccess<List<dynamic>>(outputList)
        : FlodFailure<List<dynamic>>(errors);
  }
}
