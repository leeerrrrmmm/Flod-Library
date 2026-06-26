import 'package:flod/flod.dart';

typedef Transformer<T> = T Function(dynamic value);

mixin Transformable<T> {
  // Миксин больше ничего не хранит сам. Он лишь требует список от наследника
  List<Transformer<T>> get transformers;

  dynamic applyTransforms(dynamic initialValue, FlodPath path) {
    dynamic current = initialValue;
    for (final transformer in transformers) {
      final result = transformer(current);

      // Если трансформер вернул ошибку вложенной валидации — перехватываем её!
      if (result is FlodFailure) {
        // Бросаем специальный внутренний Exception, который ядро валидатора
        // перехватит и корректно добавит в общий массив ошибок.
        throw FlodTransformerException(result.errors);
      }

      current = result;
    }
    return current;
  }
}

/// Специальное исключение для прерывания пайплайна трансформаций
class FlodTransformerException implements Exception {
  final List<FlodError> errors;
  const FlodTransformerException(this.errors);
}
