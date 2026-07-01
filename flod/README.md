# Flod Data Engine

Строгий, быстрый и типобезопасный движок валидации и трансформации данных для Dart и Flutter. Создан для сложных структур, защиты от утечек (PII) и бесшовной интеграции с UI и сетевым слоем.

## 🚀 Почему Flod?
* [cite_start]**Type-Safe & Fail-Safe:** Разделение на `parse()` (выбрасывает исключения) [cite: 111, 112] [cite_start]и `safeParse()` (возвращает `Result`)[cite: 93, 97].
* [cite_start]**Security First:** Встроенный декоратор `.secret()` маскирует чувствительные данные (`[HIDDEN]`) в логах и трейсах[cite: 101, 104].
* [cite_start]**Performance:** Пул схем (`SchemaPool`) и JIT-компиляция (`ValidatorCompiler`) для нулевого оверхеда при повторных валидациях[cite: 13, 14, 239].
* [cite_start]**Ecosystem Ready:** Готовые интеграции для `Dio` [cite: 204][cite_start], `Flutter Forms` [cite: 175] [cite_start]и защита от вредоносного JSON (`JsonGuard`)[cite: 183, 184].

---

## 📦 Быстрый старт

Создайте схему, описывающую вашу структуру данных:

```dart
final userSchema = Flod.object({
  'id': Flod.int().positive(),
  'email': Flod.string().trim().toLowerCase().email(),
  'role': Flod.literal('user'),
  'profile': Flod.object({
    'displayName': Flod.string().min(2).max(64).trim(),
    'age': Flod.int().min(13).max(120).optional(),
    'tags': Flod.list(
      schema: Flod.string().trim(),
    ).min(0).max(10).uniqueItems(),
  }),
}); [cite_start]// Схема из тестов [cite: 9]
Валидация данных
Безопасный парсинг (Рекомендуется):

Dart
final result = userSchema.safeParse(jsonData);

if (result is FlodSuccess) {
  print("Успех: ${result.data}"); // Типизированные и трансформированные данные [cite: 94]
} else if (result is FlodFailure) {
  // Доступ к древовидной структуре ошибок
  print(result.toReadable()); [cite: 275, 276]
}
🛠 Ключевые возможности (Core API)
1. Примитивы и строки
Доступен богатый набор встроенных проверок:


Flod.string().email()   
RTF


Flod.string().uuid()   
RTF


Flod.string().url()   
RTF


Flod.string().creditCard() и .cvv()   
RTF


Flod.int().positive(), .negative(), .multipleOf(7)   
RTF
і ще 1

2. Модификаторы полей

.optional() — ключ может отсутствовать в JSON.  
RTF


.nullable() — значение ключа может быть null.  
RTF


.defaultValue(value) — подстановка значения при отсутствии.  
RTF

3. Трансформации (Transform Pipeline)
Данные можно менять прямо "на лету" до валидации:

Dart
Flod.string()
  .trim()
  .toLowerCase()
  .transform((v) => v.length) // String -> int [cite: 133]
  .transform((len) => len * 2) // int -> int [cite: 134]
4. Продвинутые объекты

.strict() — запрещает любые ключи, не описанные в схеме (защита от Prototype Pollution).  
RTF


.passthrough() — пропускает неизвестные ключи без их удаления.  
RTF


Flod.union([...]).discriminatedBy('kind') — полиморфные объекты с распознаванием типа за О(1).  
RTF

5. Кросс-полевая валидация (Refine)
Сложные проверки, зависящие от нескольких полей:

Dart
final passwordSchema = Flod.object({
  'password': Flod.string().min(8),
  'confirmPassword': Flod.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  code: 'passwords_match',
  path: ['confirmPassword'], // Ошибка привяжется к конкретному полю [cite: 174]
);
🔒 Безопасность и Приватность (Privacy Layer)
В Flod встроена защита от утечек данных. Используйте модификатор .secret() для паролей, токенов, PAN карт и CVV:

Dart
Flod.string().creditCard().secret() [cite: 168]
При падении валидации (например, при логировании ошибок), оригинальное значение будет заменено на [HIDDEN], предотвращая утечку PII (Personally Identifiable Information).  
RTF
і ще 1

🔌 Интеграции (Ecosystem)
Flod — это не только валидатор, но и связующее звено инфраструктуры.

FlodFormAdapter (Flutter)
Связывает иерархию ошибок вашей схемы напрямую с UI-формами:

Dart
final formAdapter = FlodFormAdapter(signupSchema);
final errors = formAdapter.validate(invalidForm); [cite: 175, 176]
JsonGuard (Слой сетевой безопасности)
Защита от переполнения памяти и зловредных инъекций:

Dart
final tightGuard = JsonGuard(
  options: JsonGuardOptions(maxDepth: 3, maxKeys: 5, maxStringLength: 20),
); [cite: 184]
// Блокирует __proto__, гигантские массивы и чрезмерную вложенность [cite: 189, 191]
FlodValidateInterceptor (Dio)
Автоматическая валидация ответов сервера:

Dart
dio.interceptors.add(FlodValidateInterceptor(
  schema: postSchema,
  guard: tightGuard, // Опциональная проверка безопасности перед парсингом [cite: 204]
));

Эта структура покрывает все основные фичи, которые ты тестируешь в предоставленном скрипте. Если есть еще файлы или спецификации, которые нужно добавить (например, детальное описание `ValidatorCompiler`), загружай их.