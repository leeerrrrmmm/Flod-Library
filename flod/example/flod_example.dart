// import 'package:flod/flod.dart';
// import 'package:flod/src/validators/exception_validator/validator_exception.dart';

// void main() {
//   print("=================================================================");
//   print("          FLOD PRIVACY & HIGH-STRESS PERFORMANCE MATRIX          ");
//   print("=================================================================\n");

//   // / Главный хелпер для запуска сценариев валидации.
//   // / Проверяет три состояния: успех на валидных данных, публичный лог ошибок
//   // / и автоматическое маскирование [HIDDEN] для приватных (.secret()) валидаторов.
//   // / Также проводит автоматический аудит безопасности на предмет утечки данных.
//   void runScenario({
//     required String name,
//     required Validator publicValidator,
//     required Validator secretValidator,
//     required dynamic validValue,
//     required dynamic invalidValue,
//   }) {
//     print("📌 [Validator: $name]");

//     // 1. ТЕСТ: ПРАВИЛЬНЫЕ ДАННЫЕ (Сложные граничные структуры)
//     final resValid = publicValidator.safeParse(validValue);
//     if (resValid is FlodSuccess) {
//       print(
//         "   ✅ SUCCESS -> Вход проверен | Выход: ${(resValid).data} [Type: ${(resValid).data.runtimeType}]",
//       );
//     } else {
//       print("   🚨 CRITICAL FAIL -> Ожидался успех, но схема упала!");
//       print(
//         "                       Ошибки: ${(resValid as FlodFailure).errors.map((e) => '[${e.path.toReadable()}] ${e.params}').join(', ')}",
//       );
//     }

//     // 2. ТЕСТ: НЕПРАВИЛЬНЫЕ ДАННЫЕ (Публичный лог)
//     final resInvalid = publicValidator.safeParse(invalidValue);
//     if (resInvalid is FlodFailure) {
//       print(
//         "   ❌ PUBLIC FAIL -> Обнаружено ошибок: ${(resInvalid).errors.length}",
//       );
//       for (final err in resInvalid.errors) {
//         print(
//           "         ↳ Path: '${err.path.toReadable()}' | Code: ${err.code} | Message: ${err.params} | Value: ${err.value}",
//         );
//       }
//     } else {
//       print(
//         "   🚨 CRITICAL FAIL -> Ожидался фейл, но публичный валидатор пропустил невалидную структуру: $invalidValue",
//       );
//     }

//     // 3. ТЕСТ: МАСКИРОВАНИЕ ПРИВАТНОСТИ (.secret) + Авто-аудит безопасности
//     final resSecret = secretValidator.safeParse(invalidValue);
//     if (resSecret is FlodFailure) {
//       print("   🔒 SECRET FAIL -> Скрыто ошибок: ${resSecret.errors.length}");
//       bool leakDetected = false;
//       for (final err in (resSecret).errors) {
//         final valString = err.value.toString();
//         // Если секретный валидатор вернул исходное сырое значение вместо маски — это утечка
//         if (err.value != null &&
//             valString != "[HIDDEN]" &&
//             !valString.contains("null") &&
//             err.value) {
//           leakDetected = true;
//         }
//         print(
//           "         ↳ Path: '${err.path.toReadable()}' | Code: ${err.code} | Masked Value: ${err.value}",
//         );
//       }
//       if (leakDetected) {
//         print(
//           "   🚨 SECURITY BREACH -> ОБНАРУЖЕНА УТЕЧКА ДАННЫХ В СЕКРЕТНОМ ЛОГЕ!",
//         );
//       } else {
//         print(
//           "   🛡️ PRIVACY VERDICT -> ИНВАРЕАНТ ПРИВАТНОСТИ ЗАЩИЩЕН СЕКЬЮРНО.",
//         );
//       }
//       print("");
//     } else {
//       print(
//         "   🚨 CRITICAL FAIL -> Секретный валидатор пропустил плохие данные!\n",
//       );
//     }
//   }

//   // =========================================================================
//   // СЕКЦИЯ 1: PARSE API (SAFE vs EXCEPTION)
//   // =========================================================================
//   print("=== СЕКЦИЯ 1: PARSE API (SAFE vs EXCEPTION) ===");

//   final garbageInputs = [
//     12345,
//     null,
//     [],
//     {"malicious": "payload"},
//     double.nan,
//   ];
//   for (var input in garbageInputs) {
//     try {
//       print(
//         "📌 [Testing: parse() Exception Throw with input type: ${input.runtimeType}]",
//       );
//       Flod.string().parse(input);
//       print(
//         "   🚨 CRITICAL FAIL -> parse() не выбросил исключение при неверном типе ($input)!",
//       );
//     } on ValidationException catch (e) {
//       print("   ✅ SUCCESS -> parse() корректно выбросил исключение: $e");
//     } catch (e) {
//       print("   🚨 FATAL -> Выброшено непредвиденное исключение: $e");
//     }
//   }
//   print("");

//   // =========================================================================
//   // СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS
//   // =========================================================================
//   print("=== СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS ===");

//   runScenario(
//     name: "2.1. .nullable() Fallthrough (Messy Space Strings)",
//     publicValidator: Flod.string().min(5, code: "min_length_error").nullable(),
//     secretValidator: Flod.string()
//         .min(5, code: "min_length_error [SECRET]")
//         .nullable()
//         .secret(),
//     validValue: null,
//     invalidValue:
//         "   ", // Строка из пробелов, длина меньше 5 после потенциального тримминга или просто короткая грязная строка
//   );

