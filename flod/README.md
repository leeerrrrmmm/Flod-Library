<p align="center">
  <img src="https://raw.githubusercontent.com/leeerrrrmmm/Flod-Library/main/flod/assets/flod_final_logo.webp" width="900" alt="Flod Logo">
</p>

# Flod — schema validation for Dart & Flutter

**Flod** is a strict, fast, type-safe data validation and transformation engine for Dart and Flutter.
If you know **[Zod](https://zod.dev)** (TypeScript) or Zod-inspired APIs, Flod will feel immediately familiar — with the extras that matter in production: **PII-safe errors**, **JSON hardening**, **Dio middleware**, **Flutter form bridging**, and a **compiled performance layer**.

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue)](https://pub.dev)
[![tests](https://img.shields.io/badge/tests-78%2B%20passing-brightgreen)]()
[![license](https://img.shields.io/badge/license-see%20LICENSE-lightgrey)](LICENSE)

---

## Table of contents

- [Why Flod?](#why-flod)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Parse API — safeParse vs parse](#parse-api--safeparse-vs-parse)
- [Schema building blocks](#schema-building-blocks)
- [Transform pipeline](#transform-pipeline)
- [Objects, lists & unions](#objects-lists--unions)
- [Defaults, nullable & optional](#defaults-nullable--optional)
- [Cross-field validation — refine & superRefine](#cross-field-validation--refine--superrefine)
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
  flod: ^1.0.0
```

**Entry points**

| Import | Purpose |
|---|---|
| `package:flod/flod.dart` | Core validators, `Flod.*` factories, `safeParse`, i18n |
| `package:flod/dio.dart` | `FlodValidateInterceptor` — Dio middleware |
| `package:flod/guard.dart` | `JsonGuard` — JSON security layer |
| `package:flod/form.dart` | `FlodFormAdapter` — pure Dart, Flutter-ready |

---

## Quick start

```dart
import 'package:flod/flod.dart';

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

// Recommended — no exceptions
final result = checkoutSchema.safeParse(jsonMap);

if (result is FlodSuccess<Map<String, dynamic>>) {
  final data = result.data; // validated + transformed
} else if (result is FlodFailure<Map<String, dynamic>>) {
  print(result.toReadable());   // human-readable lines
  print(result.getFieldsMap()); // {"profile.age": "..."}
}
```

**Compile for production hot paths** (recommended once a schema is stable):

```dart
final compiled = checkoutSchema.compile(); // ValidatorCompiler + CompiledObjectValidator
compiled.safeParse(payload);
```

---

## Parse API — safeParse vs parse

| Method | On success | On failure | Use when |
|---|---|---|---|
| `safeParse(data)` | `FlodSuccess<T>` | `FlodFailure<T>` | HTTP handlers, UI, anywhere you want control |
| `parse(data)` | `T` | throws `ValidationException` | Internal trusted paths, "fail fast" |
| `safeParseAsync(data)` | `Future<FlodSuccess<T>>` | `Future<FlodFailure<T>>` | Schemas with `.refineAsync()` / `.superRefineAsync()` |
| `parseAsync(data)` | `Future<T>` | throws | Async fail-fast |

```dart
try {
  final user = userSchema.parse(untrustedJson);
} on ValidationException catch (e) {
  // e.errors — full FlodError list with paths & codes
}
```

**Abort early** — stop at the first error (faster invalid paths):

```dart
final strictFast = schema.stopOnFirstError();
// or per-call:
schema.safeParse(data, abortEarly: true);
```

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

---

## Transform pipeline

Transforms run **before** validation (Zod `.transform()` semantics).

```dart
Flod.string()
  .trim()
  .toLowerCase()
  .transform((v) => v.split('@').first) // custom pipeline
```

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

## Defaults, nullable & optional

| Modifier | Meaning |
|---|---|
| `.nullable()` | Key present, value may be `null` |
| `.optional()` | Key may be absent from the object |
| `.withDefault(value)` | Zod `.default()` — Dart keyword-safe name |

```dart
Flod.int().nonNegative().withDefault(0)  // missing key → 0
```

> Legacy aliases `defaultValue()`, `minItems`/`maxItems`, `fixedLength()` are deprecated — use `withDefault()`, `min()`/`max()`, `length()`.

---

## Cross-field validation — refine & superRefine

**Simple predicate** (Zod `.refine()`):

```dart
final signupSchema = Flod.object({
  'password': Flod.string().min(8),
  'confirmPassword': Flod.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  code: 'passwords_match',
  path: ['confirmPassword'], // error attaches here
);
```

**Multiple targeted issues** (Zod `.superRefine()`):

```dart
schema.superRefine((value, ctx) {
  if (value['age'] < 18 && value['country'] == 'US') {
    ctx.addIssue(code: 'too_young', path: ['age']);
  }
});
```

**Async** — use `.refineAsync()` / `.superRefineAsync()` with `safeParseAsync()`.

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

Mark any validator (or a whole object) as **secret** — failed values and debug traces show `[HIDDEN]` instead of raw PII:

```dart
final loginSchema = Flod.object({
  'email': Flod.string().email(),
  'password': Flod.string().min(8).secret(),
  'pan': Flod.string().creditCard().secret(),
});

// Or wrap the entire object:
final secureSchema = loginSchema.secret();
```

### Example: public vs secret error output

**Input:** `{'email': 'bad', 'password': '123'}`

**Public validator** (values visible — OK for non-sensitive fields):

```
❌ PUBLIC FAIL → 2 error(s)
   ↳ Path: 'email'       | Code: string_email | Value: bad
   ↳ Path: 'password'    | Code: string_min   | Value: 123
```

**Secret validator** (same schema + `.secret()` on password):

```
🔒 SECRET FAIL → 2 error(s)
   ↳ Path: 'email'       | Code: string_email | Value: bad
   ↳ Path: 'password'    | Code: string_min   | Masked Value: [HIDDEN]
```

No accidental password/token/card leaks in:

- `FlodError.value`
- `ValidationException` messages
- `FlodDebug.trace()` when `isSecret: true`

**Use `.secret()` on:** passwords, refresh tokens, API keys, PAN, CVV, SSN, recovery codes.

---

## Developer experience — readable errors

Every error carries:

- **`path`** — `FlodPath` with `.toReadable()` → `profile.tags.0`
- **`code`** — stable machine id (`FlodErrorCodes.*`) for i18n
- **`params`** — interpolation payload for translators

### Pretty output

```dart
final failure = schema.safeParse(badData) as FlodFailure;

failure.toReadable();
// Invalid email address format.
// Must be at least 8 characters long.

failure.getFieldsMap();
// {
//   'email': 'Invalid email address format.',
//   'password': 'Must be at least 8 characters long.',
// }

failure.getGroupedFieldsMap(); // all messages per field (multi-error UI)
failure.getMessages();         // List<String> via FlodConfig.errorResolver
```

### Deep nested path example

```dart
Flod.object({'user': Flod.object({'age': Flod.int().min(18)})})
    .safeParse({'user': {'age': 10}});

// Path: 'user.age'
// Message: Value must be greater than or equal to 18.
```

### Tree-style logging (from stress example)

```
   ❌ PUBLIC FAIL → 3 error(s)
         ↳ Path: 'profile.displayName' | Code: string_min | Value: A
         ↳ Path: 'items.1.qty'         | Code: number_positive | Value: -1
         ↳ Path: 'email'               | Code: string_email | Value: not-an-email
```

Wire into Flutter:

```dart
final adapter = FlodFormAdapter(signupSchema);
final fieldErrors = adapter.validate(formValues);
// {'confirmPassword': 'Custom refine check failed.'}

TextFormField(
  validator: adapter.fieldValidator('email', () => currentFormSnapshot),
);
```

---

## Integrations — Dio, forms & JsonGuard

### JsonGuard — secure JSON ingestion

Structural security **before** schema validation:

```dart
import 'package:flod/guard.dart';

const guard = JsonGuard(
  options: JsonGuardOptions(
    maxDepth: 32,
    maxKeys: 1000,
    maxStringLength: 100000,
    maxArrayLength: 10000,
    blockPrototypeKeys: true, // blocks __proto__, constructor, prototype
  ),
);

final result = guard.parseJson(rawHttpBody, userSchema);
// or: guard.guard(decoded, schema)
```

Blocks: prototype pollution keys, excessive depth/key budget, oversized strings/arrays, invalid JSON.

### FlodValidateInterceptor — Dio middleware

```dart
import 'package:flod/dio.dart';

dio.interceptors.add(FlodValidateInterceptor(
  schema: postSchema,
  guard: guard, // optional — security first, then schema
  extractData: (r) => (r.data as Map)['data'], // unwrap `{ data: ... }` envelopes
));
```

On success: replaces `response.data` with validated, typed output.
On failure: `DioException` with `ValidationException` inside.

Standalone helper (no Dio instance needed):

```dart
FlodValidateInterceptor.validatePayload(
  raw: jsonMap,
  schema: schema,
  guard: guard,
);
```

### FlodFormAdapter — form bridge

Pure Dart — no Flutter dependency required at the adapter level. See [Developer experience](#developer-experience--readable-errors) for a usage example. Built directly on top of `getFieldsMap()`, so form errors and API errors always stay in sync with the same schema.

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

```dart
FlodConfig.setup(
  localeCompiler: (code, params) {
    if (code == FlodErrorCodes.stringEmail) return 'Invalid email';
    return FlodDefaultLocale.compile(code, params);
  },
);
```

Built-in English: `FlodDefaultLocale`. Custom: `Flod.i18n(yourCompiler)`.

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

Flod v1.0 is feature-complete against its original design goals. All core engine, DX, security, performance, and integration layers described in this document are implemented and covered by the test suite:

- ✅ Core parsing (`safeParse` / `parse`, sync & async)
- ✅ Full primitive + string-format validator suite (`email`, `url`, `uuid`, `phone`, `credit card/Luhn`, `CVV`, `regex`)
- ✅ Transform pipeline, `nullable`/`optional`/`default handling`
- ✅ Objects (`strict`/`passthrough`), nested paths, lists, unions & discriminated unions
- ✅ Cross-field validation (`refine`, `superRefine`, `async variants`)
- ✅ Schema composition (`extend`, `merge`, `partial`, `pick`, `omit`)
- ✅ `.secret()` PII masking across errors and debug traces
- ✅ `i18n resolver` + `debug tracing`
- ✅ Performance layer — `SchemaPool`, `ChainOptimization`, `ValidatorCompiler`
- ✅ Integrations — `JsonGuard`, `FlodValidateInterceptor` (Dio), `FlodFormAdapter`

The only major item intentionally deferred is **typed static codegen** (`build_runner`) — see below.

---

## What's coming

The chain API stays exactly as it is today (`Flod.string().isIp().secret()`) — new capability is additive, with i18n codes and `compile()` support from day one.

### Confirmed roadmap

1. **Static codegen** — opt-in `build_runner` packages (`flod_generator`, `flod_build`): annotate a class with `@FlodSchema()`, get a typed `Validator<T>`, parse helpers, and refactor-safe field paths. Runtime-only Flod remains fully supported and will not be deprecated.
2. **Network** — `.isIp(version: IpVersion)` (IPv4 / IPv6), `.isHostname()` (RFC domain names), `.isPort()` (0–65535).
3. **Media & encoding** — `.isBase64()` (optional strict padding), `.isMimeType()` (`type/subtype`, e.g. `application/json`).
4. **Advanced formats** — `.isIso8601()` (date, time, duration), `.isJsonString()` (valid JSON object/array in a string), `.isHexColor()` (`#RRGGBB` / `#RRGGBBAA`).
5. **Content & business rules** — `.isSlug()` (URL-safe slugs), `.isCurrencyCode()` (ISO 4217), `.isLanguageCode()` (ISO 639-1).

### Proposed additions (under evaluation)

These aren't committed yet, but each targets a gap that's specific to what makes Flod different from plain Zod-porting — the API/Dio/Flutter surface — rather than duplicating format validators already on the confirmed list.

- **`.toJsonSchema()` / `.toOpenApiSchema()`** — export any Flod schema as JSON Schema / OpenAPI. Since Flod already sits at the Dio boundary, this closes the loop: the same schema that validates a response can generate the API contract documentation, instead of maintaining both by hand.
- **`.lazy(() => schema)`** — deferred schema resolution for recursive structures (comment trees, nested category trees, org charts). This is a known Zod pattern that has no equivalent yet in Flod's object/union model.
- **`schema.generateSample()`** — produce realistic fixture/mock data straight from a schema (respecting `min`/`max`/`email`/`uuid`/etc.), for unit tests and Flutter widget previews without hand-writing fixtures that drift from the real schema.
- **Isolate-aware `compile(parallel: true)`** — for the 1 MB+ payload case already covered in the benchmarks, offload compiled list validation to a Dart isolate so large API responses don't block the UI thread in Flutter.
- **`CompiledListValidator` completion** — the compiler currently returns an optimized `ListValidator` rather than a dedicated `CompiledListValidator`; closing this gap would make the compiled path fully consistent between objects and lists.

Track progress in [CHANGELOG](CHANGELOG.md).

---

## Running examples & tests

```bash
cd flod
dart pub get
dart test                            # 78+ tests — core, integrations, performance layer
dart run example/flod_example.dart   # full stress & privacy matrix
```

---

## License

See [LICENSE](LICENSE).