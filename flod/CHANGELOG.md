## 1.0.0

Initial stable release.

### Added

**Core parsing**
- `safeParse()` / `parse()` — sync validation with dual API (result object vs exceptions)
- `safeParseAsync()` / `parseAsync()` — async variants for `.refineAsync()` / `.superRefineAsync()`
- `stopOnFirstError()` and `abortEarly` option for fast-fail validation

**Validators**
- Primitives: `Flod.string()`, `Flod.int()`, `Flod.double()`, `Flod.boolean()`, `Flod.literal()`
- String formats: `.email()`, `.url()`, `.uuid()`, `.phoneNumber()`, `.creditCard()` (Luhn), `.cvv()`, `.regex()`, `.length()`
- Numeric constraints: `.min()`, `.max()`, `.positive()`, `.negative()`, `.multipleOf()`, `.nonNegative()`

**Transform pipeline**
- `.trim()`, `.toLowerCase()`, `.toUpperCase()`, `.transform()` — run before validation

**Objects, lists & unions**
- `.strict()` / `.passthrough()` object modes
- Deep nested field paths (`user.profile.age`)
- `Flod.list()` with `.min()`, `.max()`, `.uniqueItems()`
- `Flod.union()` with `.discriminatedBy()` for O(1) branch selection

**Modifiers**
- `.nullable()`, `.optional()`, `.withDefault()`

**Cross-field validation**
- `.refine()` — single predicate rules (e.g. password confirmation)
- `.superRefine()` — multiple targeted issues with custom paths
- Async variants: `.refineAsync()`, `.superRefineAsync()`

**Schema composition**
- `.extend()`, `.merge()`, `.partial()`, `.pick()`, `.omit()`
- `SchemaPool` — shared singleton primitives for memory efficiency

**Security & privacy**
- `.secret()` — masks PII (`[HIDDEN]`) in errors, exceptions, and debug traces
- `JsonGuard` — structural JSON hardening (depth limits, key limits, `__proto__` blocking, size limits)

**Developer experience**
- Readable errors: `.toReadable()`, `.getFieldsMap()`, `.getGroupedFieldsMap()`, `.getMessages()`
- i18n support via `FlodConfig.setup()` and custom locale compilers
- Debug mode with configurable trace sink (`onTrace`)

**Integrations**
- `FlodValidateInterceptor` — Dio middleware for request/response validation
- `FlodFormAdapter` — Flutter form field error mapping, synced with API validation

**Performance**
- `schema.compile()` — `ValidatorCompiler` producing `CompiledObjectValidator` / `CompiledListValidator`
- Chain optimization: identity-aware `copyWith`, `isPure` fast path, secret hoisting
- Benchmarked: ~6µs warm median for 1KB payloads, ~7.5ms for 1MB payloads (see README for methodology)

### Tests
- 78+ tests covering core engine, integrations, and performance layer