//   runScenario(
//     name: "2.2. .optional() Fallthrough (Extreme Numeric Bounds)",
//     publicValidator: Flod.int().min(18).optional(),
//     secretValidator: Flod.int().min(18).optional().secret(),
//     validValue: null,
//     invalidValue: -9223372036854775808, // Минимальное значение 64-битного int
//   );

//   // =========================================================================
//   // СЕКЦИЯ 3: OBJECT SCHEMA MODES
//   // =========================================================================
//   print("=== СЕКЦИЯ 3: OBJECT SCHEMA MODES ===");

//   runScenario(
//     name: "3.1. .strict() Mode (Deep Malicious Key Injection)",
//     publicValidator: Flod.object({"name": Flod.string()}).strict(),
//     secretValidator: Flod.object({"name": Flod.string()}).strict().secret(),
//     validValue: {"name": "Maksym"},
//     invalidValue: {
//       "name": "Maksym",
//       "unknown_hacker_key": "payload",
//       "__proto__": "prototype_pollution_attempt",
//       "nested_exploit": {"bad": true},
//     },
//   );

//   runScenario(
//     name: "3.2. .passthrough() Mode (Type Attack inside Objects)",
//     publicValidator: Flod.object({"name": Flod.string()}).passthrough(),
//     secretValidator: Flod.object({
//       "name": Flod.string(),
//     }).passthrough().secret(),
//     validValue: {
//       "name": "Maksym",
//       "extra_key": "it's okay",
//       "complex_nested_extra": {
//         "a": [1, 2, 3],
//       },
//     },
//     invalidValue: {
//       "name": double.nan,
//     }, // Подмена ожидаемой строки на разрушающий double.nan
//   );

//   runScenario(
//     name: "3.3. Nested Validation Paths (Hyper-Deep Structural Matrix)",
//     publicValidator: Flod.object({
//       "company": Flod.object({
//         "department": Flod.object({
//           "team": Flod.object({
//             "lead": Flod.object({
//               "analytics": Flod.object({"age": Flod.int().min(18)}),
//             }),
//           }),
//         }),
//       }),
//     }),
//     secretValidator: Flod.object({
//       "company": Flod.object({
//         "department": Flod.object({
//           "team": Flod.object({
//             "lead": Flod.object({
//               "analytics": Flod.object({"age": Flod.int().min(18)}),
//             }),
//           }),
//         }),
//       }),
//     }).secret(),
//     validValue: {
//       "company": {
//         "department": {
//           "team": {
//             "lead": {
//               "analytics": {"age": 25},
//             },
//           },
//         },
//       },
//     },
//     invalidValue: {
//       "company": {
//         "department": {
//           "team": {
//             "lead": {
//               "analytics": {
//                 "age": -5,
//               }, // Глубоко зарытая невалидная переменная для проверки построения пути
//             },
//           },
//         },
//       },
//     },
//   );

//   // =========================================================================
//   // СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS
//   // =========================================================================
//   print("=== СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS ===");

//   runScenario(
//     name:
//         "4.1 & 5.2. items(schema) & Built-in Transforms (Unicode Control Characters)",
//     publicValidator: Flod.list(schema: Flod.string().trim().toLowerCase()),
//     secretValidator: Flod.list(
//       schema: Flod.string().trim().toLowerCase(),
//     ).secret(),
//     validValue: ["\t  MAKSYM \n", " \r FLOD \u0000 "],
//     invalidValue: [
//       "ValidString",
//       {"invalid_object_instead_of_item": 42},
//       double.infinity,
//     ],
//   );

//   runScenario(
//     name: "4.2. Constraints (Empty and Massive Arrays Bounds)",
//     publicValidator: Flod.list().minItems(2).maxItems(4),
//     secretValidator: Flod.list().minItems(2).maxItems(4).secret(),
//     validValue: [1, 2, 3],
//     invalidValue: List.generate(
//       100,
//       (index) => index,
//     ), // Переполнение лимита массива (100 элементов вместо макс 4)
//   );

//   runScenario(
//     name: "4.3. uniqueItems (Normalized Verification with Whitespace Mutants)",
//     publicValidator: Flod.list(schema: Flod.string().trim()).uniqueItems(),
//     secretValidator: Flod.list(
//       schema: Flod.string().trim(),
//     ).uniqueItems().secret(),
//     validValue: ["a", "b", "c"],
//     invalidValue: [
//       "dart",
//       "  dart  ",
//       "dart\n",
//       "DART",
//     ], // После тримминга "dart", "  dart  " и "dart\n" превратятся в дубликаты
//   );

//   runScenario(
//     name:
//         "5.1.1. Custom Same-Type Transform (Chaotic Structural String Modification)",
//     publicValidator: Flod.string().transform(
//       (v) => "MODIFIED_${v.replaceAll(' ', '_')}_END",
//     ),
//     secretValidator: Flod.string()
//         .transform((v) => "MODIFIED_${v.replaceAll(' ', '_')}_END")
//         .secret(),
//     validValue: "heavy data test",
//     invalidValue: [1, 2, 3, 4, 5], // Передача массива вместо базовой строки
//   );

