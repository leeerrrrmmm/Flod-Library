import 'package:flod/flod.dart';

class ValidationException implements Exception {
  final List<FlodError> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    return 'Validation Exception: ${errors.length} error(s) found. ${errors.map((e) => '${e.path.toReadable()}: ${e.params} (${e.code})').join('\n')}';
  }
}
