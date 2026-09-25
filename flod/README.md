<p align="center">
  <img src="https://raw.githubusercontent.com/leeerrrrmmm/Flod-Library/main/flod/assets/flod_final_logo.webp" width="1200" alt="Flod Logo">
</p>

# Flod — schema validation for Dart & Flutter

**Flod** is a strict, fast, type-safe data validation and transformation engine for Dart and Flutter.
If you know **[Zod](https://zod.dev)** (TypeScript) or Zod-inspired APIs, Flod will feel immediately familiar — with the extras that matter in production: **PII-safe errors**, **JSON hardening**, **Dio middleware**, **Flutter form bridging**, and a **compiled performance layer**.

[![pub package](https://img.shields.io/badge/pub-v1.1.3-blue)](https://pub.dev)
[![tests](https://img.shields.io/badge/tests-95%2B%20passing-brightgreen)]()
[![license](https://img.shields.io/badge/license-see%20LICENSE-lightgrey)](LICENSE)

---

## Examples

Add Flod and import the core API:

```yaml
dependencies:
  flod: ^1.1.3
```

```dart
import 'package:flod/flod.dart';
```

### Validate an API payload

```dart
final checkoutSchema = Flod.object({
  'id': Flod.int().positive(),
  'email': Flod.string().trim().toLowerCase().email(),
  'role': Flod.literal('user'),
  'profile': Flod.object({
    'displayName': Flod.string().min(2).max(64).trim(),
    'age': Flod.int().min(13).max(120).optional(),
    'tags': Flod.list(schema: Flod.string().trim()).min(0).max(10).uniqueItems(),
  }),
  'items': Flod.list(
    schema: Flod.object({
      'sku': Flod.string().min(3).max(32),
      'qty': Flod.int().positive().max(999),
      'price': Flod.double().nonNegative(),
    }),
  ).min(1),
});

final result = checkoutSchema.safeParse(jsonMap);

if (result is FlodSuccess<Map<String, dynamic>>) {
  final data = result.data; // validated + transformed
} else if (result is FlodFailure<Map<String, dynamic>>) {
  print(result.toReadable());   // human-readable lines
  print(result.getFieldsMap()); // {"profile.age": "..."}
}
```

### `safeParse` vs `parse`

```dart
final userSchema = Flod.object({
  'name': Flod.string().min(2),
  'age': Flod.int().min(0),
});

// Recommended — no exceptions
final result = userSchema.safeParse({'name': 'A', 'age': -1});
if (result is FlodFailure) {
  print(result.toReadable());
}

// Fail-fast — throws ValidationException
try {
  userSchema.parse({'name': 'A', 'age': -1});
} on ValidationException catch (e) {
  for (final err in e.errors) {
    print('${err.path.toReadable()}: ${err.code}');
  }
}
```

Stop at the first error when you only need a yes/no answer:

```dart
schema.safeParse(data, abortEarly: true);
schema.parse(data, abortEarly: true);
await schema.safeParseAsync(data, abortEarly: true);

final strictFast = schema.stopOnFirstError();
strictFast.safeParse(data);
```

### Strings, numbers, and formats

```dart
Flod.string().email();
Flod.string().url();
Flod.string().uuid();
Flod.string().phoneNumber();
Flod.string().creditCard(); // Luhn
Flod.string().cvv();
Flod.string().min(8).regex(RegExp(r'[A-Z]'), code: 'needs_uppercase');
Flod.string().length(2);    // fixed length

Flod.int().min(0).max(120);
Flod.int().positive();
Flod.int().multipleOf(7);
Flod.double().nonNegative();
Flod.boolean();
Flod.literal('admin');
```

### Coerce form strings and stringly JSON

The same schema can accept typed JSON **and** `TextFormField` strings.

```dart
final formSchema = Flod.object({
  'age': Flod.coerce.int().min(18, message: 'Must be 18+'),
  'price': Flod.coerce.double().nonNegative(),
  'active': Flod.coerce.boolean(),
  'note': Flod.coerce.string().max(200),
});

formSchema.safeParse({
  'age': '22',     // → 22
  'price': '9.99', // → 9.99
  'active': 'yes', // → true
  'note': 42,      // → "42"
});
```

`Flod.int()` stays strict and still rejects `"42"`. Use `Flod.coerce.int()` when the input may be a string.

### Transform before validation

```dart
final usernameFromEmail = Flod.string().trim().toLowerCase().transform(
  (v) => v.split('@').first,
);

final result = usernameFromEmail.safeParse('  John.Doe@Example.com  ');
// result.data → "john.doe"
```

Built-ins: `.trim()`, `.toLowerCase()`, `.toUpperCase()`, `.transform(fn)`.

### Nested objects, lists, and unions

```dart
Flod.object({'a': Flod.string()}).strict();      // unknown keys → error
Flod.object({'a': Flod.string()}).passthrough(); // extra keys kept

Flod.list(schema: Flod.int()).min(1).max(100).uniqueItems();

final eventSchema = Flod.union([
  Flod.object({'kind': Flod.literal('click'), 'x': Flod.int()}),
  Flod.object({'kind': Flod.literal('view'), 'duration': Flod.int()}),
]).discriminatedBy('kind');
```

Nested failures keep a full path: `company.department.team.lead.analytics.age`.

### Recursive trees with `Flod.lazy`

```dart
late final Validator<Map<String, dynamic>> category;

category = Flod.object({
  'name': Flod.string().min(1),
  'children': Flod.list(schema: Flod.lazy(() => category)),
});

category.safeParse({
  'name': 'root',
  'children': [
    {'name': 'child', 'children': []},
  ],
});
```

### Defaults, optional, and nullable

```dart
Flod.int().nonNegative().withDefault(0);           // missing / null → 0
Flod.string().nullable();                          // key present, value may be null
Flod.int().optional();                             // key may be absent

Flod.list(schema: Flod.string()).withDefaultFactory(() => <String>[]);

Flod.object({'tags': Flod.list(schema: Flod.string())})
    .withDefaultFactory(() => {'tags': <String>[]});
```

Lists and maps passed to `withDefault` are shallow-cloned on every use, so mutating one result does not leak into the next parse.

### Cross-field rules

```dart
final signupSchema = Flod.object({
  'password': Flod.string().min(8),
  'confirmPassword': Flod.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  code: 'passwords_match',
  path: ['confirmPassword'],
  message: 'Passwords do not match',
);

Flod.string().email().refine(
  (email) => !email.endsWith('@tempmail.com'),
  message: 'Disposable emails are not allowed',
);

schema.superRefine((value, ctx) {
  if (value['age'] < 18 && value['country'] == 'US') {
    ctx.addIssue(code: 'too_young', path: ['age'], message: 'Too young for US');
  }
});
```

Async variants: `.refineAsync()` / `.superRefineAsync()` with `safeParseAsync()`.

### Inline error copy

```dart
Flod.string().min(8, message: 'Password too short');
Flod.int().min(18, message: 'Must be 18+');
Flod.list(schema: Flod.int()).min(1, message: 'Add at least one item');
Flod.string().email(message: 'Enter a valid email');
```

`message:` overrides i18n for that error only. The machine `code` is still stored for analytics.

### Compose object schemas

```dart
base.extend({'extra': Flod.string()});
base.merge(otherObjectSchema);
base.partial(deep: true);
base.pick(['id', 'email']);
base.omit(['internalDebug']);
```

### Mask secrets in errors

```dart
final loginSchema = Flod.object({
  'email': Flod.string().email(),
  'password': Flod.string().min(8).secret(),
  'pan': Flod.string().creditCard().secret(),
});

final failure = loginSchema.safeParse({
  'email': 'bad',
  'password': '123',
  'pan': '4111111111111111',
}) as FlodFailure;

// password / pan values are [HIDDEN] on FlodError.value
failure.errors.any((e) => e.isSecret && e.value == '[HIDDEN]');
```

Use `.secret()` on passwords, tokens, PAN, CVV, SSN, recovery codes. You can also wrap a whole object: `loginSchema.secret()`.

### Read field errors

```dart
final failure = schema.safeParse(badData) as FlodFailure;

failure.toReadable();
// Invalid email address format.
// Must be at least 8 characters long.

failure.getFieldsMap();
// {'email': '...', 'password': '...'}

failure.getGroupedFieldsMap(); // all messages per field
failure.getMessages();         // List<String>
```

Deep path example:

```dart
Flod.object({'user': Flod.object({'age': Flod.int().min(18)})})
    .safeParse({'user': {'age': 10}});
// Path: 'user.age'
```

### Harden JSON before the schema

```dart
import 'package:flod/guard.dart';
import 'package:flod/flod.dart';

const guard = JsonGuard(
  options: JsonGuardOptions(
    maxDepth: 32,
    maxKeys: 1000,
    maxStringLength: 100000,
    maxArrayLength: 10000,
    blockPrototypeKeys: true,
  ),
);

final result = guard.parseJson(rawHttpBody, userSchema);
if (result is FlodFailure) {
  print(result.toReadable());
}

try {
  final data = guard.parseJsonOrThrow(rawHttpBody, userSchema);
} on ValidationException catch (e) {
  print(e.errors);
}
```

### Validate Dio responses

```dart
import 'package:flod/dio.dart' as flod_dio;
import 'package:flod/flod.dart';
import 'package:flod/guard.dart';

final dio = flod_dio.Dio();

dio.interceptors.add(
  flod_dio.FlodValidateInterceptor(
    schema: postSchema,
    guard: guard,
    extractData: (r) => (r.data as Map)['data'],
  ),
);

try {
  final response = await dio.get('/posts/1');
  // response.data is already validated (+ transformed)
} on flod_dio.DioException catch (e) {
  if (e.error is ValidationException) {
    print((e.error as ValidationException).errors);
  }
}
```

`package:flod/dio.dart` re-exports Dio — you do not need a separate `dio` import.

Offline helper (no HTTP):

```dart
final result = flod_dio.FlodValidateInterceptor.validatePayload(
  raw: jsonMap,
  schema: schema,
  guard: guard,
);
```

### Drive Flutter form errors from one schema

```dart
import 'package:flod/form.dart';

final adapter = FlodFormAdapter(signupSchema);
final fieldErrors = adapter.validate(formValues);
// {'confirmPassword': 'Passwords do not match'}

TextFormField(
  validator: adapter.fieldValidator('email', () => currentFormSnapshot),
);
```

`FlodFormAdapter` is pure Dart. Pair it with `Flod.coerce.*` when fields arrive as strings.

### Compile a hot-path schema

```dart
final compiled = checkoutSchema.compile();
compiled.safeParse(payload);
```

Use the compiled validator in request handlers after the schema is stable.

### Localize errors

```dart
FlodConfig.setup(
  localeCompiler: (code, params) {
    if (code == FlodErrorCodes.stringEmail) return 'Invalid email';
    return FlodDefaultLocale.compile(code, params);
  },
);
```

---

## Table of contents

- [Examples](#examples)
- [Why Flod?](#why-flod)
- [Installation](#installation)
- [Parse API — safeParse vs parse](#parse-api--safeparse-vs-parse)
- [Schema building blocks](#schema-building-blocks)
- [Coercion — `Flod.coerce.*`](#coercion--flodcoerce)
- [Transform pipeline](#transform-pipeline)
- [Objects, lists & unions](#objects-lists--unions)
- [Recursive schemas — `Flod.lazy`](#recursive-schemas--flodlazy)
- [Defaults, nullable & optional](#defaults-nullable--optional)
- [Cross-field validation — refine & superRefine](#cross-field-validation--refine--superrefine)
- [Inline error messages — `message:`](#inline-error-messages--message)
- [Schema composition — Zod-style object helpers](#schema-composition--zod-style-object-helpers)
- [Security & privacy — `.secret()`](#security--privacy--secret)
- [Developer experience — readable errors](#developer-experience--readable-errors)
- [Integrations — Dio, forms & JsonGuard](#integrations--dio-forms--jsonguard)
- [Performance & benchmarks](#performance--benchmarks)
- [Internationalization (i18n)](#internationalization-i18n)
- [Debug mode](#debug-mode)
- [Project status](#project-status)
- [What's coming](#whats-coming)
- [Running examples & tests](#running-examples--tests)
- [License](#license)

---

## Why Flod?

Most Dart projects still validate API payloads with **manual casts**, scattered `if` checks, or code-gen models that assume the data is already correct. That works until it doesn't — and when it breaks, you get `type 'String' is not a subtype of type 'int'` in production, with **no field path**, **no i18n hook**, and sometimes **leaked passwords in logs**.

Flod fills the gap that **Zod** solved on the frontend — but natively for Dart/Flutter backends and clients, and with an integration layer built for real production concerns: network boundaries, forms, and secrets.

| Capability | Manual `as` / `Map` checks | Code-gen only (JSON → class) | **Flod** |
|---|---|---|---|
| Zod-like chained API | ❌ | ❌ | ✅ |
| `safeParse()` / `parse()` dual API (sync + async) | ❌ | ❌ | ✅ |
| Deep path errors (`user.profile.age`) | ❌ | partial | ✅ |
| Transforms before validation (trim, lowerCase) | manual | ❌ | ✅ |
| Cross-field rules (password confirm) | manual | ❌ | ✅ |
| `.secret()` — mask PII in errors & traces | ❌ | ❌ | ✅ |
| JSON attack-surface guard (depth, `__proto__`) | ❌ | ❌ | ✅ |
| Dio response-validation middleware | ❌ | ❌ | ✅ |
| Flutter form field error maps | ❌ | ❌ | ✅ |
| `Flod.coerce.*` (string → int/double/bool) | manual | ❌ | ✅ |
| `Flod.lazy()` recursive schemas | ❌ | ❌ | ✅ |
| Inline `message:` on rules (no i18n setup) | ❌ | ❌ | ✅ |
| Compiled hot path (`schema.compile()`) | ❌ | ❌ | ✅ |
| `build_runner` typed codegen | — | ✅ | 🔜 [see roadmap](#whats-coming) |

**When Flod shines**

- **API boundaries** — validate `jsonDecode` results before they touch business logic.
- **Flutter forms** — one schema drives server payloads *and* inline field errors.
- **Fintech / auth** — `.secret()` on passwords, tokens, PAN, CVV.
- **High-throughput services** — compile once, validate thousands of times per second.

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flod: ^1.1.3
```

**Entry points**

| Import | Purpose |
|---|---|
| `package:flod/flod.dart` | Core validators, `Flod.*` / `Flod.coerce` / `Flod.lazy`, `safeParse` / `parse`, **`ValidationException`**, **`FlodDefaultLocale`**, `FlodConfig`, i18n |
| `package:flod/dio.dart` | `FlodValidateInterceptor` **and** a full re-export of `package:dio/dio.dart` (`Dio`, `DioException`, …) — prefer this over importing `dio` directly (no extra `dio:` line needed in your app pubspec) |
| `package:flod/guard.dart` | `JsonGuard` / `JsonGuardOptions` — JSON security layer |
| `package:flod/form.dart` | `FlodFormAdapter` — pure Dart, Flutter-ready |

> **v1.1.0:** `Flod.coerce.*`, `Flod.lazy()`, inline `message:`, safe `withDefault` / `withDefaultFactory`. Prefer public exports over any `package:flod/src/...` import.

---

## Parse API — safeParse vs parse

| Method | On success | On failure | Use when |
|---|---|---|---|
| `safeParse(data, {abortEarly})` | `FlodSuccess<T>` | `FlodFailure<T>` | HTTP handlers, UI, anywhere you want control |
| `parse(data, {abortEarly})` | `T` | throws **`ValidationException`** | Internal trusted paths, "fail fast" |
| `safeParseAsync(data, {abortEarly})` | `Future<FlodSuccess<T>>` | `Future<FlodFailure<T>>` | Schemas with `.refineAsync()` / `.superRefineAsync()` |
| `parseAsync(data, {abortEarly})` | `Future<T>` | throws **`ValidationException`** | Async fail-fast |

`ValidationException` is exported from `package:flod/flod.dart` (no private `src/` import). Each instance exposes `e.errors` — a `List<FlodError>` with path, code, params, and value.

When `abortEarly` is `true` (or the schema used `stopOnFirstError()`), a multi-field object typically returns **one** error instead of collecting all field failures.

---

## Schema building blocks

### Primitives

```dart
Flod.string()          // trim, email, url, uuid, regex, creditCard (Luhn), cvv, phoneNumber, …
Flod.int()              // min, max, positive, negative, multipleOf, …
Flod.double()           // same numeric constraints
Flod.boolean()          // Zod-compatible: z.boolean() → Flod.boolean()
Flod.literal('admin')   // enum-like fixed values
```

### String formats (domain rules)

```dart
Flod.string().email()
Flod.string().url()
Flod.string().uuid()
Flod.string().phoneNumber()
Flod.string().creditCard()   // Luhn check
Flod.string().cvv()
Flod.string().min(8).regex(RegExp(r'[A-Z]'), code: 'needs_uppercase')
Flod.string().length(2)      // fixed length (Zod .length())
```

### Numbers

```dart
Flod.int().min(0).max(120)
Flod.int().positive()
Flod.int().multipleOf(7)
Flod.double().nonNegative()
```

> **Length units:** `string().min` / `.max` / `.length` use Dart `String.length` (**UTF-16 code units**), not grapheme clusters. A single emoji like `👨‍👩‍👧‍👦` may be longer than `10`.

---

## Coercion — `Flod.coerce.*`

Zod `z.coerce.*` for Dart. Coercion runs **before** type checks and rule chains, so the **same schema** can validate typed JSON **and** Flutter form strings.

| API | Accepts (in addition to the native type) |
|---|---|
| `Flod.coerce.int()` | numeric `String` (`"42"`), other `num`, `bool` (`true`→1 / `false`→0) |
| `Flod.coerce.double()` | numeric `String`, `int`/`num`, `bool` |
| `Flod.coerce.boolean()` | `"true"`/`"false"`/`"1"`/`"0"`/`"yes"`/`"no"`/`"on"`/`"off"` (case-insensitive), `0`/`1` |
| `Flod.coerce.string()` | any non-null value via `Object.toString()` |

**Important**

- Use `Flod.coerce.int()` when input may be a `String`. Plain `Flod.int()` still **rejects** `"42"` (strict typed API / JSON that already decoded numbers).
- Failed coercion → `invalid_type` (same as a normal type mismatch).
- Chain rules as usual: `Flod.coerce.int().min(0).max(120).positive()`.

---

## Transform pipeline

Transforms run **before** validation (Zod `.transform()` semantics).

Built-ins: `.trim()`, `.toLowerCase()`, `.toUpperCase()`, `.transform(fn)`.

---

## Objects, lists & unions

### Object modes

```dart
Flod.object({'a': Flod.string()}).strict();      // unknown keys → error (anti pollution)
Flod.object({'a': Flod.string()}).passthrough(); // default — extra keys kept in output
```

Nested objects preserve full paths: `company.department.team.lead.analytics.age`.

### Lists

```dart
Flod.list(schema: Flod.int()).min(1).max(100).uniqueItems();
```

### Union / discriminated union

```dart
final eventSchema = Flod.union([
  Flod.object({'kind': Flod.literal('click'), 'x': Flod.int()}),
  Flod.object({'kind': Flod.literal('view'), 'duration': Flod.int()}),
]).discriminatedBy('kind'); // O(1) branch selection
```

---

## Recursive schemas — `Flod.lazy`

Deferred schema construction (Zod `.lazy()`). Required for trees / mutually recursive types.

**Contract (exact)**

| Behavior | Detail |
|---|---|
| When factory runs | On first `validate` / `safeParse` (result is **cached**) |
| `compile()` | Leaves `LazyValidator` in place (does **not** expand) so recursive graphs do not stack-overflow |
| Async | `LazyValidator` implements `AsyncValidator` and forwards to an async inner when present |
| Secret | `Flod.lazy(() => schema).secret()` / parent `.secret()` still mask as usual |

Use `late final` + a closure that captures the same variable.

---

## Defaults, nullable & optional

| Modifier | Meaning |
|---|---|
| `.nullable()` | Key present, value may be `null` |
| `.optional()` | Key may be absent from the object |
| `.withDefault(value)` | When input is missing/`null` → default (Zod `.default()`) |
| `.withDefaultFactory(() => value)` | Same, but **factory runs every time** (safe for nested mutables) |

### Mutable defaults (lists / maps) — do this

`withDefault([])` / `withDefault({})` used to share one instance across parses (silent corruption if you mutate the result). **Fixed in v1.1.0:**

- `List` / `Map<String, dynamic>` passed to `withDefault` are **shallow-cloned** on every use.
- For nested mutables, prefer an explicit factory.

> Legacy aliases `defaultValue()`, `minItems`/`maxItems`, `fixedLength()` are deprecated — use `withDefault()`, `min()`/`max()`, `length()`.

---

## Cross-field validation — refine & superRefine

`.refine()` / `.superRefine()` work on **any** `Validator` — objects **and** leaf primitives (`Flod.string()`, `Flod.int()`, …).

**Async** — use `.refineAsync()` / `.superRefineAsync()` with `safeParseAsync()`.

**Chained `.refine().refine()` note:** nested refine wrappers short-circuit — if an inner refine fails, outer refine predicates do **not** run. To collect several cross-field issues in one pass, use **one** `.superRefine()` with multiple `ctx.addIssue(...)`.

---

## Inline error messages — `message:`

Production apps should keep using `code` + `FlodConfig` / locale compiler. For prototypes and one-off UI copy, pass `message:` on rules — it **overrides** the i18n resolver for that error only.

**Resolution order** (exact):

1. If `FlodError.message != null` → that string is returned by `getMessages()` / `toReadable()` / `getFieldsMap()`.
2. Else → `FlodI18nResolver` / `localeCompiler(code, params)`.

`code` is still stored on the error (analytics, logging, later i18n). Inline `message` does **not** remove the code.

---

## Schema composition — Zod-style object helpers

```dart
base.extend({'extra': Flod.string()});  // add/override keys
base.merge(otherObjectSchema);          // merge two object schemas
base.partial(deep: true);               // all fields optional, recursively
base.pick(['id', 'email']);             // keep subset
base.omit(['internalDebug']);           // remove keys
```

Reuse primitives via **SchemaPool** — `Flod.string()` returns shared singleton instances (see [Performance & benchmarks](#performance--benchmarks)).

---

## Security & privacy — `.secret()`

One of Flod's strongest differentiators vs other Dart validators and vs naive Zod usage in logging pipelines.

Mark any validator (or a whole object) as **secret** — failed values are masked as `[HIDDEN]` on the structured error object (and in debug traces), instead of leaking raw PII.

### Where `[HIDDEN]` appears

| Surface | Behavior |
|---|---|
| `FlodError.value` / `FlodError.toString()` / `toMap()` | `[HIDDEN]` when `isSecret: true` |
| `FlodDebug.trace()` | value shown as `[HIDDEN]` when the validator is secret |
| `toReadable()` / `getFieldsMap()` / `getMessages()` | **human messages only** — never embed the raw failed value (secret or not) |

So masking is checked on the error object, not by grepping `toReadable()` for the string `HIDDEN`.

### Example: public vs secret on `FlodError.value`

**Input:** `{'email': 'bad', 'password': '123'}`

**Public field** (`password` without `.secret()`):

```
FlodError(path: 'password', code: string_min, ..., value: 123)
```

**Secret field** (same rule + `.secret()`):

```
FlodError(path: 'password', code: string_min, ..., value: [HIDDEN])
```

No accidental password/token/card leaks in:

- `FlodError.value` (returns `[HIDDEN]` when secret)
- `FlodError.toString()` / `toMap()`
- `FlodDebug.trace()` when `isSecret: true`

**Use `.secret()` on:** passwords, refresh tokens, API keys, PAN, CVV, SSN, recovery codes.

---

## Developer experience — readable errors

Every error carries:

- **`path`** — `FlodPath` with `.toReadable()` → object keys dotted, list indices in brackets: `profile.tags[0]`, `items[1].qty`
- **`code`** — stable machine id (`FlodErrorCodes.*`) for i18n
- **`params`** — interpolation payload for translators

### Tree-style logging (from stress example)

```
   ❌ PUBLIC FAIL → 3 error(s)
         ↳ Path: 'profile.displayName' | Code: string_min      | Value: A
         ↳ Path: 'items[1].qty'        | Code: number_positive | Value: -1
         ↳ Path: 'email'               | Code: string_email    | Value: not-an-email
```

---

## Integrations — Dio, forms & JsonGuard

### JsonGuard — secure JSON ingestion

Structural security **before** schema validation. Blocks: prototype pollution keys, excessive depth/key budget, oversized strings/arrays, invalid JSON.

| Method | On failure |
|---|---|
| `parseJson` / `guard` | returns `FlodFailure` (does **not** throw) |
| `parseJsonOrThrow` | throws `ValidationException` |

Already-decoded JSON: `guard.guard(decoded, schema)`.

### FlodValidateInterceptor — Dio middleware

**Do not** add a separate `import 'package:dio/dio.dart'` just to use Flod's interceptor.
`package:flod/dio.dart` already re-exports Dio (`Dio`, `DioException`, …). That also avoids the
`depend_on_referenced_packages` analyzer warning that appears when an app imports `dio` directly
without declaring it in its own `pubspec.yaml`.

You only need `flod` in your `pubspec.yaml` — `dio` is pulled in transitively by Flod.
Declare `dio` yourself only if your app uses Dio outside of Flod and you want a direct dependency.

On success: replaces `response.data` with validated, typed output.
On failure (interceptor path): rejects with `DioException` whose `error` is a `ValidationException`.

### FlodFormAdapter — form bridge

Pure Dart — no Flutter dependency required at the adapter level. Built directly on top of `getFieldsMap()`, so form errors and API errors always stay in sync with the same schema.

---

## Performance & benchmarks

Flod v1.0 ships a **performance layer** designed for hot paths:

| Layer | What it does |
|---|---|
| **SchemaPool** | Shared singleton validators for `string`, `int`, `double`, `bool` |
| **Chain optimization** | Identity-aware `copyWith`, `isPure` fast path, secret hoisting |
| **ValidatorCompiler** | `schema.compile()` → `CompiledObjectValidator` / `CompiledListValidator`, identity cache |

### Methodology (internal QA, July 2026)

Benchmarks were run **outside the published package** (not shipped to pub.dev) using:

- Warm compiled schema (`buildSchema().compile()` once, then parse in a loop)
- Checkout-like schema: nested objects, `email()`, `trim()`, `uniqueItems()`, defaults
- Payloads ~1 KB / ~100 KB / ~1 MB (scaled via `items[]`)
- Percentile harness: 2 000 warmup + 20 000 timed iterations
- Comparison vs a **manual cast baseline** (same field access, no validation)

Environment: Dart JIT release-mode script (not IDE debugger). For absolute numbers, run your own profile with `dart run --define=dart.vm.product=true` on target hardware.

### Results summary (representative run, post Map-copy optimization)

| Scenario | Flod WARM median | Notes |
|---|---|---|
| **1 KB payload** | **~6 µs** | Full validation + transforms + paths |
| Manual baseline 1 KB | ~1 µs | Casts only — shows "feature tax" |
| **Overhead ratio** | **~6×** | Regex, trim, uniqueItems, path tracking |
| **100 KB payload** | **~465 µs** | Dominated by list item validation |
| **1 MB payload** | **~7.5 ms** | Linear with item count |

**CPU profile insight (DevTools, 20k × 1 KB):**

- Dominant cost was **`LinkedHashMap` operations** from defensive `Map.from()` per object level — fixed in v1.0 by read-only source access on the compiled path.
- `FlodPath.append` was **~1%** self-time — not the bottleneck.
- GC pauses were **not** correlated with 1 KB outlier spikes (likely scheduler / JIT tiering).

**Cold compile:** first `schema.compile()` ≈ **25 µs** (one-time startup cost).

**Compiled vs raw parity:** 100+ iteration stress tests confirm identical semantics between compiled and non-compiled validators.

```dart
final hot = productionSchema.compile();
hot.safeParse(apiPayload); // use this in request handlers
```

---

## Internationalization (i18n)

Errors are **code + params** — text lives in a resolver, not hard-coded in validators.

`FlodDefaultLocale` (built-in English compiler) and `FlodErrorCodes` are exported from `package:flod/flod.dart` (v1.0.3+ — no private `src/` import).

Built-in English: `FlodDefaultLocale.compile`. Custom factory: `Flod.i18n(yourCompiler)`.

---

## Debug mode

```dart
FlodConfig.setup(
  debug: true,
  onTrace: (msg) => log.info(msg), // optional custom sink
);
```

Trace format:

```
[Flod] [ok] StringValidator @ profile.displayName → Pro User
[Flod] [fail] IntValidator @ user.age → [HIDDEN] (1 error(s))  // when .secret()
```

---

## Project status

Flod **v1.1** adds the form/API “first week” gaps (coerce, lazy, inline messages, safe defaults) on top of the v1.0 engine:

- ✅ Core parsing (`safeParse` / `parse`, sync & async, optional `abortEarly`)
- ✅ Public `ValidationException` + `FlodDefaultLocale` on the main export
- ✅ Full primitive + string-format validator suite (`email`, `url`, `uuid`, `phone`, `credit card/Luhn`, `CVV`, `regex`)
- ✅ **`Flod.coerce.int/double/boolean/string`** — stringly form/JSON → typed values
- ✅ **`Flod.lazy(() => schema)`** — recursive / mutually recursive schemas
- ✅ **Inline `message:`** on rules + refine (bypasses i18n when set)
- ✅ **`withDefault` / `withDefaultFactory`** — mutable defaults no longer shared across parses
- ✅ Transform pipeline, `nullable`/`optional`
- ✅ Objects (`strict`/`passthrough`), nested paths (`items[1].qty`), lists, unions & discriminated unions
- ✅ Cross-field **and leaf** validation (`refine`, `superRefine`, async variants)
- ✅ Schema composition (`extend`, `merge`, `partial`, `pick`, `omit`)
- ✅ `.secret()` PII masking across errors and debug traces
- ✅ `i18n resolver` + `debug tracing`
- ✅ Performance layer — `SchemaPool`, `ChainOptimization`, `ValidatorCompiler`
- ✅ Integrations — `JsonGuard`, `FlodValidateInterceptor` (Dio re-export), `FlodFormAdapter`

The only major item intentionally deferred is **typed static codegen** (`build_runner`) — see below.

---

## What's coming

New APIs stay additive (`Flod.coerce.*`, `Flod.lazy`, `message:`) — existing call sites keep compiling.

### Confirmed roadmap

1. **Static codegen** — opt-in `build_runner` packages (`flod_generator`, `flod_build`): annotate a class with `@FlodSchema()`, get a typed `Validator<T>`, parse helpers, and refactor-safe field paths. Runtime-only Flod remains fully supported and will not be deprecated.
2. **Network** — `.isIp(version: IpVersion)` (IPv4 / IPv6), `.isHostname()` (RFC domain names), `.isPort()` (0–65535).
3. **Media & encoding** — `.isBase64()` (optional strict padding), `.isMimeType()` (`type/subtype`, e.g. `application/json`).
4. **Advanced formats** — `.isIso8601()` (date, time, duration), `.isJsonString()` (valid JSON object/array in a string), `.isHexColor()` (`#RRGGBB` / `#RRGGBBAA`).
5. **Content & business rules** — `.isSlug()` (URL-safe slugs), `.isCurrencyCode()` (ISO 4217), `.isLanguageCode()` (ISO 639-1).

### Proposed additions (under evaluation)

- **`.toJsonSchema()` / `.toOpenApiSchema()`** — export any Flod schema as JSON Schema / OpenAPI.
- **`Flod.record` / `Flod.enum_` / `.catch()` / `.describe()`** — open maps, Dart enum sugar, soft fallbacks, schema metadata.
- **`schema.generateSample()`** — fixture data from a schema.
- **Isolate-aware `compile(parallel: true)`** — niche 1 MB+ Flutter UI-thread offload.
- **`CompiledListValidator` completion** — internal compiler consistency for lists.

Track progress in [CHANGELOG](CHANGELOG.md).

---

## Running examples & tests

```bash
cd flod
dart pub get
dart test                            # 95+ tests — core, integrations, performance, v1.1 features
dart run example/flod_example.dart   # quick start & privacy demos
```

---

## License

See [LICENSE](LICENSE).
