import 'package:flod/src/error.dart';

class ParseResult<T> {
  final T? data;
  final List<FlodError>? errors;
  final bool success;

  ParseResult._internal({this.data, this.errors, required this.success});

  factory ParseResult.success(T data) =>
      ParseResult._internal(data: data, success: true);

  factory ParseResult.failure(List<FlodError> errors) =>
      ParseResult._internal(errors: errors, success: false);
}
