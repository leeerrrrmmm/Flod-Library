import 'package:dio/dio.dart';
import 'package:flod/dio.dart';
import 'package:flod/flod.dart';
import 'package:flod/form.dart';
import 'package:flod/guard.dart';
import 'package:flod/src/validators/exception_validator/validator_exception.dart';

void main() async {
  print("=================================================================");
  print("          FLOD PRIVACY & HIGH-STRESS PERFORMANCE MATRIX          ");
  print("=================================================================\n");

  // / Главный хелпер для запуска сценариев валидации.
  // / Проверяет три состояния: успех на валидных данных, публичный лог ошибок
  // / и автоматическое маскирование [HIDDEN] для приватных (.secret()) валидаторов.
  // / Также проводит автоматический аудит безопасности на предмет утечки данных.
  void runScenario({
    required String name,
    required Validator publicValidator,
    required Validator secretValidator,
    required dynamic validValue,
    required dynamic invalidValue,
  }) {
    print("📌 [Validator: $name]");

    // 1. ТЕСТ: ПРАВИЛЬНЫЕ ДАННЫЕ (Сложные граничные структуры)
    final resValid = publicValidator.safeParse(validValue);
    if (resValid is FlodSuccess) {
      print(
        "   ✅ SUCCESS -> Вход проверен | Выход: ${(resValid).data} [Type: ${(resValid).data.runtimeType}]",
      );
    } else {
      print("   🚨 CRITICAL FAIL -> Ожидался успех, но схема упала!");
      print(
        "                       Ошибки: ${(resValid as FlodFailure).errors.map((e) => '[${e.path.toReadable()}] ${e.params}').join(', ')}",
      );
    }

    // 2. ТЕСТ: НЕПРАВИЛЬНЫЕ ДАННЫЕ (Публичный лог)
    final resInvalid = publicValidator.safeParse(invalidValue);
    if (resInvalid is FlodFailure) {
      print(
        "   ❌ PUBLIC FAIL -> Обнаружено ошибок: ${(resInvalid).errors.length}",
      );
      for (final err in resInvalid.errors) {
        print(
          "         ↳ Path: '${err.path.toReadable()}' | Code: ${err.code} | Message: ${err.params} | Value: ${err.value}",
        );
      }
    } else {
      print(
        "   🚨 CRITICAL FAIL -> Ожидался фейл, но публичный валидатор пропустил невалидную структуру: $invalidValue",
      );
    }

    // 3. ТЕСТ: МАСКИРОВАНИЕ ПРИВАТНОСТИ (.secret) + Авто-аудит безопасности
    final resSecret = secretValidator.safeParse(invalidValue);
    if (resSecret is FlodFailure) {
      print("   🔒 SECRET FAIL -> Скрыто ошибок: ${resSecret.errors.length}");
      bool leakDetected = false;
      for (final err in (resSecret).errors) {
        final valString = err.value.toString();
        // Если секретный валидатор вернул исходное сырое значение вместо маски — это утечка
        if (err.value != null &&
            valString != "[HIDDEN]" &&
            !valString.contains("null") &&
            err.value) {
          leakDetected = true;
        }
        print(
          "         ↳ Path: '${err.path.toReadable()}' | Code: ${err.code} | Masked Value: ${err.value}",
        );
      }
      if (leakDetected) {
        print(
          "   🚨 SECURITY BREACH -> ОБНАРУЖЕНА УТЕЧКА ДАННЫХ В СЕКРЕТНОМ ЛОГЕ!",
        );
      } else {
        print(
          "   🛡️ PRIVACY VERDICT -> ИНВАРЕАНТ ПРИВАТНОСТИ ЗАЩИЩЕН СЕКЬЮРНО.",
        );
      }
      print("");
    } else {
      print(
        "   🚨 CRITICAL FAIL -> Секретный валидатор пропустил плохие данные!\n",
      );
    }
  }

  // =========================================================================
  // СЕКЦИЯ 1: PARSE API (SAFE vs EXCEPTION)
  // =========================================================================
  print("=== СЕКЦИЯ 1: PARSE API (SAFE vs EXCEPTION) ===");

  final garbageInputs = [
    12345,
    null,
    [],
    {"malicious": "payload"},
    double.nan,
  ];
  for (var input in garbageInputs) {
    try {
      print(
        "📌 [Testing: parse() Exception Throw with input type: ${input.runtimeType}]",
      );
      Flod.string().parse(input);
      print(
        "   🚨 CRITICAL FAIL -> parse() не выбросил исключение при неверном типе ($input)!",
      );
    } on ValidationException catch (e) {
      print("   ✅ SUCCESS -> parse() корректно выбросил исключение: $e");
    } catch (e) {
      print("   🚨 FATAL -> Выброшено непредвиденное исключение: $e");
    }
  }
  print("");

  // =========================================================================
  // СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS
  // =========================================================================
  print("=== СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS ===");

  runScenario(
    name: "2.1. .nullable() Fallthrough (Messy Space Strings)",
    publicValidator: Flod.string().min(5, code: "min_length_error").nullable(),
    secretValidator: Flod.string()
        .min(5, code: "min_length_error [SECRET]")
        .nullable()
        .secret(),
    validValue: null,
    invalidValue:
        "   ", // Строка из пробелов, длина меньше 5 после потенциального тримминга или просто короткая грязная строка
  );

  runScenario(
    name: "2.2. .optional() Fallthrough (Extreme Numeric Bounds)",
    publicValidator: Flod.int().min(18).optional(),
    secretValidator: Flod.int().min(18).optional().secret(),
    validValue: null,
    invalidValue: -9223372036854775808, // Минимальное значение 64-битного int
  );

  // =========================================================================
  // СЕКЦИЯ 3: OBJECT SCHEMA MODES
  // =========================================================================
  print("=== СЕКЦИЯ 3: OBJECT SCHEMA MODES ===");

  runScenario(
    name: "3.1. .strict() Mode (Deep Malicious Key Injection)",
    publicValidator: Flod.object({"name": Flod.string()}).strict(),
    secretValidator: Flod.object({"name": Flod.string()}).strict().secret(),
    validValue: {"name": "Maksym"},
    invalidValue: {
      "name": "Maksym",
      "unknown_hacker_key": "payload",
      "__proto__": "prototype_pollution_attempt",
      "nested_exploit": {"bad": true},
    },
  );

  runScenario(
    name: "3.2. .passthrough() Mode (Type Attack inside Objects)",
    publicValidator: Flod.object({"name": Flod.string()}).passthrough(),
    secretValidator: Flod.object({
      "name": Flod.string(),
    }).passthrough().secret(),
    validValue: {
      "name": "Maksym",
      "extra_key": "it's okay",
      "complex_nested_extra": {
        "a": [1, 2, 3],
      },
    },
    invalidValue: {
      "name": double.nan,
    }, // Подмена ожидаемой строки на разрушающий double.nan
  );

  runScenario(
    name: "3.3. Nested Validation Paths (Hyper-Deep Structural Matrix)",
    publicValidator: Flod.object({
      "company": Flod.object({
        "department": Flod.object({
          "team": Flod.object({
            "lead": Flod.object({
              "analytics": Flod.object({"age": Flod.int().min(18)}),
            }),
          }),
        }),
      }),
    }),
    secretValidator: Flod.object({
      "company": Flod.object({
        "department": Flod.object({
          "team": Flod.object({
            "lead": Flod.object({
              "analytics": Flod.object({"age": Flod.int().min(18)}),
            }),
          }),
        }),
      }),
    }).secret(),
    validValue: {
      "company": {
        "department": {
          "team": {
            "lead": {
              "analytics": {"age": 25},
            },
          },
        },
      },
    },
    invalidValue: {
      "company": {
        "department": {
          "team": {
            "lead": {
              "analytics": {
                "age": -5,
              }, // Глубоко зарытая невалидная переменная для проверки построения пути
            },
          },
        },
      },
    },
  );

  // =========================================================================
  // СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS
  // =========================================================================
  print("=== СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS ===");

  runScenario(
    name:
        "4.1 & 5.2. items(schema) & Built-in Transforms (Unicode Control Characters)",
    publicValidator: Flod.list(schema: Flod.string().trim().toLowerCase()),
    secretValidator: Flod.list(
      schema: Flod.string().trim().toLowerCase(),
    ).secret(),
    validValue: ["\t  MAKSYM \n", " \r FLOD \u0000 "],
    invalidValue: [
      "ValidString",
      {"invalid_object_instead_of_item": 42},
      double.infinity,
    ],
  );

  runScenario(
    name: "4.2. Constraints (Empty and Massive Arrays Bounds)",
    publicValidator: Flod.list().minItems(2).maxItems(4),
    secretValidator: Flod.list().minItems(2).maxItems(4).secret(),
    validValue: [1, 2, 3],
    invalidValue: List.generate(
      100,
      (index) => index,
    ), // Переполнение лимита массива (100 элементов вместо макс 4)
  );

  runScenario(
    name: "4.3. uniqueItems (Normalized Verification with Whitespace Mutants)",
    publicValidator: Flod.list(schema: Flod.string().trim()).uniqueItems(),
    secretValidator: Flod.list(
      schema: Flod.string().trim(),
    ).uniqueItems().secret(),
    validValue: ["a", "b", "c"],
    invalidValue: [
      "dart",
      "  dart  ",
      "dart\n",
      "DART",
    ], // После тримминга "dart", "  dart  " и "dart\n" превратятся в дубликаты
  );

  runScenario(
    name:
        "5.1.1. Custom Same-Type Transform (Chaotic Structural String Modification)",
    publicValidator: Flod.string().transform(
      (v) => "MODIFIED_${v.replaceAll(' ', '_')}_END",
    ),
    secretValidator: Flod.string()
        .transform((v) => "MODIFIED_${v.replaceAll(' ', '_')}_END")
        .secret(),
    validValue: "heavy data test",
    invalidValue: [1, 2, 3, 4, 5], // Передача массива вместо базовой строки
  );

  runScenario(
    name:
        "5.1.2. Complex Type-Changing Transform (String -> Multi-layered int Mapping)",
    publicValidator: Flod.string().transform(
      (v) => int.tryParse(v.trim()) ?? -999,
    ),
    secretValidator: Flod.string()
        .transform((v) => int.tryParse(v.trim()) ?? -999)
        .secret(),
    validValue: "   150   ",
    invalidValue: {"raw_json_payload": "should_fail_before_transform"},
  );

  runScenario(
    name: "5.3.1. Execution Order (Multi-stage Pipeline Pre-validation Rules)",
    publicValidator: Flod.string().trim().fixedLength(
      3,
      code: "fixed_length_error",
    ),
    secretValidator: Flod.string()
        .trim()
        .fixedLength(3, code: "fixed_length_error [SECRET]")
        .secret(),
    validValue: "\n\t EUR \r ", // Будет очищено до "EUR" (длина 3)
    invalidValue: " \t LONGRUNNINGSTRINGTHATFAILSTHEFIXEDLENGTHCHECK \n",
  );

  runScenario(
    name: "5.4. Ultimate Deep Chaining Pipeline (Deconstructive Type Shifts)",
    publicValidator: Flod.string()
        .trim()
        .toLowerCase()
        .transform((v) => v.length) // Переход String -> int
        .transform((len) => len * 2), // Операция над int
    secretValidator: Flod.string()
        .trim()
        .toLowerCase()
        .transform((v) => v.length)
        .transform((len) => len * 2)
        .secret(),
    validValue: "    FLOD STRESS    ", // "flod stress" -> длина 11 -> выход 22
    invalidValue: null,
  );

  // =========================================================================
  // СЕКЦИЯ 6: UNION TYPES
  // =========================================================================
  print("=== СЕКЦИЯ 6: UNION TYPES ===");

  runScenario(
    name: "6.1.1. Plain Union Logic (Deep Recursive Fallback Multi-Type Chaos)",
    publicValidator: Flod.union([Flod.string(), Flod.int(), Flod.list()]),
    secretValidator: Flod.union([
      Flod.string(),
      Flod.int(),
      Flod.list(),
    ]).secret(),
    validValue: [
      1,
      "test",
      {"nested": true},
    ],
    invalidValue: {"unsupported_map_type": true},
  );

  runScenario(
    name: "6.1.2. Plain Union Logic (Complex Objects Struct Overlapping)",
    publicValidator: Flod.union([
      Flod.object({
        "type": Flod.literal("user"),
        "name": Flod.string(),
        "metadata": Flod.object({"id": Flod.int()}),
      }),
      Flod.object({
        "type": Flod.literal("bot"),
        "id": Flod.int(),
        "permissions": Flod.list(),
      }),
    ]),
    secretValidator: Flod.union([
      Flod.object({
        "type": Flod.literal("user"),
        "name": Flod.string(),
        "metadata": Flod.object({"id": Flod.int()}),
      }),
      Flod.object({
        "type": Flod.literal("bot"),
        "id": Flod.int(),
        "permissions": Flod.list(),
      }),
    ]).secret(),
    validValue: {
      "type": "bot",
      "id": 777,
      "permissions": ["admin", "read"],
    },
    invalidValue: {
      "type": "guest",
      "name": 12345, // Нарушение типа
      "metadata": {"id": "not-an-int"}, // Нарушение типа во вложенности
      "permissions": "not-a-list",
    },
  );

  runScenario(
    name: "6.2.1. Tagged/Discriminated Union Optimization O(1) Routing Matrix",
    publicValidator: Flod.union([
      Flod.object({
        "kind": Flod.literal("email"),
        "address": Flod.string().email(),
      }),
      Flod.object({
        "kind": Flod.literal("phone"),
        "number": Flod.string().phoneNumber(),
      }),
      Flod.object({
        "kind": Flod.literal("crypto"),
        "wallet": Flod.string().fixedLength(42, code: "invalid_wallet_length"),
      }),
    ]).discriminatedBy("kind"),
    secretValidator: Flod.union([
      Flod.object({
        "kind": Flod.literal("email"),
        "address": Flod.string().email(),
      }),
      Flod.object({
        "kind": Flod.literal("phone"),
        "number": Flod.string().phoneNumber(),
      }),
      Flod.object({
        "kind": Flod.literal("crypto"),
        "wallet": Flod.string().fixedLength(42, code: "invalid_wallet_length"),
      }),
    ]).discriminatedBy("kind").secret(),
    validValue: {
      "kind": "crypto",
      "wallet": "0x0000000000000000000000000000000000000000",
    },
    invalidValue: {
      "kind": "phone",
      "number": "THIS_IS_NOT_A_VALID_PHONE_NUMBER_FORMAT_ATTACK",
    },
  );

  // =========================================================================
  // СЕКЦИЯ 7: DEFAULT VALUES
  // =========================================================================
  print("=== СЕКЦИЯ 7: DEFAULT VALUES ===");

  runScenario(
    name: "7.1. Basic Default Value (Deep Map Omission)",
    publicValidator: Flod.object({
      "config": Flod.object({
        "theme": Flod.string().defaultValue("dark"),
      }).optional(),
    }),
    secretValidator: Flod.object({
      "config": Flod.object({
        "theme": Flod.string().defaultValue("dark"),
      }).optional(),
    }).secret(),
    validValue: {"config": {}},
    invalidValue: {
      "config": {"theme": false},
    },
  );

  runScenario(
    name: "7.2. Default + Complex Chained Pipeline (Calculation Injection)",
    publicValidator: Flod.object({
      "port": Flod.int().defaultValue(80).transform((v) => v + 4000),
    }),
    secretValidator: Flod.object({
      "port": Flod.int().defaultValue(80).transform((v) => v + 4000),
    }).secret(),
    validValue:
        {}, // Ключа нет -> должен отработать дефолт (80) -> трансформироваться в 4080
    invalidValue: {"port": "NaN-Malicious-String-Attack"},
  );

  // =========================================================================
  // СЕКЦИЯ 8: ABORT EARLY & COMPLEX NESTING (STRESS TRIAL)
  // =========================================================================
  print("=== СЕКЦИЯ 8: EDGE CASES & STRESS TEST ===");

  // Тяжелый объект со всеми возможными деструктивными комбинациями для жесткой проверки AbortEarly режима
  final heavyPublicAbortEarlyValidator = Flod.object({
    "error_field_1": Flod.string().email(),
    "error_field_2": Flod.int().positive(),
    "nested_chaos": Flod.object({"deep_error_3": Flod.string().uuid()}),
  }).stopOnFirstError(); // Активируем разработанный режим AbortEarly

  final heavySecretAbortEarlyValidator = Flod.object({
    "error_field_1": Flod.string().email(),
    "error_field_2": Flod.int().positive(),
    "nested_chaos": Flod.object({"deep_error_3": Flod.string().uuid()}),
  }).stopOnFirstError().secret();

  runScenario(
    name:
        "8.1. AbortEarly Active Switch (Must stop strictly at 1st sequential failure)",
    publicValidator: heavyPublicAbortEarlyValidator,
    secretValidator: heavySecretAbortEarlyValidator,
    validValue: {
      "error_field_1": "test@domain.com",
      "error_field_2": 100,
      "nested_chaos": {"deep_error_3": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"},
    },
    invalidValue: {
      "error_field_1": "NOT_AN_EMAIL", // Ошибка 1
      "error_field_2": -500, // Ошибка 2
      "nested_chaos": {"deep_error_3": "BAD"}, // Ошибка 3
      // В логе PUBLIC FAIL должно отобразиться строго Ошибок: 1, подтверждая работоспособность break в цикле схем.
    },
  );

  runScenario(
    name: "8.2. Type Mismatch Explosion (Multi-Layer Poisoning Matrix)",
    publicValidator: Flod.object({
      "matrix": Flod.list(schema: Flod.int()),
      "system_flags": Flod.object({"active": Flod.boolean()}),
    }),
    secretValidator: Flod.object({
      "matrix": Flod.list(schema: Flod.int()),
      "system_flags": Flod.object({"active": Flod.boolean()}),
    }).secret(),
    validValue: {
      "matrix": [1, 2, 3],
      "system_flags": {"active": true},
    },
    invalidValue: {
      "matrix": ["string_instead_of_int", double.nan, false],
      "system_flags": "not_even_a_map_structure",
    },
  );

  // =========================================================================
  // СЕКЦИЯ 19: NUMBER VALIDATOR SUITE
  // =========================================================================
  print("=== СЕКЦИЯ 19: NUMBER VALIDATOR SUITE ===");

  runScenario(
    name: "19.2. IntValidator (Extreme Platform Interoperability Overflows)",
    publicValidator: Flod.int().min(10).max(20),
    secretValidator: Flod.int().min(10).max(20).secret(),
    validValue: 15,
    invalidValue: 9223372036854775807, // Максимальный 64-битный int
  );

  runScenario(
    name:
        "19.3. DoubleValidator (NaN, Positive/Negative Infinities Security Guard)",
    publicValidator: Flod.double(),
    secretValidator: Flod.double().secret(),
    validValue: -0.0000000000001,
    invalidValue: double.nan, // Должно жестко отсекаться встроенными guards
  );

  runScenario(
    name: "19.6.1. Specialized Signs (.positive with Sub-Zero Float Attacks)",
    publicValidator: Flod.int().positive(),
    secretValidator: Flod.int().positive().secret(),
    validValue: 1,
    invalidValue: -2147483648,
  );

  runScenario(
    name: "19.6.2. Specialized Signs (.negative Boundaries)",
    publicValidator: Flod.int().negative(),
    secretValidator: Flod.int().negative().secret(),
    validValue: -1,
    invalidValue: 0,
  );

  runScenario(
    name: "19.6.3. Specialized Signs (.nonPositive Range Limits)",
    publicValidator: Flod.int().nonPositive(),
    secretValidator: Flod.int().nonPositive().secret(),
    validValue: -9999999,
    invalidValue: 1,
  );

  runScenario(
    name: "19.6.4. Specialized Signs (.nonNegative Range Limits)",
    publicValidator: Flod.int().nonNegative(),
    secretValidator: Flod.int().nonNegative().secret(),
    validValue: 0,
    invalidValue: -1,
  );

  runScenario(
    name: "19.6.5. Arithmetic Rules (.multipleOf Mathematical Stress)",
    publicValidator: Flod.int().multipleOf(7),
    secretValidator: Flod.int().multipleOf(7).secret(),
    validValue: 700000000,
    invalidValue: 700000001,
  );

  // =========================================================================
  // СЕКЦИЯ 20: STRING DOMAIN FORMATS
  // =========================================================================
  print("=== СЕКЦИЯ 20: STRING DOMAIN FORMATS ===");

  runScenario(
    name: "20.2. .email() Verification (XSS Script Insertion Payload)",
    publicValidator: Flod.string().email(),
    secretValidator: Flod.string().email().secret(),
    validValue: "production-ready-validator@flod.architecture.io",
    invalidValue:
        "<script>alert('xss')</script>@test.com", // Ломает стандартные наивные RegExp
  );

  runScenario(
    name: "20.3. Password Policies (High Entropy Verification Complexity)",
    publicValidator: Flod.string().minUppercase(3).minNumbers(3).minSymbols(3),
    secretValidator: Flod.string()
        .minUppercase(3)
        .minNumbers(3)
        .minSymbols(3)
        .secret(),
    validValue: "ABC123abc!!!",
    invalidValue:
        "A1!a", // Слишком короткий энтропийный состав, генерирует каскад Multi-Error
  );

  runScenario(
    name: "20.4.1. Specialized Formats (.url Malformed Structural Bypass)",
    publicValidator: Flod.string().url(),
    secretValidator: Flod.string().url().secret(),
    validValue:
        "https://subdomain.domain.co.uk/path/to/resource?query=1&sort=desc#anchor",
    invalidValue: "http://../../malicious-relative-path-escape",
  );

  runScenario(
    name:
        "20.4.2. Specialized Formats (.phoneNumber International Syntax Match)",
    publicValidator: Flod.string().phoneNumber(),
    secretValidator: Flod.string().phoneNumber().secret(),
    validValue: "+12345678901234",
    invalidValue: "0000-not-a-phone-alphabetic-string-injection",
  );

  runScenario(
    name: "20.4.3. Specialized Formats (.uuid v4 Variant Conformance)",
    publicValidator: Flod.string().uuid(),
    secretValidator: Flod.string().uuid().secret(),
    validValue: "123e4567-e89b-12d3-a456-426614174000",
    invalidValue:
        "123e4567-e89b-12d3-a456-42661417400G", // Невалидный Hex-символ 'G' на границе строки
  );

  runScenario(
    name: "20.6. .fixedLength() Control (Zero Length Attack Vector)",
    publicValidator: Flod.string().fixedLength(
      3,
      code: FlodErrorCodes.stringFixedLength,
    ),
    secretValidator: Flod.string()
        .fixedLength(3, code: FlodErrorCodes.stringFixedLength)
        .secret(),
    validValue: "USD",
    invalidValue: "", // Пустая строка для падения проверки фиксированной длины
  );

  runScenario(
    name: "20.7. Credit Card Domain Logic (Luhn Format & Size Exploitation)",
    publicValidator: Flod.string().creditCard(),
    secretValidator: Flod.string().creditCard().secret(),
    validValue: "4111111111111111",
    invalidValue:
        "4111111111111111111111111111111111111111111111111111", // Переполнение стандартного буфера номера карты
  );

  runScenario(
    name: "20.8. CVV Domain Logic (Alphabetical Noise Injection)",
    publicValidator: Flod.string().cvv(),
    secretValidator: Flod.string().cvv().secret(),
    validValue: "999",
    invalidValue: "99A", // Алфавитный символ вместо числового защитного кода
  );

  // =========================================================================
  // SECTION 16: INTEGRATIONS (Form / JSON Guard / Dio)
  // =========================================================================
  print("=== SECTION 16: INTEGRATIONS (Form / JSON Guard / Dio) ===");

  var integPassed = 0;
  var integFailed = 0;

  void integCheck(String label, bool ok, [String detail = '']) {
    if (ok) {
      integPassed++;
      print('   ✅ $label');
    } else {
      integFailed++;
      print('   🚨 FAIL: $label${detail.isEmpty ? '' : ' -> $detail'}');
    }
  }

  // --- 16.1 Form Adapter ---
  final signupSchema =
      Flod.object({
        'email': Flod.string().email(),
        'password': Flod.string().min(8),
        'confirmPassword': Flod.string(),
      }).refine(
        (d) => d['password'] == d['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
      );
  final formAdapter = FlodFormAdapter(signupSchema);

  final invalidForm = {
    'email': 'not-an-email',
    'password': 'short',
    'confirmPassword': 'mismatch',
  };
  final formFields = formAdapter.validate(invalidForm);
  final formGrouped = formAdapter.validateGrouped(invalidForm);
  integCheck('INT-01 form validate() returns field map', formFields.isNotEmpty);
  integCheck(
    'INT-02 form validateGrouped() has email errors',
    formGrouped.containsKey('email'),
  );
  integCheck(
    'INT-03 form errorFor() targets confirmPassword',
    formAdapter.errorFor('confirmPassword', {
          'email': 'user@example.com',
          'password': 'SecurePass99',
          'confirmPassword': 'DifferentPass',
        }) !=
        null,
  );

  final emailFieldValidator = formAdapter.fieldValidator(
    'email',
    () => invalidForm,
  );
  integCheck(
    'INT-04 form fieldValidator() returns message for bad email',
    emailFieldValidator(null) != null,
  );

  final validForm = {
    'email': 'user@example.com',
    'password': 'SecurePass99',
    'confirmPassword': 'SecurePass99',
  };
  integCheck(
    'INT-05 form validate() empty on valid payload',
    formAdapter.validate(validForm).isEmpty,
  );

  // --- 16.2 JSON Guard ---
  const jsonGuard = JsonGuard();
  const tightGuard = JsonGuard(
    options: JsonGuardOptions(maxDepth: 3, maxKeys: 5, maxStringLength: 20),
  );
  final apiUserSchema = Flod.object({
    'id': Flod.int(),
    'name': Flod.string().min(1),
  });

  final guardOk = jsonGuard.parseJson('{"id":1,"name":"Ada"}', apiUserSchema);
  integCheck('INT-06 guard parseJson valid payload', guardOk is FlodSuccess);

  final guardBadJson = jsonGuard.parseJson('{broken', apiUserSchema);
  integCheck(
    'INT-07 guard rejects malformed JSON',
    guardBadJson is FlodFailure &&
        (guardBadJson as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardInvalidJson,
  );

  final guardProto = jsonGuard.parseJson(
    '{"id":1,"name":"Ada","__proto__":{"isAdmin":true}}',
    apiUserSchema,
  );
  integCheck(
    'INT-08 guard blocks __proto__ key',
    guardProto is FlodFailure &&
        (guardProto as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardPrototypeKey,
  );

  final deepPayload = {
    'a': {
      'b': {
        'c': {'d': 1},
      },
    },
  };
  final guardDepth = tightGuard.guard(deepPayload, apiUserSchema);
  integCheck(
    'INT-09 guard enforces maxDepth',
    guardDepth is FlodFailure &&
        (guardDepth as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardMaxDepth,
  );

  final guardKeys = tightGuard.guard({
    'id': 1,
    'name': 'Ada',
    'extra1': 1,
    'extra2': 2,
    'extra3': 3,
    'extra4': 4,
  }, apiUserSchema);
  integCheck(
    'INT-10 guard enforces maxKeys budget',
    guardKeys is FlodFailure &&
        (guardKeys as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardMaxKeys,
  );

  final guardString = tightGuard.guard({
    'id': 1,
    'name': 'this-name-is-way-too-long-for-tight-guard',
  }, apiUserSchema);
  integCheck(
    'INT-11 guard enforces maxStringLength',
    guardString is FlodFailure &&
        (guardString as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardMaxStringLength,
  );

  final tagsSchema = Flod.object({
    'id': Flod.int(),
    'name': Flod.string(),
    'tags': Flod.list(schema: Flod.int()),
  });
  final guardArray = JsonGuard(options: JsonGuardOptions(maxArrayLength: 2))
      .guard({
        'id': 1,
        'name': 'Ada',
        'tags': [1, 2, 3],
      }, tagsSchema);
  integCheck(
    'INT-12 guard enforces maxArrayLength',
    guardArray is FlodFailure &&
        (guardArray as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardMaxArrayLength,
  );

  try {
    jsonGuard.parseJsonOrThrow('{"id":1,"name":"Ada"}', apiUserSchema);
    integCheck('INT-13 guard parseJsonOrThrow success path', true);
  } catch (e) {
    integCheck('INT-13 guard parseJsonOrThrow success path', false, '$e');
  }

  // Guard + schema failure (security passed, validation failed)
  final guardSchemaFail = jsonGuard.parseJson(
    '{"id":"not-int","name":"Ada"}',
    apiUserSchema,
  );
  integCheck(
    'INT-14 guard passes security then schema rejects type',
    guardSchemaFail is FlodFailure &&
        (guardSchemaFail as FlodFailure).errors.first.code ==
            FlodErrorCodes.invalidType,
  );

  // --- 16.3 Dio Interceptor ---
  final postSchema = Flod.object({'id': Flod.int(), 'title': Flod.string()});
  final dioInterceptor = FlodValidateInterceptor(
    schema: postSchema,
    guard: jsonGuard,
  );

  final dioValid = FlodValidateInterceptor.validatePayload(
    raw: {'id': 1, 'title': 'Hello'},
    schema: postSchema,
    guard: jsonGuard,
  );
  integCheck(
    'INT-15 dio validatePayload accepts valid response',
    dioValid is FlodSuccess,
  );

  final dioInvalid = FlodValidateInterceptor.validatePayload(
    raw: {'id': 'bad', 'title': 'Hello'},
    schema: postSchema,
  );
  integCheck(
    'INT-16 dio validatePayload rejects invalid schema',
    dioInvalid is FlodFailure,
  );

  // Full onResponse path (real Dio handler)
  final liveResponse = Response(
    requestOptions: RequestOptions(path: '/posts/1'),
    data: {'id': 7, 'title': 'Live'},
  );
  final liveHandler = _CapturingResponseHandler();
  dioInterceptor.onResponse(liveResponse, liveHandler);
  final liveState = await liveHandler.completedResponse();
  integCheck(
    'INT-17 dio onResponse replaces data with validated map',
    liveState.data is Map && (liveState.data as Map)['id'] == 7,
  );

  // Nested extractData path
  final nestedInterceptor = FlodValidateInterceptor(
    schema: postSchema,
    extractData: (r) => (r.data as Map)['data'],
  );
  final nestedResponse = Response(
    requestOptions: RequestOptions(path: '/posts/wrapped'),
    data: {
      'meta': {'version': 1},
      'data': {'id': 99, 'title': 'Wrapped'},
    },
  );
  final nestedHandler = _CapturingResponseHandler();
  nestedInterceptor.onResponse(nestedResponse, nestedHandler);
  final nestedState = await nestedHandler.completedResponse();
  integCheck(
    'INT-18 dio extractData unwraps nested payload',
    (nestedState.data as Map)['id'] == 99,
  );

  // Guard blocks malicious payload before schema in dio chain
  final guardedReject = FlodValidateInterceptor.validatePayload(
    raw: {
      'id': 1,
      'title': 'x',
      '__proto__': {'admin': true},
    },
    schema: postSchema,
    guard: tightGuard,
  );
  integCheck(
    'INT-19 dio + guard blocks prototype pollution',
    guardedReject is FlodFailure &&
        (guardedReject as FlodFailure).errors.first.code ==
            FlodErrorCodes.guardPrototypeKey,
  );

  // onResponse reject path
  final rejectResponse = Response(
    requestOptions: RequestOptions(path: '/posts/bad'),
    data: {'id': 'bad', 'title': 'Hello'},
  );
  final rejectHandler = _CapturingResponseHandler();
  dioInterceptor.onResponse(rejectResponse, rejectHandler);
  var rejectOk = false;
  try {
    await rejectHandler.whenComplete();
  } catch (e) {
    rejectOk = e.toString().contains('Validation Exception');
  }
  integCheck(
    'INT-20 dio onResponse rejects with ValidationException',
    rejectOk,
  );

  print('');
  print('   📊 INTEGRATIONS: $integPassed passed | $integFailed failed');
  if (integFailed == 0) {
    print('   🔗 INTEGRATIONS: ALL CASES HOLD');
  } else {
    print('   ⚠️  INTEGRATIONS: REGRESSION DETECTED');
  }
  print('');

  // =========================================================================
  // SECTION ULTIMATE: OMNIBUS MEGA-STRESS MATRIX
  // Covers: compile, composition, refine, union, privacy, i18n, abortEarly,
  //         transforms, nested objects, lists, numbers, strings — all at once.
  // =========================================================================
  print("=== SECTION ULTIMATE: OMNIBUS MEGA-STRESS MATRIX ===");

  var ultimatePassed = 0;
  var ultimateFailed = 0;

  void ultimateCheck(String label, bool ok, [String detail = '']) {
    if (ok) {
      ultimatePassed++;
      print('   ✅ $label');
    } else {
      ultimateFailed++;
      print('   🚨 FAIL: $label${detail.isEmpty ? '' : ' -> $detail'}');
    }
  }

  // --- Base building blocks (12.1 Schema Reuse) ---
  final baseUser = Flod.object({
    'id': Flod.int().positive(),
    'email': Flod.string().trim().toLowerCase().email(),
    'role': Flod.literal('user'),
  });

  final baseProfile = Flod.object({
    'displayName': Flod.string().min(2).max(64).trim(),
    'age': Flod.int().min(13).max(120).optional(),
    'tags': Flod.list(
      schema: Flod.string().trim(),
    ).min(0).max(10).uniqueItems(),
  });

  // --- Composition chain (18.x) ---
  final checkoutBase = baseUser
      .extend({
        'profile': baseProfile,
        'billing': Flod.object({
          'country': Flod.string().fixedLength(2),
          'zip': Flod.string().min(3).max(12),
        }),
      })
      .merge(
        Flod.object({
          'loyaltyPoints': Flod.int().nonNegative().defaultValue(0),
        }),
      );

  final paymentUnion = Flod.union([
    Flod.object({
      'method': Flod.literal('card'),
      'pan': Flod.string().creditCard().secret(),
      'cvv': Flod.string().cvv().secret(),
      'exp': Flod.string().regex(RegExp(r'^\d{2}/\d{2}$')),
    }),
    Flod.object({
      'method': Flod.literal('crypto'),
      'wallet': Flod.string().fixedLength(42),
      'chain': Flod.literal('eth'),
    }),
    Flod.object({
      'method': Flod.literal('invoice'),
      'company': Flod.string().min(2),
      'taxId': Flod.string().regex(RegExp(r'^[A-Z0-9-]{5,20}$')),
    }),
  ]).discriminatedBy('method');

  final orderItems = Flod.list(
    schema: Flod.object({
      'sku': Flod.string().min(3).max(32),
      'qty': Flod.int().positive().max(999),
      'price': Flod.double().nonNegative(),
    }),
  ).min(1).max(50);

  // --- Full schema with refine + compile (12.3, 21.x) ---
  final rawCheckoutSchema = checkoutBase
      .extend({
        'password': Flod.string().min(8).minNumbers(2).minUppercase(1).secret(),
        'confirmPassword': Flod.string().secret(),
        'payment': paymentUnion,
        'items': orderItems,
        'metadata': Flod.object({
          'source': Flod.string().defaultValue('web'),
          'campaign': Flod.string().nullable(),
        }).passthrough(),
      })
      .refine(
        (data) => data['password'] == data['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
      )
      .refine(
        (data) {
          final items = data['items'] as List?;
          if (items == null) return true;
          final totalQty = items.fold<int>(
            0,
            (sum, item) => sum + ((item as Map)['qty'] as int? ?? 0),
          );
          return totalQty <= 500;
        },
        code: 'cart_qty_limit',
        path: ['items'],
      );

  ValidatorCompiler.instance.clearCache();
  final compiledCheckout = rawCheckoutSchema.compile();
  ultimateCheck(
    'ULT-01 compile() marks schema as compiled',
    compiledCheckout.isCompiled,
  );
  ultimateCheck(
    'ULT-02 compile() identity cache hit',
    identical(compiledCheckout, rawCheckoutSchema.compile()),
  );

  final partialUpdateSchema = checkoutBase
      .partial(deep: true)
      .pick(['profile', 'billing', 'loyaltyPoints'])
      .omit(['loyaltyPoints'])
      .compile();

  // --- Valid mega-payload ---
  final validCheckoutPayload = {
    'id': 42,
    'email': '  PRO.User@Example.COM  ',
    'role': 'user',
    'profile': {
      'displayName': '  Pro User  ',
      'age': 28,
      'tags': ['vip', 'beta'],
    },
    'billing': {'country': 'UA', 'zip': '01001'},
    'loyaltyPoints': 150,
    'password': 'SecurePass99',
    'confirmPassword': 'SecurePass99',
    'payment': {
      'method': 'card',
      'pan': '4111111111111111',
      'cvv': '123',
      'exp': '12/30',
    },
    'items': [
      {'sku': 'SKU-001', 'qty': 2, 'price': 19.99},
      {'sku': 'SKU-002', 'qty': 1, 'price': 5.0},
    ],
    'metadata': {
      'source': 'mobile',
      'campaign': null,
      'extra_analytics_key': {'nested': true},
    },
  };

  final validRaw = rawCheckoutSchema.safeParse(validCheckoutPayload);
  final validCompiled = compiledCheckout.safeParse(validCheckoutPayload);
  ultimateCheck(
    'ULT-03 raw schema accepts valid checkout',
    validRaw is FlodSuccess,
  );
  ultimateCheck(
    'ULT-04 compiled schema accepts valid checkout',
    validCompiled is FlodSuccess,
  );
  ultimateCheck(
    'ULT-05 compiled == raw semantics on success',
    validRaw is FlodSuccess &&
        validCompiled is FlodSuccess &&
        (validRaw as FlodSuccess).data['email'] ==
            (validCompiled as FlodSuccess).data['email'],
  );

  if (validCompiled case FlodSuccess(data: final checkoutData)) {
    ultimateCheck(
      'ULT-06 email transform pipeline (trim + lower)',
      checkoutData['email'] == 'pro.user@example.com',
    );
    ultimateCheck(
      'ULT-07 displayName trim applied',
      (checkoutData['profile'] as Map)['displayName'] == 'Pro User',
    );
    ultimateCheck(
      'ULT-08 passthrough metadata key preserved',
      (checkoutData['metadata'] as Map).containsKey('extra_analytics_key'),
    );
  }

  // --- Toxic payloads matrix ---
  final passwordMismatchPayload = Map<String, dynamic>.from(
    validCheckoutPayload,
  )..['confirmPassword'] = 'DifferentPassword99';

  final mismatchResult = compiledCheckout.safeParse(passwordMismatchPayload);
  ultimateCheck(
    'ULT-09 refine catches password mismatch',
    mismatchResult is FlodFailure &&
        (mismatchResult as FlodFailure).errors.any(
          (e) => e.code == 'passwords_match',
        ),
  );
  if (mismatchResult case FlodFailure(errors: final mismatchErrors)) {
    ultimateCheck(
      'ULT-10 refine error targets confirmPassword path',
      mismatchErrors.any(
        (e) => e.path.toReadable().contains('confirmPassword'),
      ),
    );
  }

  final cartOverflowPayload = Map<String, dynamic>.from(validCheckoutPayload)
    ..['items'] = List.generate(
      10,
      (i) => {'sku': 'SKU-$i', 'qty': 60, 'price': 1.0},
    );

  final cartResult = compiledCheckout.safeParse(cartOverflowPayload);
  ultimateCheck(
    'ULT-11 refine catches cart quantity overflow',
    cartResult is FlodFailure &&
        (cartResult as FlodFailure).errors.any(
          (e) => e.code == 'cart_qty_limit',
        ),
  );

  final strictFailPayload = {
    'profile': {'displayName': 'XY'},
    'billing': {'country': 'UA', 'zip': '01001'},
    'hacker_injected_key': 'payload',
  };
  ultimateCheck(
    'ULT-12 partial+pick+omit update schema accepts sparse patch',
    partialUpdateSchema.safeParse(strictFailPayload) is FlodSuccess,
  );

  final duplicateTagsPayload = Map<String, dynamic>.from(validCheckoutPayload);
  (duplicateTagsPayload['profile'] as Map)['tags'] = ['vip', '  vip  '];
  ultimateCheck(
    'ULT-13 uniqueItems catches trimmed duplicates',
    compiledCheckout.safeParse(duplicateTagsPayload) is FlodFailure,
  );

  final badDiscriminantPayload = Map<String, dynamic>.from(validCheckoutPayload)
    ..['payment'] = {
      'method': 'card',
      'pan': '4111111111111112',
      'cvv': '12A',
      'exp': '13/30',
    };
  final badPaymentResult = compiledCheckout.safeParse(badDiscriminantPayload);
  ultimateCheck(
    'ULT-14 discriminated union validates nested card fields',
    badPaymentResult is FlodFailure,
  );

  // --- Privacy audit on secret fields ---
  if (badPaymentResult is FlodFailure) {
    final secretCheckout = compiledCheckout.secret();
    final secretFail = secretCheckout.safeParse(badDiscriminantPayload);
    var leakDetected = false;
    if (secretFail case FlodFailure(errors: final secretErrors)) {
      for (final err in secretErrors) {
        final raw = err.value?.toString() ?? '';
        if (err.isSecret &&
            err.value != null &&
            raw != '[HIDDEN]' &&
            !raw.contains('null') &&
            (raw.contains('4111') || raw.contains('12A'))) {
          leakDetected = true;
        }
      }
    }
    ultimateCheck('ULT-15 secret() masks PAN/CVV in error logs', !leakDetected);
  } else {
    ultimateCheck(
      'ULT-15 secret() masks PAN/CVV in error logs',
      false,
      'bad payment did not fail',
    );
  }

  // --- AbortEarly vs collect-all ---
  final abortSchema = Flod.object({
    'a': Flod.string().email(),
    'b': Flod.int().positive(),
    'c': Flod.string().uuid(),
  }).stopOnFirstError().compile();

  final multiErrorPayload = {'a': 'not-email', 'b': -1, 'c': 'bad-uuid'};
  final abortResult = abortSchema.safeParse(multiErrorPayload);
  ultimateCheck(
    'ULT-16 abortEarly stops at first error',
    abortResult is FlodFailure &&
        (abortResult as FlodFailure).errors.length == 1,
  );

  final collectSchema = Flod.object({
    'a': Flod.string().email(),
    'b': Flod.int().positive(),
    'c': Flod.string().uuid(),
  }).compile();
  final collectResult = collectSchema.safeParse(multiErrorPayload);
  ultimateCheck(
    'ULT-17 collect-all gathers multiple errors',
    collectResult is FlodFailure &&
        (collectResult as FlodFailure).errors.length >= 2,
  );

  // --- parse() exception path ---
  try {
    Flod.int().parse('not-a-number');
    ultimateCheck('ULT-18 parse() throws on invalid type', false);
  } on ValidationException {
    ultimateCheck('ULT-18 parse() throws ValidationException', true);
  } catch (e) {
    ultimateCheck('ULT-18 parse() throws ValidationException', false, '$e');
  }

  // --- i18n / DX readable output ---
  if (collectResult case FlodFailure(errors: final _)) {
    final failure = collectResult as FlodFailure;
    final messages = failure.getMessages();
    final fieldsMap = failure.getFieldsMap();
    final grouped = failure.getGroupedFieldsMap();
    final readable = failure.toReadable();
    ultimateCheck('ULT-19 getMessages() non-empty', messages.isNotEmpty);
    ultimateCheck('ULT-20 getFieldsMap() non-empty', fieldsMap.isNotEmpty);
    ultimateCheck('ULT-21 getGroupedFieldsMap() non-empty', grouped.isNotEmpty);
    ultimateCheck('ULT-22 toReadable() non-empty', readable.isNotEmpty);
  } else {
    ultimateCheck(
      'ULT-19..22 i18n/DX outputs',
      false,
      'collectResult not failure',
    );
  }

  // --- Performance hot-loop: compiled vs raw parity (100 iterations) ---
  var parityOk = true;
  for (var i = 0; i < 100; i++) {
    final payload = Map<String, dynamic>.from(validCheckoutPayload)
      ..['id'] = i + 1;
    final r1 = rawCheckoutSchema.safeParse(payload);
    final r2 = compiledCheckout.safeParse(payload);
    if (r1 is FlodSuccess != r2 is FlodSuccess) {
      parityOk = false;
      break;
    }
  }
  ultimateCheck('ULT-23 compiled/raw parity x100 iterations', parityOk);

  // --- SchemaPool identity ---
  ultimateCheck(
    'ULT-24 SchemaPool singleton identity',
    identical(SchemaPool.string, Flod.string()) &&
        identical(SchemaPool.int, Flod.int()),
  );

  print('');
  print(
    '   📊 ULTIMATE MATRIX: $ultimatePassed passed | $ultimateFailed failed',
  );
  if (ultimateFailed == 0) {
    print('   🏆 OMNIBUS STRESS: ALL INVARIANTS HOLD');
  } else {
    print(
      '   ⚠️  OMNIBUS STRESS: REGRESSION DETECTED — inspect failures above',
    );
  }
  print('');

  print("=================================================================");
  print("    COMPLETE HIGH-STRESS VERIFICATION MATRIX RUN FINISHED        ");
  print("=================================================================");
}

/// Exposes [ResponseInterceptorHandler.future] for Dio interceptor demos.
final class _CapturingResponseHandler extends ResponseInterceptorHandler {
  Future<Response> completedResponse() async {
    final state = await future;
    return (state as dynamic).data as Response;
  }

  Future<void> whenComplete() => future;
}
