import 'package:flod/flod.dart';

void main() {
  print("=================================================================");
  print("          FLOD VALIDATION ENGINE - COMPLETE TEST SUITE           ");
  print("=================================================================\n");

  // Вспомогательная функция для красивого вывода результатов проверки
  void printResult(String title, ParseResult result) {
    if (result.success) {
      print("✅ $title: SUCCESS -> Data: ${result.data}");
    } else {
      print("❌ $title: FAIL");

      // ЯВНО указываем тип FlodError вместо final.
      // Теперь компилятор знает, что error.path — это список,
      // и метод .toReadable() на листе начинает работать!
      for (final FlodError error in result.errors ?? []) {
        print(
          "   -> [Path: ${error.path.toReadable()}] ${error.message} (${error.code})",
        );
      }
    }
  }

  // =========================================================================
  // 1. СТРОКИ: ТРАНСФОРМАЦИИ, ДЛИНА И РЕГУЛЯРНЫЕ ВЫРАЖЕНИЯ (Позиционный API)
  // =========================================================================
  print("=== 1. STRING CORE & TRANSFORMS ===");

  final basicString = Flod.string().trim().toLowerCase().min(
    3,
    "Too short string",
    "min_len",
  );

  printResult(
    "String valid transformation",
    basicString.safeParse("   FLOD   "),
  );
  printResult(
    "String failure (too short after trim)",
    basicString.safeParse("  fl  "),
  );
  printResult(
    "String failure (invalid type passed)",
    basicString.safeParse(123),
  );

  // =========================================================================
  // 2. СТРОКИ: ДОМЕННЫЕ ПРАВИЛА И ПОДДЕРЖКА i18n (Именованный API расширений)
  // =========================================================================
  print("\n=== 2. STRING DOMAIN RULES & I18N ===");

  // Тест дефолтных сообщений
  final defaultEmail = Flod.string().email();
  printResult("Email (Default success)", defaultEmail.safeParse("dev@flod.io"));
  printResult(
    "Email (Default failure)",
    defaultEmail.safeParse("invalid-email"),
  );

  // Тест кастомной локализации (i18n)
  final i18nEmail = Flod.string().email(
    message: "Некорректный адрес электронной почты",
    code: "RU_ERR_EMAIL",
  );
  printResult(
    "Email (i18n failure localization check)",
    i18nEmail.safeParse("wrong@"),
  );

  // Тест остальных доменных расширений строк
  final urlValidator = Flod.string().url();
  printResult("URL valid", urlValidator.safeParse("https://dart.dev/guides"));
  printResult("URL invalid", urlValidator.safeParse("ftp://invalid-url"));

  final phoneValidator = Flod.string().phoneNumber();
  printResult("Phone valid", phoneValidator.safeParse("+123456789012"));
  printResult("Phone invalid", phoneValidator.safeParse("0"));

  final uuidValidator = Flod.string().uuid();
  printResult(
    "UUID v4 valid",
    uuidValidator.safeParse("9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"),
  );
  printResult(
    "UUID v4 invalid",
    uuidValidator.safeParse("9b1deb4d-3b7d-3bad-9bdd-2b0d7b3dcb6d"),
  ); // Не '4' в секции версии

  // Тест политик паролей
  final passwordValidator = Flod.string()
      .minUppercase(2)
      .minNumbers(2)
      .minSymbols(2);
  printResult(
    "Password valid policy",
    passwordValidator.safeParse("AA11!!safe"),
  );
  printResult(
    "Password invalid policy (missing uppercase/symbols)",
    passwordValidator.safeParse("a1safe!"),
  );

  // =========================================================================
  // 3. ЧИСЛА: INT И DOUBLE (Границы, полиморфизм и валидация типов)
  // =========================================================================
  print("\n=== 3. NUMBERS (INT & DOUBLE) ===");

  final intValidator = Flod.int()
      .min(10, message: "Must be >= 10")
      .max(50)
      .positive();
  printResult("Int valid range", intValidator.safeParse(25));
  printResult("Int failure (under min)", intValidator.safeParse(5));
  printResult("Int failure (over max)", intValidator.safeParse(60));
  printResult("Int failure (type double passed)", intValidator.safeParse(25.5));

  final doubleValidator = Flod.double().min(0.0).max(100.0).multipleOf(0.25);
  printResult("Double valid float point", doubleValidator.safeParse(10.5));
  printResult(
    "Double failure (NaN / Infinite check)",
    doubleValidator.safeParse(double.nan),
  );
  printResult(
    "Double failure (type int passed)",
    doubleValidator.safeParse(50),
  );

  // =========================================================================
  // 4. ДЕКОРАТОРЫ: NULLABLE И OPTIONAL
  // =========================================================================
  print("\n=== 4. DECORATORS (NULLABLE & OPTIONAL) ===");

  final nullableString = Flod.string().trim().nullable();
  printResult("Nullable explicit null", nullableString.safeParse(null));
  printResult(
    "Nullable with valid data",
    nullableString.safeParse("  Hello  "),
  );
  printResult("Nullable failure on wrong type", nullableString.safeParse(45.6));

  final optionalInt = Flod.int().optional();
  printResult("Optional missing/null value", optionalInt.safeParse(null));
  printResult("Optional with valid int", optionalInt.safeParse(42));

  // =========================================================================
  // 5. КОЛЛЕКЦИИ: СПИСКИ (Длина, уникальность, вложенные схемы, поиск по индексам)
  // =========================================================================
  print("\n=== 5. LISTS & ARRAYS ===");

  final simpleList = Flod.list().minItems(2).maxItems(4);
  printResult("Simple List length valid", simpleList.safeParse([1, 2, 3]));
  printResult(
    "Simple List failure (too long)",
    simpleList.safeParse([1, 2, 3, 4, 5]),
  );

  final uniqueIntList = Flod.list(schema: Flod.int()).uniqueItems();
  printResult("Unique Int List valid", uniqueIntList.safeParse([10, 20, 30]));
  printResult(
    "Unique Int List failure (duplicate index path tracing)",
    uniqueIntList.safeParse([10, 20, 10, 30]),
  );
  printResult(
    "Unique Int List failure (wrong child item type)",
    uniqueIntList.safeParse([10, "wrong", 30]),
  );

  // =========================================================================
  // 6. СХЕМЫ ОБЪЕКТОВ И РЕЖИМЫ СТРОГОСТИ (Passthrough vs Strict)
  // =========================================================================
  print("\n=== 6. OBJECT SCHEMAS & MODES ===");

  final profileSchema = Flod.object({
    "username": Flod.string().trim().min(3, "Short username", "user_short"),
    "age": Flod.int().min(18),
    "website": Flod.string().url().optional(), // Опциональное поле в схеме
  });

  // final validProfile = {"username": "  coder_dan ", "age": 21};
  final extraKeysProfile = {
    "username": "alex",
    "age": 30,
    "session_token": "secret_abc123",
  };
  final invalidProfile = {"username": "jo", "age": 15};

  printResult(
    "Object Passthrough mode (allows unknown keys)",
    profileSchema.passthrough().safeParse(extraKeysProfile),
  );
  printResult(
    "Object Strict mode failure (blocks unknown keys)",
    profileSchema.strict().safeParse(extraKeysProfile),
  );
  printResult(
    "Object field schema violations validation",
    profileSchema.safeParse(invalidProfile),
  );

  // =========================================================================
  // 7. СУПЕР-КОМПЛЕКСНЫЙ СЦЕНАРИЙ: ГЛУБОКАЯ ВЛОЖЕННОСТЬ И ДЕРЕВО ПУТЕЙ ОШИБОК
  // =========================================================================
  print("\n=== 7. COMPLEX DEEP NESTED VALIDATION (ECOMMERCE ORDER DATA) ===");

  // Описываем сложную древовидную структуру данных
  final orderSchema = Flod.object({
    "orderId": Flod.string().uuid(),
    "customer": Flod.object({
      "email": Flod.string().email(),
      "phone": Flod.string().phoneNumber().nullable(),
    }),
    "items": Flod.list(
      schema: Flod.object({
        "productId": Flod.string().trim(),
        "quantity": Flod.int().min(1),
        "price": Flod.double().positive(),
      }),
    ).minItems(1),
  }).strict();

  final brokenOrderData = {
    "orderId": "invalid-uuid-format",
    "customer": {
      "email": "not-an-email",
      "phone": null, // Разрешено nullable
    },
    "items": [
      {
        "productId": "PROD-1",
        "quantity": 5,
        "price": 99.99,
      }, // Корректный элемент
      {
        "productId": "PROD-2",
        "quantity": 0,
        "price": -5.0,
      }, // Ошибки: quantity < 1, price не positive()
    ],
    "hacker_field": "exploit", // Вызовет ошибку из-за .strict() режима
  };

  printResult(
    "Deep nested structures complete check",
    orderSchema.safeParse(brokenOrderData),
  );

  print("\n=================================================================");
  print("                    ALL SCENARIOS EXECUTED                       ");
  print("=================================================================");
}
