library;

import 'package:flod/flod.dart';

export 'src/cfg/flog_config.dart';
export 'src/core/async_validator.dart';
export 'src/core/debug/flod_debug.dart';
// Core & Results
export 'src/core/performance/compiled_validators.dart';
export 'src/core/performance/schema_pool.dart';
export 'src/core/performance/validator_compiler.dart';
export 'src/core/validator.dart';
// Самое важное: Экспорт всех расширений (.nullable(), .optional() и т.д.)
export 'src/extensions/all_extensions.dart';
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
export 'src/validators/refine_validator/refine_validator.dart';
export 'src/validators/refine_validator/super_refine_context.dart';
export 'src/validators/refine_validator/super_refine_validator.dart';
export 'src/validators/string_validator/string_validator.dart';
export 'src/validators/union_validator/union_validator.dart';

/// Главная точка входа в библиотеку Flod.
/// Предоставляет удобный и лаконичный API для декларативного создания схем.
abstract final class Flod {
  /// Валидатор строковых данных (12.1 — shared base instance)
  static StringValidator string() => SchemaPool.string;

  /// Валидатор целочисленных значений (int) (12.1 — shared base instance)
  static IntValidator int() => SchemaPool.int;

  /// Валидатор чисел с плавающей точкой (double) (12.1 — shared base instance)
  static DoubleValidator double() => SchemaPool.double;

  /// Валидатор логических значений (bool) (12.1 — shared base instance)
  /// Zod-compatible: `z.boolean()` → `Flod.boolean()`.
  static BoolValidator boolean() => SchemaPool.boolean;

  /// Валидатор списков/коллекций с поддержкой внутренней схемы элементов
  static ListValidator<T> list<T>({Validator<T>? schema}) =>
      ListValidator<T>(schema: schema);

  /// Валидатор объектов (Map< String, dynamic >) со строгой структурой ключей
  static ObjectValidator object(Map<String, Validator> schema) =>
      ObjectValidator(schema);

  /// Валидатор объектов (Map< String, dynamic >) со строгой структурой ключей и условными валидациями
  static Validator<Map<String, dynamic>> refineObject(
    Map<String, Validator> schema,
    bool Function(Map<String, dynamic> value) predicate, {
    List<String>? path,
    String? code,
    Map<String, dynamic>? params,
  }) => ObjectValidator(
    schema,
  ).refine(predicate, path: path, code: code, params: params);

  /// Валидатор Union-типов (объединений) для полиморфных структур
  static UnionValidator union(List<Validator> schemas) =>
      UnionValidator(schemas);

  /// Валидатор строго фиксированных литеральных значений (enum-like или константы)
  static LiteralValidator<T> literal<T>(T expectedValue, {String? code}) {
    return LiteralValidator<T>(expectedValue, customCode: code);
  }

  /// Фабрика для сборки кастомных локализаторов (например, украинского ukrainianResolver)
  static FlodI18nResolver i18n(FlodLocaleCompiler compiler) =>
      FlodI18nResolver(compiler);
}