//   runScenario(
//     name:
//         "5.1.2. Complex Type-Changing Transform (String -> Multi-layered int Mapping)",
//     publicValidator: Flod.string().transform(
//       (v) => int.tryParse(v.trim()) ?? -999,
//     ),
//     secretValidator: Flod.string()
//         .transform((v) => int.tryParse(v.trim()) ?? -999)
//         .secret(),
//     validValue: "   150   ",
//     invalidValue: {"raw_json_payload": "should_fail_before_transform"},
//   );

//   runScenario(
//     name: "5.3.1. Execution Order (Multi-stage Pipeline Pre-validation Rules)",
//     publicValidator: Flod.string().trim().fixedLength(
//       3,
//       code: "fixed_length_error",
//     ),
//     secretValidator: Flod.string()
//         .trim()
//         .fixedLength(3, code: "fixed_length_error [SECRET]")
//         .secret(),
//     validValue: "\n\t EUR \r ", // Будет очищено до "EUR" (длина 3)
//     invalidValue: " \t LONGRUNNINGSTRINGTHATFAILSTHEFIXEDLENGTHCHECK \n",
//   );

//   runScenario(
//     name: "5.4. Ultimate Deep Chaining Pipeline (Deconstructive Type Shifts)",
//     publicValidator: Flod.string()
//         .trim()
//         .toLowerCase()
//         .transform((v) => v.length) // Переход String -> int
//         .transform((len) => len * 2), // Операция над int
//     secretValidator: Flod.string()
//         .trim()
//         .toLowerCase()
//         .transform((v) => v.length)
//         .transform((len) => len * 2)
//         .secret(),
//     validValue: "    FLOD STRESS    ", // "flod stress" -> длина 11 -> выход 22
//     invalidValue: null,
//   );

//   // =========================================================================
//   // СЕКЦИЯ 6: UNION TYPES
//   // =========================================================================
//   print("=== СЕКЦИЯ 6: UNION TYPES ===");

//   runScenario(
//     name: "6.1.1. Plain Union Logic (Deep Recursive Fallback Multi-Type Chaos)",
//     publicValidator: Flod.union([Flod.string(), Flod.int(), Flod.list()]),
//     secretValidator: Flod.union([
//       Flod.string(),
//       Flod.int(),
//       Flod.list(),
//     ]).secret(),
//     validValue: [
//       1,
//       "test",
//       {"nested": true},
//     ],
//     invalidValue: {"unsupported_map_type": true},
//   );

//   runScenario(
//     name: "6.1.2. Plain Union Logic (Complex Objects Struct Overlapping)",
//     publicValidator: Flod.union([
//       Flod.object({
//         "type": Flod.literal("user"),
//         "name": Flod.string(),
//         "metadata": Flod.object({"id": Flod.int()}),
//       }),
//       Flod.object({
//         "type": Flod.literal("bot"),
//         "id": Flod.int(),
//         "permissions": Flod.list(),
//       }),
//     ]),
//     secretValidator: Flod.union([
//       Flod.object({
//         "type": Flod.literal("user"),
//         "name": Flod.string(),
//         "metadata": Flod.object({"id": Flod.int()}),
//       }),
//       Flod.object({
//         "type": Flod.literal("bot"),
//         "id": Flod.int(),
//         "permissions": Flod.list(),
//       }),
//     ]).secret(),
//     validValue: {
//       "type": "bot",
//       "id": 777,
//       "permissions": ["admin", "read"],
//     },
//     invalidValue: {
//       "type": "guest",
//       "name": 12345, // Нарушение типа
//       "metadata": {"id": "not-an-int"}, // Нарушение типа во вложенности
//       "permissions": "not-a-list",
//     },
//   );

//   runScenario(
//     name: "6.2.1. Tagged/Discriminated Union Optimization O(1) Routing Matrix",
//     publicValidator: Flod.union([
//       Flod.object({
//         "kind": Flod.literal("email"),
//         "address": Flod.string().email(),
//       }),
//       Flod.object({
//         "kind": Flod.literal("phone"),
//         "number": Flod.string().phoneNumber(),
//       }),
//       Flod.object({
//         "kind": Flod.literal("crypto"),
//         "wallet": Flod.string().fixedLength(42, code: "invalid_wallet_length"),
//       }),
//     ]).discriminatedBy("kind"),
//     secretValidator: Flod.union([
//       Flod.object({
//         "kind": Flod.literal("email"),
//         "address": Flod.string().email(),
//       }),
//       Flod.object({
//         "kind": Flod.literal("phone"),
//         "number": Flod.string().phoneNumber(),
//       }),
//       Flod.object({
//         "kind": Flod.literal("crypto"),
//         "wallet": Flod.string().fixedLength(42, code: "invalid_wallet_length"),
//       }),
//     ]).discriminatedBy("kind").secret(),
//     validValue: {
//       "kind": "crypto",
//       "wallet": "0x0000000000000000000000000000000000000000",
//     },
//     invalidValue: {
//       "kind": "phone",
//       "number": "THIS_IS_NOT_A_VALID_PHONE_NUMBER_FORMAT_ATTACK",
//     },
//   );

//   // =========================================================================
//   // СЕКЦИЯ 7: DEFAULT VALUES
//   // =========================================================================
//   print("=== СЕКЦИЯ 7: DEFAULT VALUES ===");

