import 'package:flod/src/validators/bool_validator/bool_validator.dart';
import 'package:flod/src/validators/number_validator/double_validator.dart';
import 'package:flod/src/validators/number_validator/int_validator.dart';
import 'package:flod/src/validators/string_validator/string_validator.dart';

/// 12.1 Schema Reuse — shared immutable base validators.
///
/// Reuse these constants instead of calling [Flod.string] / [Flod.int] etc.
/// when you need an unconfigured primitive schema.
abstract final class SchemaPool {
  static const StringValidator string = StringValidator();
  static const IntValidator int = IntValidator();
  static const DoubleValidator double = DoubleValidator();
  static const BoolValidator boolean = BoolValidator();
}
