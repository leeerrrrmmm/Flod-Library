import 'package:flod/src/error.dart';
import 'package:flod/src/extensions/list_extension.dart';
import 'package:flod/src/res/validation_result.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/validator.dart';

class ListValidator extends Validator<List<dynamic>> {
  final Validator? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool? uniqueItems;

  ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.uniqueItems = false,
  });

  ListValidator minItems(int n) => ListValidator(
    schema: schema,
    minItemsLength: n,
    maxItemsLength: maxItemsLength,
    uniqueItems: uniqueItems,
  );

  ListValidator maxItems(int n) => ListValidator(
    schema: schema,
    minItemsLength: minItemsLength,
    maxItemsLength: n,
    uniqueItems: uniqueItems,
  );

  ListValidator unique() => ListValidator(
    schema: schema,
    minItemsLength: minItemsLength,
    maxItemsLength: maxItemsLength,
    uniqueItems: true,
  );

  @override
  ValidationResult<List<dynamic>> validate(
    dynamic value, {
    Path path = const [],
  }) {
    if (value is! List) {
      return FlodFailure<List<dynamic>>([
        FlodError(path, 'Expected a list', 'invalid_type'),
      ]);
    }

    final list = value;

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

    if (uniqueItems == true) {
      final seen = <dynamic>{};
      for (int i = 0; i < list.length; i++) {
        if (!seen.add(list[i])) {
          // Здесь мы создаем путь, указывающий на конкретный индекс дубликата
          final errorPath = path.append(i);
          return FlodFailure<List<dynamic>>([
            FlodError(
              errorPath as Path,
              'Duplicate item found at index $i',
              'unique_items',
            ),
          ]);
        }
      }
    }

    if (schema != null) {
      for (int i = 0; i < list.length; i++) {
        // Убедись, что path — это список (или используй свой метод добавления)
        final nextPath = path.append(i);
        final res = schema!.validate(list[i], path: nextPath as Path);

        if (res is FlodFailure) {
          // Приводим ошибку дочернего элемента к типу List
          return FlodFailure<List<dynamic>>(res.errors);
        }
      }
    }

    return FlodSuccess<List<dynamic>>(list);
  }
}
