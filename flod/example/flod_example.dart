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
import 'package:flod/src/validators/exception_validator/validator_exception.dart';

void main() {
  print('=== Flod quick start ===\n');

  basicQuickStart();
  parseVsSafeParse();
  transformPipeline();
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
/// 4. Cross-field validation — refine / superRefine
/// -------------------------------------------------------------
void crossFieldValidation() {
  print('--- 4. Cross-field validation ---');

  final signupSchema =
      Flod.object({
        'password': Flod.string().min(8),
        'confirmPassword': Flod.string(),
      }).refine(
        (data) => data['password'] == data['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
      );

  final result = signupSchema.safeParse({
    'password': 'supersecret',
    'confirmPassword': 'doesNotMatch',
  });

  if (result is FlodFailure) {
    print('Refine caught mismatch:');
    print(result.toReadable());
  }

  print('');
}

/// -------------------------------------------------------------
/// 5. .secret() — PII-safe error output
/// -------------------------------------------------------------
void secretFieldsDemo() {
  print('--- 5. Secret fields (.secret()) ---');

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
/// 6. JsonGuard — structural security before schema validation
/// -------------------------------------------------------------
void jsonGuardDemo() {
  print('--- 6. JsonGuard ---');

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
/// 7. Compiled schema — hot path for production
/// -------------------------------------------------------------
void compiledSchemaDemo() {
  print('--- 7. Compiled schema (hot path) ---');

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
