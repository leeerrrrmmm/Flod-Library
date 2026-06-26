library;

import 'src/core/validator.dart';
import 'src/i18n/resolver.dart';
import 'src/validators/bool_validator/bool_validator.dart';
import 'src/validators/list_validator/list_validator.dart';
import 'src/validators/literal_validator/literal_validator.dart';
import 'src/validators/number_validator/double_validator.dart';
import 'src/validators/number_validator/int_validator.dart';
import 'src/validators/object_validator/object_validator.dart';
import 'src/validators/string_validator/string_validator.dart';
import 'src/validators/union_validator/union_validator.dart';

// Core & Results
export 'src/core/validator.dart';
// Самое важное: Экспорт всех расширений (.nullable(), .optional() и т.д.)
export 'src/extensions/all_extensions.dart';
export 'src/cfg/flog_config.dart';
export 'src/i18n/errors/errors_codes.dart';
export 'src/i18n/resolver.dart';
export 'src/res/parse_result.dart';
// Types & Errors
export 'src/types/flod_error.dart';
export 'src/types/path.dart';
// Validators
export 'src/validators/bool_validator/bool_validator.dart';
export 'src/validators/list_validator/list_validator.dart';
export 'src/validators/literal_validator/literal_validator.dart';
export 'src/validators/nullable_and_optional_validator/nullable_validator.dart';
export 'src/validators/nullable_and_optional_validator/optional_validator.dart';
export 'src/validators/number_validator/base_number_validator.dart';
export 'src/validators/number_validator/double_validator.dart';
export 'src/validators/number_validator/int_validator.dart';
export 'src/validators/object_validator/object_validator.dart';
export 'src/validators/string_validator/string_validator.dart';
export 'src/validators/union_validator/union_validator.dart';

/// Главная точка входа в библиотеку Flod.
/// Предоставляет удобный и лаконичный API для декларативного создания схем.
abstract final class Flod {
  /// Валидатор строковых данных
  static StringValidator string() => StringValidator();

  /// Валидатор целочисленных значений (int)
  static IntValidator int() => IntValidator();

  /// Валидатор чисел с плавающей точкой (double)
  static DoubleValidator double() => DoubleValidator();

  /// Валидатор логических значений (bool)
  static BoolValidator bool() => BoolValidator();

  /// Валидатор списков/коллекций с поддержкой внутренней схемы элементов
  static ListValidator<T> list<T>({Validator<T>? schema}) =>
      ListValidator<T>(schema: schema);

  /// Валидатор объектов (Map< String, dynamic >) со строгой структурой ключей
  static ObjectValidator object(Map<String, Validator> schema) =>
      ObjectValidator(schema);

  /// Валидатор Union-типов (объединений) для полиморфных структур
  static UnionValidator union(List<Validator> schemas) =>
      UnionValidator(schemas);

  /// Валидатор строго фиксированных литеральных значений (enum-like или константы)
  static LiteralValidator<T> literal<T>(
    T expectedValue, {
    String? code,
  }) {
    return LiteralValidator<T>(
      expectedValue,
      customCode: code,
    );
  }

  /// Фабрика для сборки кастомных локализаторов (например, украинского ukrainianResolver)
  static FlodI18nResolver i18n(FlodLocaleCompiler compiler) =>
      FlodI18nResolver(compiler);
}
