// ignore_for_file: avoid_print
//
// flod_example.dart
//
// Quick-start / stress & privacy matrix example for the Flod package.
// Run with:
//   dart run example/flod_example.dart
//
import 'package:flod/flod.dart';
import 'package:flod/guard.dart';

void main() {
  print('=== Flod quick start (v1.1.0) ===\n');

  basicQuickStart();
  parseVsSafeParse();
  transformPipeline();
  coerceFormDemo();
  recursiveLazyDemo();
  inlineMessageDemo();
  defaultsDemo();
  crossFieldValidation();
  secretFieldsDemo();
  jsonGuardDemo();
  compiledSchemaDemo();
}

/// -------------------------------------------------------------
/// 1. Basic schema + safeParse (from README "Quick start")
/// -------------------------------------------------------------
void basicQuickStart() {
  print('--- 1. Basic quick start ---');

  final checkoutSchema = Flod.object({
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
    'items': Flod.list(
      schema: Flod.object({
        'sku': Flod.string().min(3).max(32),
        'qty': Flod.int().positive().max(999),
        'price': Flod.double().nonNegative(),
      }),
    ).min(1),
  });

  final validPayload = {
    'id': 42,
    'email': '  User@Example.com  ',
    'role': 'user',
    'profile': {
      'displayName': 'Pro User',
      'age': 29,
      'tags': ['vip', 'beta'],
    },
    'items': [
      {'sku': 'SKU-001', 'qty': 2, 'price': 19.99},
    ],
  };

  final result = checkoutSchema.safeParse(validPayload);

  if (result is FlodSuccess<Map<String, dynamic>>) {
    print('✅ Valid payload parsed:');
    print(result.data);
  } else if (result is FlodFailure<Map<String, dynamic>>) {
    print(result.toReadable());
    print(result.getFieldsMap());
  }

  print('');
}

/// -------------------------------------------------------------
/// 2. parse() (throws) vs safeParse() (no exceptions)
/// -------------------------------------------------------------
void parseVsSafeParse() {
  print('--- 2. parse() vs safeParse() ---');

  final userSchema = Flod.object({
    'name': Flod.string().min(2),
    'age': Flod.int().min(0),
  });

  // safeParse — recommended for HTTP handlers / UI code.
  final safeResult = userSchema.safeParse({'name': 'A', 'age': -1});
  if (safeResult is FlodFailure) {
    print('safeParse caught ${safeResult.toReadable()}, no throw.');
  }

  // parse — fail-fast, throws ValidationException.
  try {
    userSchema.parse({'name': 'A', 'age': -1});
  } on ValidationException catch (e) {
    print(
      'parse() threw ValidationException with ${e.errors.length} error(s).',
    );
  }

  print('');
}

/// -------------------------------------------------------------
/// 3. Transform pipeline (trim / lowerCase / custom transform)
/// -------------------------------------------------------------
void transformPipeline() {
  print('--- 3. Transform pipeline ---');

  final usernameFromEmail = Flod.string().trim().toLowerCase().transform(
    (v) => v.split('@').first,
  );

  final result = usernameFromEmail.safeParse('  John.Doe@Example.com  ');
  if (result is FlodSuccess<String>) {
    print('Transformed value: "${result.data}"'); // -> "john.doe"
  }

  print('');
}

/// -------------------------------------------------------------
/// 4. Coercion — Flod.coerce.* (Flutter forms / stringly JSON)
/// -------------------------------------------------------------
void coerceFormDemo() {
  print('--- 4. Coercion (Flod.coerce.*) ---');

  final formSchema = Flod.object({
    'age': Flod.coerce.int().min(18, message: 'Must be 18+'),
    'price': Flod.coerce.double().nonNegative(),
    'active': Flod.coerce.boolean(),
    'note': Flod.coerce.string().max(200),
  });

  final ok = formSchema.safeParse({
    'age': '22',
    'price': '9.99',
    'active': 'yes',
    'note': 42,
  });

  if (ok is FlodSuccess<Map<String, dynamic>>) {
    print('Coerced form payload: ${ok.data}');
  }

  final bad = formSchema.safeParse({
    'age': '12',
    'price': '-1',
    'active': 'maybe',
    'note': 'ok',
  });

  if (bad is FlodFailure<Map<String, dynamic>>) {
    print('Coercion / rule failures:');
    print(bad.getFieldsMap());
  }

  // Plain Flod.int() stays strict — strings are rejected.
  final strict = Flod.int().safeParse('42');
  print(
    'Strict Flod.int() on "42": '
    '${strict is FlodFailure ? 'rejected (expected)' : 'unexpected success'}',
  );

  print('');
}

/// -------------------------------------------------------------
/// 5. Recursive schemas — Flod.lazy()
/// -------------------------------------------------------------
void recursiveLazyDemo() {
  print('--- 5. Recursive schemas (Flod.lazy) ---');

  late final Validator<Map<String, dynamic>> category;
  category = Flod.object({
    'name': Flod.string().min(1),
    'children': Flod.list(schema: Flod.lazy(() => category)),
  });

  final tree = category.safeParse({
    'name': 'root',
    'children': [
      {
        'name': 'child',
        'children': [
          {'name': 'leaf', 'children': <dynamic>[]},
        ],
      },
    ],
  });

  if (tree is FlodSuccess<Map<String, dynamic>>) {
    print('Recursive tree OK: ${tree.data}');
  }

  final bad = category.safeParse({
    'name': 'root',
    'children': [
      {'name': '', 'children': <dynamic>[]},
    ],
  });

  if (bad is FlodFailure<Map<String, dynamic>>) {
    print('Deep path error: ${bad.getFieldsMap()}');
  }

  // compile() leaves lazy nodes intact (no stack overflow on recursive graphs).
  final compiled = category.compile();
  final compiledOk = compiled.safeParse({
    'name': 'compiled',
    'children': <dynamic>[],
  });
  print(
    'Compiled lazy tree: '
    '${compiledOk is FlodSuccess ? 'ok' : 'failed'}',
  );

  print('');
}