//   runScenario(
//     name: "7.1. Basic Default Value (Deep Map Omission)",
//     publicValidator: Flod.object({
//       "config": Flod.object({
//         "theme": Flod.string().defaultValue("dark"),
//       }).optional(),
//     }),
//     secretValidator: Flod.object({
//       "config": Flod.object({
//         "theme": Flod.string().defaultValue("dark"),
//       }).optional(),
//     }).secret(),
//     validValue: {"config": {}},
//     invalidValue: {
//       "config": {"theme": false},
//     },
//   );

//   runScenario(
//     name: "7.2. Default + Complex Chained Pipeline (Calculation Injection)",
//     publicValidator: Flod.object({
//       "port": Flod.int().defaultValue(80).transform((v) => v + 4000),
//     }),
//     secretValidator: Flod.object({
//       "port": Flod.int().defaultValue(80).transform((v) => v + 4000),
//     }).secret(),
//     validValue:
//         {}, // Ключа нет -> должен отработать дефолт (80) -> трансформироваться в 4080
//     invalidValue: {"port": "NaN-Malicious-String-Attack"},
//   );

//   // =========================================================================
//   // СЕКЦИЯ 8: ABORT EARLY & COMPLEX NESTING (STRESS TRIAL)
//   // =========================================================================
//   print("=== СЕКЦИЯ 8: EDGE CASES & STRESS TEST ===");

//   // Тяжелый объект со всеми возможными деструктивными комбинациями для жесткой проверки AbortEarly режима
//   final heavyPublicAbortEarlyValidator = Flod.object({
//     "error_field_1": Flod.string().email(),
//     "error_field_2": Flod.int().positive(),
//     "nested_chaos": Flod.object({"deep_error_3": Flod.string().uuid()}),
//   }).stopOnFirstError(); // Активируем разработанный режим AbortEarly

//   final heavySecretAbortEarlyValidator = Flod.object({
//     "error_field_1": Flod.string().email(),
//     "error_field_2": Flod.int().positive(),
//     "nested_chaos": Flod.object({"deep_error_3": Flod.string().uuid()}),
//   }).stopOnFirstError().secret();

//   runScenario(
//     name:
//         "8.1. AbortEarly Active Switch (Must stop strictly at 1st sequential failure)",
//     publicValidator: heavyPublicAbortEarlyValidator,
//     secretValidator: heavySecretAbortEarlyValidator,
//     validValue: {
//       "error_field_1": "test@domain.com",
//       "error_field_2": 100,
//       "nested_chaos": {"deep_error_3": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"},
//     },
//     invalidValue: {
//       "error_field_1": "NOT_AN_EMAIL", // Ошибка 1
//       "error_field_2": -500, // Ошибка 2
//       "nested_chaos": {"deep_error_3": "BAD"}, // Ошибка 3
//       // В логе PUBLIC FAIL должно отобразиться строго Ошибок: 1, подтверждая работоспособность break в цикле схем.
//     },
//   );

//   runScenario(
//     name: "8.2. Type Mismatch Explosion (Multi-Layer Poisoning Matrix)",
//     publicValidator: Flod.object({
//       "matrix": Flod.list(schema: Flod.int()),
//       "system_flags": Flod.object({"active": Flod.bool()}),
//     }),
//     secretValidator: Flod.object({
//       "matrix": Flod.list(schema: Flod.int()),
//       "system_flags": Flod.object({"active": Flod.bool()}),
//     }).secret(),
//     validValue: {
//       "matrix": [1, 2, 3],
//       "system_flags": {"active": true},
//     },
//     invalidValue: {
//       "matrix": ["string_instead_of_int", double.nan, false],
//       "system_flags": "not_even_a_map_structure",
//     },
//   );

//   // =========================================================================
//   // СЕКЦИЯ 19: NUMBER VALIDATOR SUITE
//   // =========================================================================
//   print("=== СЕКЦИЯ 19: NUMBER VALIDATOR SUITE ===");

//   runScenario(
//     name: "19.2. IntValidator (Extreme Platform Interoperability Overflows)",
//     publicValidator: Flod.int().min(10).max(20),
//     secretValidator: Flod.int().min(10).max(20).secret(),
//     validValue: 15,
//     invalidValue: 9223372036854775807, // Максимальный 64-битный int
//   );

//   runScenario(
//     name:
//         "19.3. DoubleValidator (NaN, Positive/Negative Infinities Security Guard)",
//     publicValidator: Flod.double(),
//     secretValidator: Flod.double().secret(),
//     validValue: -0.0000000000001,
//     invalidValue: double.nan, // Должно жестко отсекаться встроенными guards
//   );

//   runScenario(
//     name: "19.6.1. Specialized Signs (.positive with Sub-Zero Float Attacks)",
//     publicValidator: Flod.int().positive(),
//     secretValidator: Flod.int().positive().secret(),
//     validValue: 1,
//     invalidValue: -2147483648,
//   );

//   runScenario(
//     name: "19.6.2. Specialized Signs (.negative Boundaries)",
//     publicValidator: Flod.int().negative(),
//     secretValidator: Flod.int().negative().secret(),
//     validValue: -1,
//     invalidValue: 0,
//   );

//   runScenario(
//     name: "19.6.3. Specialized Signs (.nonPositive Range Limits)",
//     publicValidator: Flod.int().nonPositive(),
//     secretValidator: Flod.int().nonPositive().secret(),
//     validValue: -9999999,
//     invalidValue: 1,
//   );

//   runScenario(
//     name: "19.6.4. Specialized Signs (.nonNegative Range Limits)",
//     publicValidator: Flod.int().nonNegative(),
//     secretValidator: Flod.int().nonNegative().secret(),
//     validValue: 0,
//     invalidValue: -1,
//   );

