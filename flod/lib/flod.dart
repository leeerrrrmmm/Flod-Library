library;

import 'package:flod/flod.dart';

// Core
export 'src/core/validator.dart';
export 'src/error.dart';
// ЭТО САМОЕ ВАЖНОЕ: Экспорт всех расширений
export 'src/extensions/all_extensions.dart';
export 'src/res/parse_result.dart';
export 'src/res/validation_result.dart';
// Types & Results
export 'src/types/path.dart';
export 'src/validators/number_validator/base_number_validator.dart'; // Обязательно экспортируй базовый
export 'src/validators/number_validator/double_validator.dart';
export 'src/validators/number_validator/int_validator.dart';
export 'src/validators/list_validator/list_validator.dart';
export 'src/validators/nullable_and_optional_validator/nullable_validator.dart';
export 'src/validators/object_validator/object_validator.dart';
export 'src/validators/nullable_and_optional_validator/optional_validator.dart';
// Validators
export 'src/validators/string_validator/string_validator.dart';

// Удобная фабрика Flod
class Flod {
  static StringValidator string() => StringValidator();
  static IntValidator int() => IntValidator();
  static DoubleValidator double() => DoubleValidator();
  static ListValidator list({Validator? schema}) =>
      ListValidator(schema: schema);
  static ObjectValidator object(Map<String, Validator> schema) =>
      ObjectValidator(schema);
}
