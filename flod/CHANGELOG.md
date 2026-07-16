## 1.0.3

Public-API hardening release. Fixes analyzer errors that appeared when consuming Flod from other apps (e.g. `on ValidationException`, `abortEarly: true`, `Dio` / `DioException`, `FlodDefaultLocale`) while following the documented README examples.

### Fixed — public exports (`package:flod/flod.dart`)

- **`ValidationException`** is now exported from the main library barrel.
  - Previously the class lived only under `lib/src/validators/exception_validator/validator_exception.dart` and was used internally by `parse` / `parseAsync` / `JsonGuard.parseJsonOrThrow` / Dio interceptor.
  - Consumers could not write `on ValidationException catch (e)` after `import 'package:flod/flod.dart'` — the analyzer reported `non_type_in_catch_clause` / `undefined_class`.
  - Examples and tests that imported the private `src/` path no longer need that workaround; they use the public export.
- **`FlodDefaultLocale`** is now exported from the main library barrel.
  - Previously only reachable via `lib/src/i18n/default_locale.dart`.
  - Documented i18n setup (`return FlodDefaultLocale.compile(code, params)`) now type-checks for downstream packages without private imports.

### Fixed — `abortEarly` on the Parse API

- `ValidatorExtensions.safeParse`, `parse`, `safeParseAsync`, and `parseAsync` now accept an optional named parameter `{bool? abortEarly}`.
- The flag is forwarded into `Validator.validate` / `AsyncValidator.validateAsync`, matching:
  - schema-level `stopOnFirstError()` / object `abortEarly`, and
  - the README example `schema.safeParse(data, abortEarly: true)`.
- Before this release, calling `safeParse(..., abortEarly: true)` failed with `undefined_named_parameter` even though low-level `validate(..., abortEarly: …)` already supported it.
- Added a regression test: per-call `abortEarly: true` returns a single error on multi-field object failure (same behavior as `stopOnFirstError()`).

### Fixed — Dio integration entry point (`package:flod/dio.dart`)

- Re-exports the entire `package:dio/dio.dart` surface alongside `FlodValidateInterceptor`.
- A single `import 'package:flod/dio.dart'` now resolves `Dio`, `DioException`, `Interceptor`, `Response`, etc., so handler code can catch validation failures without a separate Dio import:
  ```dart
  } on DioException catch (e) {
    if (e.error is ValidationException) { /* ... */ }
  }
  ```
- Before this release, importing only `package:flod/dio.dart` left `Dio` / `DioException` undefined (`undefined_function` / `undefined_class` / `non_type_in_catch_clause`).

### Changed — docs & examples

- README entry-points table documents the new exports and Dio re-export.
- Parse / JsonGuard / Dio / i18n sections clarify public types and `parseJson` vs `parseJsonOrThrow`.
- Package examples (`example/flod_example.dart`, `example/high_ex.dart`) and tests no longer import private `src/` paths for `ValidationException`.

### Migration (from ≤ 1.0.2)

| Before (broken / private) | After (1.0.3) |
|---|---|
| `import '.../src/.../validator_exception.dart'` | `import 'package:flod/flod.dart'` — use `ValidationException` |
| `import '.../src/.../default_locale.dart'` | `import 'package:flod/flod.dart'` — use `FlodDefaultLocale` |
| `schema.stopOnFirstError()` only for abort | also `safeParse(data, abortEarly: true)` / `parse(..., abortEarly: true)` |
| `import 'package:dio/dio.dart'` + `package:flod/dio.dart` | `import 'package:flod/dio.dart'` alone is enough |

No breaking changes to existing method signatures beyond **adding** optional named parameters (`abortEarly`). Existing call sites continue to compile.

---

## 1.0.2

### Fixed
- Relaxed `meta` constraint from `^1.18.3` to `^1.12.0` so `flutter pub add flod` works with Flutter's SDK-pinned `meta` (e.g. `1.18.0`) without `dependency_overrides`.

## 1.0.1

### Fixed
- Escaped angle brackets in doc comment (`lib/flod.dart`) that were being interpreted as HTML, causing a static analysis info-level warning on pub.dev.