//   runScenario(
//     name: "19.6.5. Arithmetic Rules (.multipleOf Mathematical Stress)",
//     publicValidator: Flod.int().multipleOf(7),
//     secretValidator: Flod.int().multipleOf(7).secret(),
//     validValue: 700000000,
//     invalidValue: 700000001,
//   );

//   // =========================================================================
//   // СЕКЦИЯ 20: STRING DOMAIN FORMATS
//   // =========================================================================
//   print("=== СЕКЦИЯ 20: STRING DOMAIN FORMATS ===");

//   runScenario(
//     name: "20.2. .email() Verification (XSS Script Insertion Payload)",
//     publicValidator: Flod.string().email(),
//     secretValidator: Flod.string().email().secret(),
//     validValue: "production-ready-validator@flod.architecture.io",
//     invalidValue:
//         "<script>alert('xss')</script>@test.com", // Ломает стандартные наивные RegExp
//   );

//   runScenario(
//     name: "20.3. Password Policies (High Entropy Verification Complexity)",
//     publicValidator: Flod.string().minUppercase(3).minNumbers(3).minSymbols(3),
//     secretValidator: Flod.string()
//         .minUppercase(3)
//         .minNumbers(3)
//         .minSymbols(3)
//         .secret(),
//     validValue: "ABC123abc!!!",
//     invalidValue:
//         "A1!a", // Слишком короткий энтропийный состав, генерирует каскад Multi-Error
//   );

//   runScenario(
//     name: "20.4.1. Specialized Formats (.url Malformed Structural Bypass)",
//     publicValidator: Flod.string().url(),
//     secretValidator: Flod.string().url().secret(),
//     validValue:
//         "https://subdomain.domain.co.uk/path/to/resource?query=1&sort=desc#anchor",
//     invalidValue: "http://../../malicious-relative-path-escape",
//   );

//   runScenario(
//     name:
//         "20.4.2. Specialized Formats (.phoneNumber International Syntax Match)",
//     publicValidator: Flod.string().phoneNumber(),
//     secretValidator: Flod.string().phoneNumber().secret(),
//     validValue: "+12345678901234",
//     invalidValue: "0000-not-a-phone-alphabetic-string-injection",
//   );

//   runScenario(
//     name: "20.4.3. Specialized Formats (.uuid v4 Variant Conformance)",
//     publicValidator: Flod.string().uuid(),
//     secretValidator: Flod.string().uuid().secret(),
//     validValue: "123e4567-e89b-12d3-a456-426614174000",
//     invalidValue:
//         "123e4567-e89b-12d3-a456-42661417400G", // Невалидный Hex-символ 'G' на границе строки
//   );

//   runScenario(
//     name: "20.6. .fixedLength() Control (Zero Length Attack Vector)",
//     publicValidator: Flod.string().fixedLength(
//       3,
//       code: FlodErrorCodes.stringFixedLength,
//     ),
//     secretValidator: Flod.string()
//         .fixedLength(3, code: FlodErrorCodes.stringFixedLength)
//         .secret(),
//     validValue: "USD",
//     invalidValue: "", // Пустая строка для падения проверки фиксированной длины
//   );

//   runScenario(
//     name: "20.7. Credit Card Domain Logic (Luhn Format & Size Exploitation)",
//     publicValidator: Flod.string().creditCard(),
//     secretValidator: Flod.string().creditCard().secret(),
//     validValue: "4111111111111111",
//     invalidValue:
//         "4111111111111111111111111111111111111111111111111111", // Переполнение стандартного буфера номера карты
//   );

//   runScenario(
//     name: "20.8. CVV Domain Logic (Alphabetical Noise Injection)",
//     publicValidator: Flod.string().cvv(),
//     secretValidator: Flod.string().cvv().secret(),
//     validValue: "999",
//     invalidValue: "99A", // Алфавитный символ вместо числового защитного кода
//   );

//   print("=================================================================");
//   print("    COMPLETE HIGH-STRESS VERIFICATION MATRIX RUN FINISHED        ");
//   print("=================================================================");
// }

// // import 'package:flod/flod.dart';
// // import 'package:flod/src/validators/exception_validator/validator_exception.dart';

// // // =========================================================================
// // // ТОЧКА РАСШИРЕНИЯ ПОЛЬЗОВАТЕЛЯ: СТОРОННИЕ КОМПИЛЯТОРЫ ЛОКАЛИЗАЦИИ (Пункт 10)
// // // =========================================================================

// // // Инициализация украинской локализации через вашу фабрику:
// // final ukrainianResolver = Flod.i18n((code, params) {
// //   switch (code) {
// //     case FlodErrorCodes.required:
// //       return 'Це поле є обовʼязковим';
// //     case FlodErrorCodes.invalidType:
// //       return 'Очікуваний тип: ${params['expected']}, отриманий: ${params['actual']}.';
// //     case FlodErrorCodes.objectStrict:
// //       return 'Виявлені неприпустимі ключі: ${params['key']}.';
// //     case FlodErrorCodes.stringMin:
// //       return 'Мінімальна довжина: ${params['limit']} символів.';
// //     case FlodErrorCodes.numberMin:
// //       return 'Значення має бути >= ${params['limit']}.';
// //     case FlodErrorCodes.listMaxItems:
// //       return 'Список може містити максимум ${params['limit']} елементів.';
// //     case FlodErrorCodes.stringEmail:
// //       return 'Невірний формат email.';
// //     case FlodErrorCodes.stringCreditCard:
// //       return 'Невірний номер кредитної картки.';
// //     case FlodErrorCodes.stringMinUppercase:
// //       return 'Потрібно мінімум ${params['limit']} великих літер.';
// //     case FlodErrorCodes.stringMinNumbers:
// //       return 'Потрібно мінімум ${params['limit']} цифр.';
// //     case FlodErrorCodes.stringMinSymbols:
// //       return 'Потрібно мінімум ${params['limit']} спецсимволів.';
// //     case FlodErrorCodes.numberMultipleOf:
// //       return 'Число має бути кратним ${params['limit']}.';
// //     case FlodErrorCodes.union:
// //       return 'Помилка [$code]';
// //     default:
// //       return 'Помилка [$code]';
// //   }
// // });

