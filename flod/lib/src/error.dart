import 'package:flod/src/types/path.dart';

class FlodError {
  final Path path;
  final String message;
  final String code;

  FlodError(this.path, this.message, this.code);
}
