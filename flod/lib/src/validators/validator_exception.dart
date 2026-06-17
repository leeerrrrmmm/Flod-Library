import 'package:flod/src/error.dart';
import 'package:flod/src/types/path.dart';

class ValidationException implements Exception {
  final List<FlodError> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    return 'Validation Exception: ${errors.length} error(s) found. ${errors.map((e) => '${e.path.toReadable()}: ${e.message} (${e.code})').join('\n')}';
  }
}