// // final germanResolver = Flod.i18n((code, params) {
// //   switch (code) {
// //     case 'required':
// //       return 'Dieses Feld ist obligatorisch.';
// //     case 'invalid_type':
// //       return 'Erwartet: ${params['expected']}, erhalten: ${params['actual']}.';
// //     case 'object.strict':
// //       return 'Unzulässiger Schlüssel: ${params['key']}.';
// //     case FlodErrorCodes.union:
// //       return 'Daten entsprechen keinem erlaubten Typ.';
// //     // Strings
// //     case FlodErrorCodes.stringMin:
// //       return 'Mindestlänge: ${params['limit']} Zeichen.';
// //     case FlodErrorCodes.stringFixedLength:
// //       return 'Länge muss exakt ${params['limit']} Zeichen sein.';
// //     case FlodErrorCodes.stringEmail:
// //       return 'Ungültiges E-Mail-Format.';
// //     case FlodErrorCodes.stringUrl:
// //       return 'Ungültige URL-Struktur.';
// //     case FlodErrorCodes.stringUuid:
// //       return 'Ungültige UUID v4.';
// //     case FlodErrorCodes.stringCreditCard:
// //       return 'Ungültige Kreditkarte (Luhn-Fehler).';
// //     case FlodErrorCodes.stringCvv:
// //       return 'Ungültiger CVV-Code.';
// //     // Password Policies
// //     case FlodErrorCodes.stringMinUppercase:
// //       return 'Mindestens ${params['limit']} Großbuchstaben erforderlich.';
// //     case FlodErrorCodes.stringMinNumbers:
// //       return 'Mindestens ${params['limit']} Ziffern erforderlich.';
// //     case FlodErrorCodes.stringMinSymbols:
// //       return 'Mindestens ${params['limit']} Sonderzeichen erforderlich.';
// //     // Numbers
// //     case FlodErrorCodes.numberMin:
// //       return 'Wert muss >= ${params['limit']} sein.';
// //     case FlodErrorCodes.numberPositive:
// //       return 'Zahl muss positiv sein.';
// //     case FlodErrorCodes.numberNegative:
// //       return 'Zahl muss negativ sein.';
// //     case FlodErrorCodes.numberMultipleOf:
// //       return 'Zahl muss ein Vielfaches von ${params['limit']} sein.';
// //     // Lists
// //     case FlodErrorCodes.listMinItems:
// //       return 'Liste muss mindestens ${params['limit']} Elemente enthalten.';
// //     case FlodErrorCodes.listMaxItems:
// //       return 'Liste darf maximal ${params['limit']} Elemente enthalten.';
// //     case FlodErrorCodes.listUniqueItems:
// //       return 'Alle Elemente in der Liste müssen eindeutig sein.';
// //     default:
// //       return 'Validierungsfehler (Code: $code).';
// //   }
// // });

// // void main() {
// //   print("=================================================================");
// //   print("        FLOD EXTRA-HARDCORE COMPREHENSIVE STRESS ENGINE          ");
// //   print("=================================================================\n");
// //   final ukrResolver = ukrainianResolver;
// //   final gerResolver = germanResolver;

// //   /// Универсальный жесткий исполнитель сценариев
// //   void executeStressScenario({
// //     required String section,
// //     required String description,
// //     required Validator validator,
// //     required dynamic validPayload,
// //     required dynamic toxicPayload,
// //   }) {
// //     print("-----------------------------------------------------------------");
// //     print("🔬 [SECTION $section] $description");
// //     print("-----------------------------------------------------------------");

// //     // 1. ТЕСТ: safeParse() И УСПЕХ (Пункт 1.2)
// //     final successResult = validator.safeParse(validPayload);
// //     if (successResult is FlodSuccess) {
// //       print("   ✅ [safeParse: SUCCESS] Данные успешно прошли сито Flod.");
// //     } else {
// //       print(
// //         "   🚨 [safeParse: CRITICAL FAIL] Валидные данные были заблокированы!",
// //       );
// //       final errs = (successResult as FlodFailure).errors;
// //       for (var e in errs) {
// //         print(
// //           "      ↳ Path: '${e.path.toReadable()}' | Code: ${e.code} | Value: ${e.value}",
// //         );
// //       }
// //     }

// //     // 2. ТЕСТ: safeParse() И АГРЕССИВНОЕ ПАДЕНИЕ (Пункты 9, 13, 15, 22)
// //     final failureResult = validator.safeParse(toxicPayload);
// //     if (failureResult is FlodFailure) {
// //       print(
// //         "   ❌ [safeParse: TOXIC DATA CAUGHT] Словлено ошибок: ${failureResult.errors.length}",
// //       );

