import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class ListValidator extends Validator<List<dynamic>>
    with Transformable<List<dynamic>> {
  final Validator? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool isUnique; // ИСПРАВЛЕНИЕ: Переименовали поле во избежание конфликта

  ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.isUnique = false, // По умолчанию false
  });

  ListValidator minItems(int n) => ListValidator(
    schema: schema,
    minItemsLength: n,
    maxItemsLength: maxItemsLength,
    isUnique: isUnique,
  );

  ListValidator maxItems(int n) => ListValidator(
    schema: schema,
    minItemsLength: minItemsLength,
    maxItemsLength: n,
    isUnique: isUnique,
  );

  // ИСПРАВЛЕНИЕ: Метод теперь называется строго по твоему чек-листу
  ListValidator uniqueItems() => ListValidator(
    schema: schema,
    minItemsLength: minItemsLength,
    maxItemsLength: maxItemsLength,
    isUnique: true,
  );

  @override
  ValidationResult<List<dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    final dynamic transformed = applyTransforms(value);

    if (transformed is! List) {
      return FlodFailure<List<dynamic>>([
        FlodError(path, 'Expected a list', 'invalid_type'),
      ]);
    }

    final list = transformed;

    if (minItemsLength != null && list.length < minItemsLength!) {
      return FlodFailure<List<dynamic>>([
        FlodError(path, 'Expected at least $minItemsLength items', 'min_items'),
      ]);
    }

    if (maxItemsLength != null && list.length > maxItemsLength!) {
      return FlodFailure<List<dynamic>>([
        FlodError(path, 'Expected at most $maxItemsLength items', 'max_items'),
      ]);
    }

    // ИСПРАВЛЕНИЕ: Проверяем флаг через новое имя поля
    if (isUnique) {
      final seen = <dynamic>{};
      for (int i = 0; i < list.length; i++) {
        if (!seen.add(list[i])) {
          final errorPath = path.append(i);
          return FlodFailure<List<dynamic>>([
            FlodError(
              errorPath,
              'Duplicate item found at index $i',
              'unique_items',
            ),
          ]);
        }
      }
    }

    if (schema != null) {
      for (int i = 0; i < list.length; i++) {
        final nextPath = path.append(i);
        final res = schema!.validate(list[i], path: nextPath);

        // ИСПРАВЛЕНИЕ: Используем твой новый sealed-API геттер result.isFailure
        if (res.isFailure) {
          return FlodFailure<List<dynamic>>(res.errors);
        }
      }
    }

    return FlodSuccess<List<dynamic>>(List<dynamic>.from(list));
  }
}
