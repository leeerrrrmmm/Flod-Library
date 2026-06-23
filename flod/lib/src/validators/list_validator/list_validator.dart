import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class ListValidator extends Validator<List<dynamic>>
    with Transformable<List<dynamic>> {
  final Validator? schema;
  final int? minItemsLength;
  final int? maxItemsLength;
  final bool isUnique;

  // Конструктор принимает super.isSecret и передает его в Validator
  ListValidator({
    this.schema,
    this.minItemsLength,
    this.maxItemsLength,
    this.isUnique = false,
    super.isSecret,
  });

  // Реализуем контракт из базового класса Validator
  @override
  ListValidator secret() => copyWith(isSecret: true);

  // Кастомный copyWith для удобного управления состоянием
  ListValidator copyWith({
    Validator? schema,
    int? minItemsLength,
    int? maxItemsLength,
    bool? isUnique,
    bool? isSecret,
  }) {
    return ListValidator(
      schema: schema ?? this.schema,
      minItemsLength: minItemsLength ?? this.minItemsLength,
      maxItemsLength: maxItemsLength ?? this.maxItemsLength,
      isUnique: isUnique ?? this.isUnique,
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
    final dynamic transformed = applyTransforms(value);

    if (transformed is! List) {
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

    final list = transformed;

    if (minItemsLength != null && list.length < minItemsLength!) {
      return FlodFailure<List<dynamic>>([
        FlodError(
          path,
          'Expected at least $minItemsLength items',
          'min_items',
          value: list,
          isSecret: isSecret,
        ),
      ]);
    }

    if (maxItemsLength != null && list.length > maxItemsLength!) {
      return FlodFailure<List<dynamic>>([
        FlodError(
          path,
          'Expected at most $maxItemsLength items',
          'max_items',
          value: list,
          isSecret: isSecret,
        ),
      ]);
    }

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
              value: list[i],
              isSecret:
                  isSecret, // Если весь список приватный — маскируем элемент
            ),
          ]);
        }
      }
    }

    if (schema != null) {
      for (int i = 0; i < list.length; i++) {
        final nextPath = path.append(i);
        final res = schema!.validate(list[i], path: nextPath);

        if (res.isFailure) {
          // Если родительский список помечен как .secret(),
          // нам нужно пересобрать ошибки вложенной схемы, чтобы скрыть данные!
          if (isSecret) {
            final obfuscatedErrors = res.errors
                .map(
                  (e) => FlodError(
                    e.path,
                    e.message,
                    e.code,
                    value:
                        null, // Принудительно затираем, так как родитель секретен
                    isSecret: true,
                  ),
                )
                .toList();
            return FlodFailure<List<dynamic>>(obfuscatedErrors);
          }

          return FlodFailure<List<dynamic>>(res.errors);
        }
      }
    }

    return FlodSuccess<List<dynamic>>(List<dynamic>.from(list));
  }
}