// //       // Проверка маскирования логов и уязвимостей (Пункт 22)
// //       bool privacyLeak = false;
// //       for (final err in failureResult.errors) {
// //         final valStr = err.value.toString();
// //         // Защитный инвариант: если в ошибках просочилось исходное токсичное значение,
// //         // но при этом поле должно быть скрыто (тестируем логику .secret())
// //         if (err.value != null &&
// //             valStr != "[HIDDEN]" &&
// //             !valStr.contains("null") &&
// //             valStr.contains("toxic")) {
// //           privacyLeak = true;
// //         }
// //       }

// //       if (privacyLeak) {
// //         print(
// //           "   🚨 [SECURITY BREACH] ОБНАРУЖЕНА УТЕЧКА ДАННЫХ В ОБЪЕКТЕ ОШИБКИ!",
// //         );
// //       } else {
// //         print("   🛡️ [PRIVACY VERDICT] Конфиденциальность данных защищена.");
// //       }

// //       // МАКСИМАЛЬНО ЖЕСТКИЙ I18N ТЕСТ НА 2-Х ЯЗЫКАХ (Пункт 10)
// //       final ukrMap = failureResult.getGroupedFieldsMap(
// //         customResolver: ukrResolver,
// //       );
// //       final gerMap = failureResult.getGroupedFieldsMap(
// //         customResolver: gerResolver,
// //       );

// //       print("\n         🇺🇦 [UA Localization - Grouped Multi-Errors]:");
// //       ukrMap.forEach((path, msgs) {
// //         print("            ↳ Поле '$path': ${msgs.join(' И ')}");
// //       });

// //       print("         🇩🇪 [DE Localization - Grouped Multi-Errors]:");
// //       gerMap.forEach((path, msgs) {
// //         print("            ↳ Feld '$path': ${msgs.join(' UND ')}");
// //       });
// //       print("");
// //     } else {
// //       print(
// //         "   🚨 [CRITICAL INFRASTRUCTURE FAIL] Валидатор пропустил токсичный payload!",
// //       );
// //     }
// //   }

// //   // =========================================================================
// //   // СЕКЦИЯ 1: PARSE API & EXCEPTIONS (Пункты 1.1, 1.2)
// //   // =========================================================================
// //   print("=== СЕКЦИЯ 1: PARSE API СИНХРОННЫЕ ИСКЛЮЧЕНИЯ ===");
// //   try {
// //     Flod.int().parse("строка_вместо_числа");
// //     print("   🚨 FAIL: parse() пропустил ошибку без Exception!");
// //   } on ValidationException catch (e) {
// //     print("   ✅ SUCCESS: parse() выбросил ValidationException: $e");
// //   }
// //   print("");

// //   // =========================================================================
// //   // СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS (Пункты 2.1, 2.2)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "2",
// //     description: "Nullable & Optional Развязка с грязными строками пробелов",
// //     validator: Flod.string()
// //         .min(5, code: FlodErrorCodes.stringMin)
// //         .nullable()
// //         .optional(),
// //     validPayload: null, // Допустимо из-за nullable
// //     toxicPayload: "   ", // Ошибка: длина меньше 5
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 3 & 13: OBJECT MODES & DEEP AGGREGATION (Пункты 3.1, 3.2, 3.3, 13)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "3 & 13",
// //     description:
// //         "Strict Mode, Глубокая вложенность путей и инъекция ключей (__proto__)",
// //     validator: Flod.object({
// //       "user": Flod.object({
// //         "profile": Flod.object({"age": Flod.int().min(18)}).strict(),
// //       }),
// //     }),
// //     validPayload: {
// //       "user": {
// //         "profile": {"age": 25},
// //       },
// //     },
// //     toxicPayload: {
// //       "user": {
// //         "profile": {
// //           "age": 12, // Ошибка 1: Возраст меньше 18
// //           "__proto__":
// //               "malicious_pollution", // Ошибка 2: Лишний ключ в strict() режиме
// //           "hacker_payload": true,
// //         },
// //       },
// //     },
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 4: LIST / ARRAY SCHEMA CONSTRAINTS (Пункты 4.1, 4.2, 4.3)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "4",
// //     description:
// //         "Коллекции: Ограничения размера и мутанты уникальности элементов",
// //     validator: Flod.list(
// //       schema: Flod.string().trim(),
// //     ).minItems(2).maxItems(4).uniqueItems(),
// //     validPayload: ["alpha", "beta", "gamma"],
// //     toxicPayload: [
// //       "dart",
// //       "  dart  ", // После trim() превратится в "dart" -> дубликат (uniqueItems fail)
// //       "flutter",
// //       "firebase",
// //       "extra_item_overflow", // Превышение maxItems (5 элементов вместо макс 4)
// //     ],
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 5: TRANSFORM PIPELINE (Пункты 5.1, 5.2, 5.3)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "5",
// //     description: "Пайплайн трансформаций: Выполнение строго ДО валидации чисел",
// //     validator: Flod.string()
// //         .trim()
// //         .toLowerCase()
// //         .transform((v) => int.tryParse(v) ?? 0) // String -> int
// //         .transform((nums) => nums * 2)
// //         .transform(
// //           (v) => Flod.int().min(50).validate(v),
// //         ), // Кастомный или встроенный pipe-проверщик лимита
// //     validPayload: "   30   ", // "30" -> 30 -> 60 (60 >= 50: Успех)
// //     toxicPayload: "  15  ", // "15" -> 15 -> 30 (30 < 50: Ошибка)
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 6: UNION TYPES WITH O(1) DISCRIMINATION (Пункты 6.1, 6.2)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "6",
// //     description:
// //         "Discriminated Union по полю 'type' с глубоким падением внутренней схемы",
// //     validator: Flod.union([
// //       Flod.object({
// //         "type": Flod.literal("email_service"),
// //         "meta": Flod.object({"email": Flod.string().email()}),
// //       }),
// //       Flod.object({
// //         "type": Flod.literal("phone_service"),
// //         "meta": Flod.object({"phone": Flod.string().phoneNumber()}),
// //       }),
// //     ]).discriminatedBy("type"),
// //     validPayload: {
// //       "type": "email_service",
// //       "meta": {"email": "dev@flod.io"},
// //     },
// //     toxicPayload: {
// //       "type": "email_service",
// //       "meta": {
// //         "email": "NOT_A_VALID_EMAIL_XSS_ATTACK",
// //       }, // Падение внутренней структуры
// //     },
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 7: DEFAULT VALUES FALLBACK (Пункты 7.1, 7.2)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "7",
// //     description:
// //         "Заполнение дефолтов при отсутствии ключей с последующей математикой",
// //     validator: Flod.object({
// //       "timeout": Flod.int().defaultValue(100).transform((v) => v + 50),
// //     }),
// //     validPayload: {}, // Ключа нет -> 100 -> 150 (Успех)
// //     toxicPayload: {
// //       "timeout": "invalid_type_string",
// //     }, // Ошибка типа до дефолта
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 8: ABORT EARLY ACTIVE BREAK (Пункты 8.1, 8.2)
// //   // =========================================================================
// //   // Создаем валидатор с жестким стопом на первой ошибке
// //   final abortEarlyValidator = Flod.object({
// //     "fail_one": Flod.int().positive(),
// //     "fail_two": Flod.string().email(),
// //     "fail_three": Flod.string().uuid(),
// //   }).stopOnFirstError(); // true

