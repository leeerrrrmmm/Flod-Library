// import 'package:flod/src/types/flod_error.dart';

// sealed class ValidationResult<T> {
//   const ValidationResult();

//   ValidationResult.flodFailure(List<FlodError> errors);

//   bool get isSuccess => this is FlodSuccess<T>;
//   bool get isFailure => this is FlodFailure<T>;

//   T get data {
//     if (this case FlodSuccess<T>(data: final d)) return d;
//     throw StateError('Try to get data from FlodFailure');
//   }

//   List<FlodError> get errors {
//     if (this case FlodFailure<T>(errors: final e)) return e;
//     throw StateError('Try to get errors from FlodSuccess');
//   }

//   // Позволяет удобно прокинуть результат дальше
//   R fold<R>(
//     R Function(List<FlodError> errors) onFailure,
//     R Function(T data) onSuccess,
//   ) {
//     return switch (this) {
//       FlodFailure(errors: final e) => onFailure(e),
//       FlodSuccess(data: final d) => onSuccess(d),
//     };
//   }

//   // Полезно для цепочек: если успех, делаем что-то еще
//   ValidationResult<R> map<R>(R Function(T data) transform) {
//     return switch (this) {
//       FlodFailure(errors: final e) => FlodFailure(e),
//       FlodSuccess(data: final d) => FlodSuccess(transform(d)),
//     };
//   }
// }

// class FlodSuccess<T> extends ValidationResult<T> {
//   @override
//   final T data;

//   const FlodSuccess(this.data);
// }

// class FlodFailure<T> extends ValidationResult<T> {
//   @override
//   final List<FlodError> errors;

//   const FlodFailure(this.errors);
//   // Фабрика для быстрого создания одной ошибки (идеально для abortEarly)
//   factory FlodFailure.single(FlodError error) => FlodFailure([error]);
// }
