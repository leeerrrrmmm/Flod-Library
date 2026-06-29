import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

/// Строго типизированный валидатор списков/коллекций.
/// [T] обозначает тип элементов, находящихся внутри списка.
class ListValidator<T> extends Validator<List<T>> with Transformable<List<T>> {
  final Validator<T>? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool isUnique;

  @override
  final List<Transformer<List<T>>> transformers;

  const ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.isUnique = false,
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  ListValidator<T> secret() => copyWith(isSecret: true);

  ListValidator<T> copyWith({
    Validator<T>? schema,
    int? minItemsLength,
    int? maxItemsLength,
    bool? isUnique,
    List<Transformer<List<T>>>? transformers,
    bool? isSecret,
  }) {
    return ListValidator<T>(
      schema: schema ?? this.schema,
      minItemsLength: minItemsLength ?? this.minItemsLength,
      maxItemsLength: maxItemsLength ?? this.maxItemsLength,
      isUnique: isUnique ?? this.isUnique,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  ListValidator<T> minItems(int n) => copyWith(minItemsLength: n);

  ListValidator<T> maxItems(int n) => copyWith(maxItemsLength: n);

  /// Zod-compatible alias for [minItems].
  ListValidator<T> min(int n) => minItems(n);

  /// Zod-compatible alias for [maxItems].
  ListValidator<T> max(int n) => maxItems(n);

  ListValidator<T> uniqueItems() => copyWith(isUnique: true);

  @override
  ParseResult<List<T>> validate(
    dynamic input, {
    FlodPath path = const FlodPath.empty(),
    bool? abortEarly,
  }) {
    // 1. Проверяем базовый тип данных
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

    // Безопасное приведение к Iterable для выполнения трансформаций
    final List<dynamic> rawList = input;

    // 2. Применяем пайплайн трансформаций (работаем с типизированным списком)
    // Преобразуем исходный список к List<T> перед применением трансформеров,
    // либо маппим элементы, если это необходимо.
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

    // Применяем зарегистрированные трансформаторы уровня списка
    baseList = applyTransforms(baseList, path);

    final errors = <FlodError>[];

    // 3. Проверка ограничений на длину списка
    if (minItemsLength != null && baseList.length < minItemsLength!) {
      errors.add(
        FlodError(
          path: path,
          code: FlodErrorCodes.listMinItems,
          params: {'limit': minItemsLength},
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
          value: baseList,
          isSecret: isSecret,
        ),
      );
    }

    final List<T> outputList = [];

    // 4. Поэлементная валидация по вложенной схеме (schema)
    for (int i = 0; i < baseList.length; i++) {
      final nextPath = path.append(i);
      final item = baseList[i];

      if (schema != null) {
        // Передаем статус секретности вглубь
        final currentSchema = isSecret ? schema!.secret() : schema!;
        final res = currentSchema.validate(
          item,
          path: nextPath,
          abortEarly: abortEarly,
        );

        if (res is FlodSuccess<T>) {
          outputList.add(res.data);
        } else if (res is FlodFailure<T>) {
          // ЯВНО добавили <T> здесь
          // Теперь Dart гарантирует Smart Cast и видит поле `.errors`
          errors.addAll(res.errors);
          outputList.add(item);
        }
      } else {
        outputList.add(item);
      }
    }

    // 5. Проверяем уникальность ТОЛЬКО если дочерние элементы успешно свалидировались.
    if (isUnique && errors.isEmpty) {
      final seen = <T>{};
      for (int i = 0; i < outputList.length; i++) {
        if (!seen.add(outputList[i])) {
          errors.add(
            FlodError(
              path: path.append(i),
              code: FlodErrorCodes.listUniqueItems,
              params: {'index': i},
              value: outputList[i],
              isSecret: isSecret,
            ),
          );
        }
      }
    }

    return errors.isEmpty
        ? FlodSuccess<List<T>>(outputList)
        : FlodFailure<List<T>>(errors);
  }
}
