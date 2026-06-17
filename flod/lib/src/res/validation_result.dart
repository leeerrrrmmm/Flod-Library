import 'package:flod/src/error.dart';

sealed class ValidationResult<T> {
  const ValidationResult();

  bool get isSuccess => this is FlodSuccess<T>;
  bool get isFailure => this is FlodFailure<T>;

  T get data {
    if (this case FlodSuccess<T>(data: final d)) return d;
    throw StateError('Try to get data from FlodFailure');
  }

  List<FlodError> get errors {
    if (this case FlodFailure<T>(errors: final e)) return e;
    throw StateError('Try to get errors from FlodSuccess');
  }
}

class FlodSuccess<T> extends ValidationResult<T> {
  @override
  final T data;

  const FlodSuccess(this.data);
}

class FlodFailure<T> extends ValidationResult<T> {
  @override
  final List<FlodError> errors;

  const FlodFailure(this.errors);
}
