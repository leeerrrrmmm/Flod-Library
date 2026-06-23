import 'package:flod/flod.dart';

class TransformValidator<In, Out> extends Validator<Out> {
  final Validator<In> _parent;
  final Out Function(In value) _transformer;

  TransformValidator(this._parent, this._transformer, {super.isSecret});

  @override
  Validator<Out> secret() {
    // Рекурсивно прокидываем приватность по всей цепочке трансформаций вверх
    return TransformValidator<In, Out>(
      _parent.secret(),
      _transformer,
      isSecret: true,
    );
  }

  @override
  ValidationResult<Out> validate(dynamic value, {Path path = const []}) {
    final parentResult = _parent.validate(value, path: path);

    // Вычисляем результирующую приватность слоя
    final bool currentSecret = isSecret || _parent.isSecret;

    switch (parentResult) {
      case FlodFailure<In>(errors: final errs):
        // Если родитель упал и слой секретный — маскируем его ошибки на выходе
        if (currentSecret) {
          final obfuscated = errs
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
          return FlodFailure<Out>(obfuscated);
        }
        return FlodFailure<Out>(errs);

      case FlodSuccess<In>(data: final data):
        try {
          final transformed = _transformer(data);
          return FlodSuccess<Out>(transformed);
        } catch (e) {
          final transformError = FlodError(
            path,
            e.toString(),
            "transform_error",
            value: value,
            isSecret: currentSecret,
          );

          return FlodFailure<Out>([transformError]);
        }
    }
  }
}