/// -------------------------------------------------------------
/// 6. Inline message: on rules & refine
/// -------------------------------------------------------------
void inlineMessageDemo() {
  print('--- 6. Inline message: ---');

  final password = Flod.string().min(8, message: 'Password too short');
  final short = password.safeParse('123') as FlodFailure<String>;
  print('Rule message: ${short.getMessages()}');

  final email = Flod.string().email().refine(
    (v) => !v.endsWith('@tempmail.com'),
    message: 'Disposable emails are not allowed',
  );
  final disposable =
      email.safeParse('a@tempmail.com') as FlodFailure<String>;
  print('Refine message: ${disposable.getMessages()}');
  print('Code still present: ${disposable.errors.single.code}');

  print('');
}

/// -------------------------------------------------------------
/// 7. Defaults — withDefault / withDefaultFactory (safe cloning)
/// -------------------------------------------------------------
void defaultsDemo() {
  print('--- 7. Defaults (withDefault / withDefaultFactory) ---');

  final tags = Flod.list(schema: Flod.string()).withDefault(<String>[]);
  final a = (tags.safeParse(null) as FlodSuccess<List<String>>).data;
  a.add('mutated');
  final b = (tags.safeParse(null) as FlodSuccess<List<String>>).data;
  print(
    'withDefault([]) clones: a=$a, b=$b '
    '(identical=${identical(a, b)})',
  );

  final nested = Flod.object({
    'tags': Flod.list(schema: Flod.string()),
  }).withDefaultFactory(() => {'tags': <String>[]});

  final first =
      (nested.safeParse(null) as FlodSuccess<Map<String, dynamic>>).data;
  (first['tags'] as List).add('x');
  final second =
      (nested.safeParse(null) as FlodSuccess<Map<String, dynamic>>).data;
  print(
    'withDefaultFactory nested: first=${first['tags']}, '
    'second=${second['tags']}',
  );

  print('');
}

/// -------------------------------------------------------------
/// 8. Cross-field validation — refine / superRefine
/// -------------------------------------------------------------
void crossFieldValidation() {
  print('--- 8. Cross-field validation ---');

  final signupSchema =
      Flod.object({
        'password': Flod.string().min(8, message: 'Password too short'),
        'confirmPassword': Flod.string(),
      }).refine(
        (data) => data['password'] == data['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
        message: 'Passwords do not match',
      );

  final result = signupSchema.safeParse({
    'password': 'supersecret',
    'confirmPassword': 'doesNotMatch',
  });

  if (result is FlodFailure<Map<String, dynamic>>) {
    print('Refine caught mismatch:');
    print(result.toReadable());
    print(result.getFieldsMap());
  }

  print('');
}

/// -------------------------------------------------------------
/// 9. .secret() — PII-safe error output
/// -------------------------------------------------------------
void secretFieldsDemo() {
  print('--- 9. Secret fields (.secret()) ---');

  final publicSchema = Flod.object({
    'email': Flod.string().email(),
    'password': Flod.string().min(8),
  });

  final secretSchema = Flod.object({
    'email': Flod.string().email(),
    'password': Flod.string().min(8).secret(),
  });

  final badInput = {'email': 'bad', 'password': '123'};

  final publicFail = publicSchema.safeParse(badInput) as FlodFailure;
  final secretFail = secretSchema.safeParse(badInput) as FlodFailure;

  print('❌ PUBLIC FAIL → ${publicFail.errors.length} error(s)');
  for (final e in publicFail.errors) {
    print(
      '   ↳ Path: ${e.path.toReadable()} | Code: ${e.code} | Value: ${e.value}',
    );
  }

  print('🔒 SECRET FAIL → ${secretFail.errors.length} error(s)');
  for (final e in secretFail.errors) {
    print(
      '   ↳ Path: ${e.path.toReadable()} | Code: ${e.code} | Value: ${e.value}',
    );
  }

  print('');
}

/// -------------------------------------------------------------
/// 10. JsonGuard — structural security before schema validation
/// -------------------------------------------------------------
void jsonGuardDemo() {
  print('--- 10. JsonGuard ---');

  const guard = JsonGuard(
    options: JsonGuardOptions(
      maxDepth: 32,
      maxKeys: 1000,
      maxStringLength: 100000,
      maxArrayLength: 10000,
      blockPrototypeKeys: true,
    ),
  );

  final userSchema = Flod.object({
    'id': Flod.int().positive(),
    'name': Flod.string().min(1),
  });

  const rawJson = '{"id": 1, "name": "Ana"}';

  final result = guard.parseJson(rawJson, userSchema);
  print('JsonGuard + schema result: $result');

  print('');
}

/// -------------------------------------------------------------
/// 11. Compiled schema — hot path for production
/// -------------------------------------------------------------
void compiledSchemaDemo() {
  print('--- 11. Compiled schema (hot path) ---');

  final productionSchema = Flod.object({
    'id': Flod.int().positive(),
    'email': Flod.string().email(),
  });

  final compiled = productionSchema.compile();

  final sw = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    compiled.safeParse({'id': i + 1, 'email': 'user$i@example.com'});
  }
  sw.stop();

  print(
    '10,000 compiled safeParse calls took ${sw.elapsedMicroseconds} µs '
    '(~${(sw.elapsedMicroseconds / 10000).toStringAsFixed(2)} µs/op).',
  );

  print('');
}
