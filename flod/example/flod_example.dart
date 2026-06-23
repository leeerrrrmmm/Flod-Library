import 'package:flod/flod.dart';

void main() {
  print("=================================================================");
  print("          FLOD PRIVACY & FUNCTIONAL COMPLETE MATRIX             ");
  print("=================================================================\n");

  /// Главный хелпер для запуска сценариев валидации.
  /// Проверяет три состояния: успех на валидных данных, публичный лог ошибок
  /// и автоматическое маскирование [HIDDEN] для приватных (.secret()) валидаторов.
  void runScenario({
    required String name,
    required Validator publicValidator,
    required Validator secretValidator,
    required dynamic validValue,
    required dynamic invalidValue,
  }) {
    print("📌 [Validator: $name]");

    // 1. ТЕСТ: ПРАВИЛЬНЫЕ ДАННЫЕ
    final resValid = publicValidator.safeParse(validValue);
    if (resValid.success) {
      print(
        "   ✅ SUCCESS -> Вход: $validValue | Выход: ${resValid.data} [Type: ${resValid.data.runtimeType}]",
      );
    } else {
      print("   🚨 CRITICAL FAIL -> Ожидался успех, но схема упала!");
      print(
        "                       Ошибки: ${resValid.errors?.map((e) => '[${e.path.toReadable()}] ${e.message}').join(', ')}",
      );
    }

    // 2. ТЕСТ: НЕПРАВИЛЬНЫЕ ДАННЫЕ (Публичный лог)
    final resInvalid = publicValidator.safeParse(invalidValue);
    if (!resInvalid.success) {
      print("   ❌ PUBLIC FAIL -> Ошибок: ${resInvalid.errors!.length}");
      for (final err in resInvalid.errors!) {
        print(
          "         ↳ Path: '${err.path.toReadable()}' | Code: ${err.code} | Message: ${err.message} | Value: ${err.rejectedValue}",
        );
      }
    } else {
      print(
        "   🚨 CRITICAL FAIL -> Ожидался фейл, но публичный валидатор пропустил: $invalidValue",
      );
    }

    // 3. ТЕСТ: МАСКИРОВАНИЕ ПРИВАТНОСТИ (.secret)
    final resSecret = secretValidator.safeParse(invalidValue);
    if (!resSecret.success) {
      print("   🔒 SECRET FAIL -> Ошибок: ${resSecret.errors!.length}");
      for (final err in resSecret.errors!) {
        print(
          "         ↳ Path: '${err.path}' | Code: ${err.code} | Masked Value: ${err.rejectedValue}",
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

  try {
    print("📌 [Testing: parse() Exception Throw]");
    Flod.string().parse(12345);
    print(
      "   🚨 CRITICAL FAIL -> parse() не выбросил исключение при неверном типе!",
    );
  } catch (e) {
    print("   ✅ SUCCESS -> parse() корректно выбросил исключение: $e\n");
  }

  // =========================================================================
  // СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS
  // =========================================================================
  print("=== СЕКЦИЯ 2: NULLABLE & OPTIONAL DECORATORS ===");

  runScenario(
    name: "2.1. .nullable() Fallthrough",
    publicValidator: Flod.string()
        .min(5, "Min length error", "min_length_error")
        .nullable(),
    secretValidator: Flod.string()
        .min(5, "Min length error", "min_length_error [SECRET]")
        .nullable()
        .secret(),
    validValue: null,
    invalidValue: "dev",
  );

  runScenario(
    name: "2.2. .optional() Fallthrough",
    publicValidator: Flod.int().min(18).optional(),
    secretValidator: Flod.int().min(18).optional().secret(),
    validValue: null,
    invalidValue: 12,
  );

  // =========================================================================
  // СЕКЦИЯ 3: OBJECT SCHEMA MODES
  // =========================================================================
  print("=== СЕКЦИЯ 3: OBJECT SCHEMA MODES ===");

  runScenario(
    name: "3.1. .strict() Mode",
    publicValidator: Flod.object({"name": Flod.string()}).strict(),
    secretValidator: Flod.object({"name": Flod.string()}).strict().secret(),
    validValue: {"name": "Maksym"},
    invalidValue: {"name": "Maksym", "unknown_hacker_key": "payload"},
  );

  runScenario(
    name: "3.2. .passthrough() Mode",
    publicValidator: Flod.object({"name": Flod.string()}).passthrough(),
    secretValidator: Flod.object({
      "name": Flod.string(),
    }).passthrough().secret(),
    validValue: {"name": "Maksym", "extra_key": "it's okay"},
    invalidValue: {"name": 123},
  );

  runScenario(
    name: "3.3. Nested Validation Paths",
    publicValidator: Flod.object({
      "user": Flod.object({
        "profile": Flod.object({"age": Flod.int().min(18)}),
      }),
    }),
    secretValidator: Flod.object({
      "user": Flod.object({
        "profile": Flod.object({"age": Flod.int().min(18)}),
      }),
    }).secret(),
    validValue: {
      "user": {
        "profile": {"age": 25},
      },
    },
    invalidValue: {
      "user": {
        "profile": {"age": 10},
      },
    },
  );

  // =========================================================================
  // СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS
  // =========================================================================
  print("=== СЕКЦИЯ 4 & 5: COLLECTIONS & TRANSFORMS ===");

  runScenario(
    name:
        "4.1 & 5.2. items(schema) & Built-in Transforms (.trim / .toLowerCase)",
    publicValidator: Flod.list(schema: Flod.string().trim().toLowerCase()),
    secretValidator: Flod.list(
      schema: Flod.string().trim().toLowerCase(),
    ).secret(),
    validValue: ["  MAKSYM ", " FLOD "],
    invalidValue: ["  MAKSYM ", 42],
  );

  runScenario(
    name: "4.2. Constraints (minItems & maxItems)",
    publicValidator: Flod.list().minItems(2).maxItems(4),
    secretValidator: Flod.list().minItems(2).maxItems(4).secret(),
    validValue: [1, 2, 3],
    invalidValue: [1],
  );

  runScenario(
    name: "4.3. uniqueItems (Normalized Verification)",
    publicValidator: Flod.list(schema: Flod.string().trim()).uniqueItems(),
    secretValidator: Flod.list(
      schema: Flod.string().trim(),
    ).uniqueItems().secret(),
    validValue: ["a", "b", "c"],
    invalidValue: ["dart", "  dart  "],
  );

  // -------------------------------------------------------------------------
  // НОВЫЕ СТРЕСС-ТЕСТЫ ДЛЯ СЕКЦИИ 5 (TRANSFORM NUANCES)
  // -------------------------------------------------------------------------

  runScenario(
    name: "5.1.1. Custom Same-Type Transform (String Modification)",
    publicValidator: Flod.string().transform((v) => "MODIFIED_$v"),
    secretValidator: Flod.string().transform((v) => "MODIFIED_$v").secret(),
    validValue: "data", // На выходе ожидаем "MODIFIED_data"
    invalidValue:
        12345, // Должен упасть на проверке типа String до трансформера
  );

  runScenario(
    name: "5.1.2. Complex Type-Changing Transform (String -> int)",
    // Проверяем, умеет ли движок менять выходной тип данных в ParseResult
    publicValidator: Flod.string().transform((v) => int.tryParse(v) ?? 0),
    secretValidator: Flod.string()
        .transform((v) => int.tryParse(v) ?? 0)
        .secret(),
    validValue: "150", // На выходе ожидаем int со значением 150
    invalidValue: 999, // Передаем некорректный исходный тип (int вместо String)
  );

  runScenario(
    name: "5.3.1. Execution Order (Transform runs BEFORE validation rules)",
    // Сначала обрезаем пробелы, и только потом проверяем фиксированную длину.
    // Если бы валидация шла ДО трансформера, " EUR " упал бы с ошибкой длины (5 вместо 3).
    publicValidator: Flod.string().trim().fixedLength(
      3,
      "Fixed length error",
      "fixed_length_error",
    ),
    secretValidator: Flod.string()
        .trim()
        .fixedLength(3, "Fixed length error", "fixed_length_error [SECRET]")
        .secret(),
    validValue:
        "  EUR  ", // Успешно трансформируется в "EUR" и проходит валидацию
    invalidValue:
        "  RUBLE  ", // Трансформируется в "RUBLE", падает на ограничении длины
  );

  runScenario(
    name:
        "5.4. Ultimate Deep Chaining Pipeline (Multi-stage mutation & Privacy check)",
    // Цепочка: String -> Стрип пробелов -> Ловеркейс -> Изменение типа в int (длина) -> Проверка кратности
    // Внимание: Если твоя архитектура требует вызова .pipe() для перехода между валидаторами
    // разных типов, этот тест подсветит, как ведет себя система типов Dart.
    publicValidator: Flod.string()
        .trim()
        .toLowerCase()
        .transform((v) => v.length) // С этого момента тип Out стал int
        .transform(
          (len) => len * 2,
        ), // Удваиваем длину (тест последовательных трансформеров)
    secretValidator: Flod.string()
        .trim()
        .toLowerCase()
        .transform((v) => v.length)
        .transform((len) => len * 2)
        .secret(),
    validValue: "  FLOD  ", // "flod" -> длина 4 -> на выходе int 8.
    invalidValue:
        100, // Падает на старте из-за несоответствия базовому типу String
  );

  // =========================================================================
  // СЕКЦИЯ 19: NUMBER VALIDATOR SUITE
  // =========================================================================
  print("=== СЕКЦИЯ 19: NUMBER VALIDATOR SUITE ===");

  runScenario(
    name: "19.2. IntValidator (is int, min, max)",
    publicValidator: Flod.int().min(10).max(20),
    secretValidator: Flod.int().min(10).max(20).secret(),
    validValue: 15,
    invalidValue: 25,
  );

  runScenario(
    name: "19.3. DoubleValidator (NaN & Infinity Guards)",
    publicValidator: Flod.double(),
    secretValidator: Flod.double().secret(),
    validValue: 3.14,
    invalidValue: double.infinity,
  );

  runScenario(
    name: "19.6.1. Specialized Signs (.positive)",
    publicValidator: Flod.int().positive(),
    secretValidator: Flod.int().positive().secret(),
    validValue: 42,
    invalidValue: 0, // Ноль не является строго положительным
  );

  runScenario(
    name: "19.6.2. Specialized Signs (.negative)",
    publicValidator: Flod.int().negative(),
    secretValidator: Flod.int().negative().secret(),
    validValue: -5,
    invalidValue: 12,
  );

  runScenario(
    name: "19.6.3. Specialized Signs (.nonPositive)",
    publicValidator: Flod.int().nonPositive(),
    secretValidator: Flod.int().nonPositive().secret(),
    validValue: 0, // Ноль разрешен
    invalidValue: 1,
  );

  runScenario(
    name: "19.6.4. Specialized Signs (.nonNegative)",
    publicValidator: Flod.int().nonNegative(),
    secretValidator: Flod.int().nonNegative().secret(),
    validValue: 0, // Ноль разрешен
    invalidValue: -1,
  );

  runScenario(
    name: "19.6.5. Arithmetic Rules (.multipleOf)",
    publicValidator: Flod.int().multipleOf(3),
    secretValidator: Flod.int().multipleOf(3).secret(),
    validValue: 9,
    invalidValue: 7,
  );

  // =========================================================================
  // СЕКЦИЯ 20: STRING DOMAIN FORMATS
  // =========================================================================
  print("=== СЕКЦИЯ 20: STRING DOMAIN FORMATS ===");

  runScenario(
    name: "20.2. .email() Verification",
    publicValidator: Flod.string().email(),
    secretValidator: Flod.string().email().secret(),
    validValue: "dev@flod.io",
    invalidValue: "bad_email",
  );

  runScenario(
    name: "20.3. Password Policies (Uppercase, Numbers, Symbols)",
    publicValidator: Flod.string().minUppercase(1).minNumbers(1).minSymbols(1),
    secretValidator: Flod.string()
        .minUppercase(1)
        .minNumbers(1)
        .minSymbols(1)
        .secret(),
    validValue: "Secure1!",
    invalidValue: "secure",
  );

  runScenario(
    name: "20.4.1. Specialized Formats (.url)",
    publicValidator: Flod.string().url(),
    secretValidator: Flod.string().url().secret(),
    validValue: "https://flod.io",
    invalidValue: "just-a-string",
  );

  runScenario(
    name: "20.4.2. Specialized Formats (.phoneNumber)",
    publicValidator: Flod.string().phoneNumber(),
    secretValidator: Flod.string().phoneNumber().secret(),
    validValue: "+1234567890",
    invalidValue: "just-a-string",
  );

  runScenario(
    name: "20.4.3. Specialized Formats (.uuid)",
    publicValidator: Flod.string().uuid(),
    secretValidator: Flod.string().uuid().secret(),
    validValue: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    invalidValue: "just-a-string",
  );

  runScenario(
    name: "20.6. .fixedLength() Control",
    publicValidator: Flod.string().fixedLength(
      3,
      "Fixed length error",
      "fixed_length_error",
    ),
    secretValidator: Flod.string()
        .fixedLength(3, "Fixed length error", "fixed_length_error [SECRET]")
        .secret(),
    validValue: "EUR",
    invalidValue: "RUBLE",
  );

  runScenario(
    name: "20.7. Credit Card Domain Logic",
    publicValidator: Flod.string().creditCard(),
    secretValidator: Flod.string().creditCard().secret(),
    validValue: "4111111111111111",
    invalidValue: "41111-error",
  );

  runScenario(
    name: "20.8. CVV Domain Logic",
    publicValidator: Flod.string().cvv(),
    secretValidator: Flod.string().cvv().secret(),
    validValue: "123",
    invalidValue: "41111-error",
  );

  print("=================================================================");
  print("          COMPLETE VERIFICATION MATRIX RUN FINISHED              ");
  print("=================================================================");
}
