import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class NullableValidator<T> extends Validator<T?> with Transformable<T?> {
  final Validator<T> _inner;

  @override
  final List<Transformer<T?>> transformers;

  // Константный конструктор для сохранения иммутабельности всего дерева схем
  const NullableValidator(
    this._inner, {
    this.transformers = const [],
    super.isSecret = false,
  });

  /// Inner validator wrapped by this nullable layer.
  Validator<T> get inner => _inner;

  @override
  NullableValidator<T> secret() => copyWith(isSecret: true);

  // Метод transform удален отсюда, чтобы не ломать полиморфизм базового класса Validator<T>.
  // Теперь .transform<R>() автоматически наследуется сверху и умеет менять типы данных.

  // Обновленный copyWith, который корректно сохраняет и пробрасывает трансформеры
  NullableValidator<T> copyWith({
    Validator<T>? inner,
    List<Transformer<T?>>? transformers,
    bool? isSecret,
  }) {
    return NullableValidator<T>(
      inner ?? _inner,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T?> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  }) {
    // 1. EXECUTION ORDER (5.3): Сначала применяем трансформации уровня Nullable
    final dynamic transformed = applyTransforms(value, path);

    // 2. Логика nullability — если значение null, прерываем цепочку с успехом
    if (transformed == null) {
      return FlodSuccess<T?>(null);
    }

    // 3. Передаем управление внутреннему валидатору для проверки типа и правил
    final result = _inner.validate(
      transformed,
      path: path,
      abortEarly: abortEarly,
    );

    if (result is FlodFailure) {
      // Обфускация ошибок: если обертка секретна, стираем сырые данные из логов
      if (isSecret) {
        final obfuscatedErrors = (result as FlodFailure<T?>).errors
            .map(
              (e) => FlodError(
                path: e.path,
                code: e.code,
                params: e.params,

                value: null,
                isSecret: true,
              ),
            )
            .toList();
        return FlodFailure(obfuscatedErrors);
      }

      return FlodFailure<T?>((result as FlodFailure<T?>).errors);
    }

    // Безопасное извлечение данных через твой геттер .data
    return FlodSuccess<T?>((result as FlodSuccess<T?>).data);
  }
}

extension NullableExtension<T> on Validator<T> {
  /// Делает валидатор nullable, позволяя обрабатывать null-значения
  NullableValidator<T> nullable() => NullableValidator<T>(this);
}
