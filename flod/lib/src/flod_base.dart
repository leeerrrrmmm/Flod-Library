import 'package:flod/src/validators/double_validator.dart';
import 'package:flod/src/validators/int_validator.dart';
import 'package:flod/src/validators/object_validator.dart';
import 'package:flod/src/validators/string_validator.dart';
import 'package:flod/src/validators/validator.dart';

class Flod {
  static StringValidator string() => StringValidator();
  static IntValidator int() => IntValidator();
  static DoubleValidator double() => DoubleValidator();
  static ObjectValidator object(Map<String, Validator> schema) =>
      ObjectValidator(schema);
}
