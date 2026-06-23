import 'package:flod/src/types/path.dart';

class FlodError {
  final Path path;
  final String message;
  final String code;

  /// Безопасное значение для логов
  final dynamic rejectedValue;

  FlodError(
    this.path,
    this.message,
    this.code, {
    dynamic value,
    bool isSecret = false,
  }) : rejectedValue = isSecret ? '[HIDDEN]' : value;

  @override
  String toString() {
    // Если rejectedValue равен null (например, для не обновленных валидаторов),
    // лог останется аккуратным
    final valueLog = rejectedValue != null ? ' | Value: $rejectedValue' : '';
    return '-> [Path: $path] $message ($code)$valueLog';
  }
}
