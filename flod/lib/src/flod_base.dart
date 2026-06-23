import 'package:flod/src/validators/number_validator/double_validator.dart';
import 'package:flod/src/validators/number_validator/int_validator.dart';
import 'package:flod/src/validators/list_validator/list_validator.dart';
import 'package:flod/src/validators/object_validator/object_validator.dart';
import 'package:flod/src/validators/string_validator/string_validator.dart';
import 'package:flod/src/core/validator.dart';

class Flod {
  static StringValidator string() => StringValidator();
  static IntValidator int() => IntValidator();
  static DoubleValidator double() => DoubleValidator();
  static ObjectValidator object(Map<String, Validator> schema) =>
      ObjectValidator(schema);
  static ListValidator list({Validator? schema}) {
    return ListValidator(schema: schema);
  }
}