// //   executeStressScenario(
// //     section: "8",
// //     description:
// //         "AbortEarly Switch: Сбор ровно 1 ошибки вместо каскада трех падений",
// //     validator: abortEarlyValidator,
// //     validPayload: {
// //       "fail_one": 10,
// //       "fail_two": "test@test.com",
// //       "fail_three": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
// //     },
// //     toxicPayload: {
// //       "fail_one": -500, // Падение тут! Цикл обязан сделать break!
// //       "fail_two": "invalid_email",
// //       "fail_three": "invalid_uuid",
// //     },
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 19 & 20: NUMBER VALIDATOR & DOMAIN STRINGS (Пункты 19, 20)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "19 & 20",
// //     description:
// //         "Комплексные доменные проверки: Пароли, Кредитные карты и Кратность",
// //     validator: Flod.object({
// //       "multiple": Flod.int().multipleOf(7),
// //       "card": Flod.string().creditCard(),
// //       "password": Flod.string()
// //           .minUppercase(2)
// //           .minNumbers(2)
// //           .minSymbols(2)
// //           .secret(),
// //     }),
// //     validPayload: {
// //       "multiple": 49,
// //       "card": "4111111111111111",
// //       "password": "AA11!!",
// //     },
// //     toxicPayload: {
// //       "multiple": 50, // Ошибка кратности
// //       "card": "4111111111111112", // Ошибка Луна
// //       "password": "weak", // Сразу 3 ошибки пароля (Multi-Error на одном поле)
// //     },
// //   );

// //   // =========================================================================
// //   // СЕКЦИЯ 22: LOG PRIVACY & PROTECTION (.secret()) (Пункт 22)
// //   // =========================================================================
// //   executeStressScenario(
// //     section: "22",
// //     description:
// //         "Log Privacy: Полное маскирование секретного токена в объекте ошибки",
// //     validator: Flod.object({
// //       "public_id": Flod.string(),
// //       "secure_token": Flod.string()
// //           .min(32, code: FlodErrorCodes.stringMin)
// //           .secret(), // Скрываем от логов!
// //     }),
// //     validPayload: {
// //       "public_id": "user_123",
// //       "secure_token": "super_long_secret_hash_token_string_32",
// //     },
// //     toxicPayload: {
// //       "public_id": "user_123",
// //       "secure_token":
// //           "toxic_short", // Ошибка длины, но значение обязано скрыться!
// //     },
// //   );

// //   print("=================================================================");
// //   print("         ALL STRESS TRIALS COMPLETED WITH 100% SUCCESS           ");
// //   print("=================================================================");
// // }
import 'package:flod/flod.dart';

void main() {
  final signupSchema =
      Flod.object({
        'email': Flod.string(),
        'password': Flod.string(),
        'confirmPassword': Flod.string(),
      }).refine(
        (data) => data['password'] == data['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
      );

  final invalidData = {
    'email': 'test@flod.dev',
    'password': 'password123',
    'confirmPassword': 'different_password',
  };

  final result = signupSchema.safeParse(invalidData);

  if (result is FlodFailure) {
    print('--- Ошибка валидации ---');

    // 👇 ВАЖНО: используем toReadable()
    print(result.toReadable());
  } else {
    print('Валидация пройдена успешно!');
  }
}
