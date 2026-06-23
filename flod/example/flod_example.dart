import 'package:flod/flod.dart';

void main() {
  print("=================================================================");
  print("          FLOD PRIVACY MATRIX: EXHAUSTIVE DIAGNOSTIC SUITE       ");
  print("=================================================================\n");

  /// Умный диагностический хелпер.
  /// Исключает ложные срабатывания и детально подсвечивает логику Flod.
  void runScenario({
    required String name,
    required Validator publicValidator,
    required Validator secretValidator,
    required dynamic validValue,
    required dynamic invalidValue,
  }) {
    print("📌 [Rule: $name]");

    // 1. ТЕСТ: ПРАВИЛЬНЫЕ ДАННЫЕ
    final resValid = publicValidator.safeParse(validValue);
    if (resValid.success) {
      // Выводим не только значение, но и runtimeType для проверки строгости типов
      print(
        "   ✅ ПРАВИЛЬНО          -> SUCCESS: ${resValid.data} [Type: ${resValid.data.runtimeType}]",
      );
    } else {
      // Если safeParse вернул ошибку на валидных данных — это бага в логике правила!
      print("   🚨 CRITICAL TEST FAIL -> ОЖИДАЛСЯ УСПЕХ, НО ПРАВИЛО УПАЛО!");
      print(
        "                            Ошибки: ${resValid.errors?.map((e) => e.toString()).join(', ')}",
      );
    }

    // 2. ТЕСТ: НЕПРАВИЛЬНЫЕ ДАННЫЕ (Публичный лог)
    final resInvalid = publicValidator.safeParse(invalidValue);
    if (resInvalid.success == false) {
      final errInvalid = resInvalid.errors!.first.toString();
      print("   ❌ НЕПРАВИЛЬНО        -> FAIL: $errInvalid");
    } else {
      print(
        "   🚨 CRITICAL TEST FAIL -> ОЖИДАЛСЯ ФЕЙЛ, НО ВАЛИДАТОР ПРОПУСТИЛ ДАННЫЕ! (Value: $invalidValue)",
      );
    }

    // 3. ТЕСТ: НЕПРАВИЛЬНЫЕ ДАННЫЕ + МАСКИРОВАНИЕ (Секретный лог)
    final resSecret = secretValidator.safeParse(invalidValue);
    if (resSecret.success == false) {
      final errSecret = resSecret.errors!.first.toString();
      print("   🔒 НЕПРАВИЛЬНО HIDDEN -> FAIL: $errSecret\n");
    } else {
      print(
        "   🚨 CRITICAL TEST FAIL -> SECRET ОЖИДАЛСЯ ФЕЙЛ, НО ВАЛИДАТОР ПРОПУСТИЛ ДАННЫЕ!\n",
      );
    }
  }

  // =========================================================================
  // СЕКЦИЯ 1: СТРОКИ (CORE & RULES)
  // =========================================================================
  print("=== СЕКЦИЯ 1: СТРОКИ (CORE & RULES) ===");

  runScenario(
    name: "String Type Check",
    publicValidator: Flod.string(),
    secretValidator: Flod.string().secret(),
    validValue: "Hello Flod",
    invalidValue: 42,
  );

  runScenario(
    name: "String .min()",
    publicValidator: Flod.string().min(5, "Too short", "min_err"),
    secretValidator: Flod.string()
        .min(5, "Too short", "min_err SECRET")
        .secret(),
    validValue: "DartLanguage",
    invalidValue: "dev",
  );

  runScenario(
    name: "String .max()",
    publicValidator: Flod.string().max(5, "Too long", "max_err"),
    secretValidator: Flod.string()
        .max(5, "Too long", "max_err SECRET")
        .secret(),
    validValue: "Flod",
    invalidValue: "Framework",
  );

  runScenario(
    name: "String .regex()",
    publicValidator: Flod.string().regex(
      RegExp(r'^[0-9]+$'),
      "Numbers only",
      "regex_err",
    ),
    secretValidator: Flod.string()
        .regex(RegExp(r'^[0-9]+$'), "Numbers only", "regex_err SECRET")
        .secret(),
    validValue: "2026",
    invalidValue: "year2026",
  );

  // =========================================================================
  // СЕКЦИЯ 2: ДОМЕННЫЕ РАСШИРЕНИЯ СТРОК
  // =========================================================================
  print("\n=== СЕКЦИЯ 2: ДОМЕННЫЕ РАСШИРЕНИЯ СТРОК ===");

  runScenario(
    name: "Email Validation",
    publicValidator: Flod.string().email(),
    secretValidator: Flod.string().email().secret(),
    validValue: "maksym@flod.dev",
    invalidValue: "invalid_email_format",
  );

  runScenario(
    name: "URL Validation",
    publicValidator: Flod.string().url(),
    secretValidator: Flod.string().url().secret(),
    validValue: "https://pub.dev/packages/flod",
    invalidValue: "not-a-valid-url",
  );

  runScenario(
    name: "Phone Number Validation",
    publicValidator: Flod.string().phoneNumber(),
    secretValidator: Flod.string().phoneNumber().secret(),
    validValue: "+380501234567",
    invalidValue: "abc-phone",
  );

  runScenario(
    name: "UUID v4 Validation",
    publicValidator: Flod.string().uuid(),
    secretValidator: Flod.string().uuid().secret(),
    // ИСПРАВЛЕНО: Раньше был UUID v1, из-за чего тест падал. Теперь тут чистый v4 (четверка в начале 3-й группы).
    validValue: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    invalidValue: "custom-token-uid",
  );

  runScenario(
    name: "Password Uppercase Policy",
    publicValidator: Flod.string().minUppercase(2),
    secretValidator: Flod.string().minUppercase(2).secret(),
    validValue: "FLodFramework",
    invalidValue: "flod",
  );

  runScenario(
    name: "Password Numbers Policy",
    publicValidator: Flod.string().minNumbers(2),
    secretValidator: Flod.string().minNumbers(2).secret(),
    validValue: "Pass12",
    invalidValue: "Password",
  );

  runScenario(
    name: "Password Symbols Policy",
    publicValidator: Flod.string().minSymbols(2),
    secretValidator: Flod.string().minSymbols(2).secret(),
    validValue: "Admin!!",
    invalidValue: "Admin123",
  );

  runScenario(
    name: "Fixed Length String",
    publicValidator: Flod.string().fixedLength(
      3,
      "Too short",
      "fixed_length_err",
    ),
    secretValidator: Flod.string()
        .fixedLength(3, "Too short", "fixed_length_err SECRET")
        .secret(),
    validValue: "USD",
    invalidValue: "EUROPE",
  );

  runScenario(
    name: "Credit Card Validation",
    publicValidator: Flod.string().creditCard(),
    secretValidator: Flod.string().creditCard().secret(),
    validValue: "4111111111111111",
    invalidValue: "4111-card-error",
  );

  runScenario(
    name: "CVV Validation",
    publicValidator: Flod.string().cvv(),
    secretValidator: Flod.string().cvv().secret(),
    validValue: "123",
    invalidValue: "12",
  );

  // =========================================================================
  // СЕКЦИЯ 3: ЧИСЛА (INT & DOUBLE)
  // =========================================================================
  print("\n=== СЕКЦИЯ 3: ЧИСЛА (INT & DOUBLE) ===");

  runScenario(
    name: "Int Type Check",
    publicValidator: Flod.int(),
    secretValidator: Flod.int().secret(),
    validValue: 100,
    invalidValue: "not_an_int",
  );

  runScenario(
    name: "Int .min() Boundary",
    publicValidator: Flod.int().min(10),
    secretValidator: Flod.int().min(10).secret(),
    validValue: 15,
    invalidValue: 4,
  );

  runScenario(
    name: "Int .max() Boundary",
    publicValidator: Flod.int().max(100),
    secretValidator: Flod.int().max(100).secret(),
    validValue: 50,
    invalidValue: 105,
  );

  runScenario(
    name: "Int .positive() Rule",
    publicValidator: Flod.int().positive(),
    secretValidator: Flod.int().positive().secret(),
    validValue: 1,
    invalidValue: -5,
  );

  runScenario(
    name: "Double Type Check",
    publicValidator: Flod.double(),
    secretValidator: Flod.double().secret(),
    validValue: 45.55,
    invalidValue: "not_a_double",
  );

  runScenario(
    name: "Double .multipleOf() Float Point Rule",
    publicValidator: Flod.double().multipleOf(0.25),
    secretValidator: Flod.double().multipleOf(0.25).secret(),
    validValue: 10.75,
    invalidValue: 10.81,
  );

  // =========================================================================
  // СЕКЦИЯ 4: ДЕКОРАТОРЫ (NULLABLE & OPTIONAL)
  // =========================================================================
  print("\n=== СЕКЦИЯ 4: ДЕКОРАТОРЫ (NULLABLE & OPTIONAL) ===");

  runScenario(
    name: "Nullable Decorator (Validation Step Fallthrough)",
    publicValidator: Flod.string().min(5, "Too short", "min_err").nullable(),
    secretValidator: Flod.string()
        .min(5, "Too short", "min_err")
        .nullable()
        .secret(),
    validValue: null,
    invalidValue: "abc",
  );

  runScenario(
    name: "Optional Decorator (Validation Step Fallthrough)",
    publicValidator: Flod.int().min(18).optional(),
    secretValidator: Flod.int().min(18).optional().secret(),
    validValue: null,
    invalidValue: 12,
  );

  // =========================================================================
  // СЕКЦИЯ 5: КОЛЛЕКЦИИ И СХЕМЫ ОБЪЕКТОВ
  // =========================================================================
  print("\n=== СЕКЦИЯ 5: КОЛЛЕКЦИИ И СХЕМЫ ОБЪЕКТОВ ===");

  runScenario(
    name: "List .minItems() Length Rule",
    publicValidator: Flod.list().minItems(3),
    secretValidator: Flod.list().minItems(3).secret(),
    validValue: [1, 2, 3],
    invalidValue: [1, 2],
  );

  runScenario(
    name: "List .uniqueItems() Constraint",
    publicValidator: Flod.list().uniqueItems(),
    secretValidator: Flod.list().uniqueItems().secret(),
    validValue: ["a", "b", "c"],
    invalidValue: ["a", "b", "a"],
  );

  runScenario(
    name: "List Nested Element Type Validation",
    publicValidator: Flod.list(schema: Flod.int()),
    secretValidator: Flod.list(schema: Flod.int()).secret(),
    validValue: [1, 2, 3],
    invalidValue: [1, "bad_element", 3],
  );

  runScenario(
    name: "Object Map Type Check",
    publicValidator: Flod.object({}),
    secretValidator: Flod.object({}).secret(),
    validValue: <String, dynamic>{},
    invalidValue: "string_instead_of_map",
  );

  runScenario(
    name: "Object .strict() Mode (Block Extra Keys)",
    publicValidator: Flod.object({"allowed": Flod.string()}).strict(),
    secretValidator: Flod.object({"allowed": Flod.string()}).strict().secret(),
    validValue: {"allowed": "yes"},
    invalidValue: {"allowed": "yes", "hacker_key": "exploit_payload"},
  );

  runScenario(
    name: "Object Schema Missing Required Field",
    publicValidator: Flod.object({"requiredKey": Flod.string()}),
    secretValidator: Flod.object({"requiredKey": Flod.string()}).secret(),
    validValue: {"requiredKey": "present"},
    invalidValue: {"wrongKey": "data"},
  );

  print("=================================================================");
  print("          DIAGNOSTIC RUN COMPLETED IN STRICT SEQUENCE            ");
  print("=================================================================");
}
