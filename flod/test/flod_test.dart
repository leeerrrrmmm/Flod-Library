import 'package:flod/flod.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectValidator composition', () {
    final base = Flod.object({
      'name': Flod.string(),
      'age': Flod.int(),
      'address': Flod.object({
        'city': Flod.string(),
        'zip': Flod.string(),
      }),
    });

    test('extend adds and overrides keys', () {
      final extended = base.extend({'age': Flod.string(), 'email': Flod.string().email()});

      final result = extended.safeParse({
        'name': 'Alice',
        'age': '30',
        'email': 'alice@example.com',
        'address': {'city': 'Kyiv', 'zip': '01001'},
      });

      expect(result, isA<FlodSuccess>());
    });

    test('merge combines two object schemas', () {
      final extra = Flod.object({'role': Flod.string()});
      final merged = base.merge(extra);

      final result = merged.safeParse({
        'name': 'Bob',
        'age': 25,
        'role': 'admin',
        'address': {'city': 'Lviv', 'zip': '79000'},
      });

      expect(result, isA<FlodSuccess>());
    });

    test('partial makes all fields optional', () {
      final partial = base.partial();

      expect(partial.safeParse({}), isA<FlodSuccess>());
      expect(
        partial.safeParse({'address': {'city': 'Odesa'}}),
        isA<FlodSuccess>(),
      );
    });

    test('partial deep makes nested fields optional', () {
      final partial = base.partial(deep: true);

      final result = partial.safeParse({
        'address': {},
      });

      expect(result, isA<FlodSuccess>());
    });

    test('pick keeps only selected keys', () {
      final picked = base.pick(['name']);

      expect(
        picked.safeParse({'name': 'Eve'}),
        isA<FlodSuccess>(),
      );
      expect(
        picked.safeParse({'name': 'Eve', 'age': 20}),
        isA<FlodSuccess>(),
      );
    });

    test('omit removes selected keys', () {
      final omitted = base.omit(['age']);

      final result = omitted.safeParse({
        'name': 'Dan',
        'address': {'city': 'Kharkiv', 'zip': '61000'},
      });

      expect(result, isA<FlodSuccess>());
      expect((result as FlodSuccess).data.containsKey('age'), isFalse);
    });
  });

  group('Zod-compatible API aliases', () {
    test('ListValidator.min/max', () {
      final schema = Flod.list(schema: Flod.int()).min(1).max(3);

      expect(schema.safeParse([1, 2]), isA<FlodSuccess>());
      expect(schema.safeParse([]), isA<FlodFailure>());
      expect(schema.safeParse([1, 2, 3, 4]), isA<FlodFailure>());
    });

    test('StringValidator.length alias', () {
      final schema = Flod.string().length(3);

      expect(schema.safeParse('abc'), isA<FlodSuccess>());
      expect(schema.safeParse('ab'), isA<FlodFailure>());
    });

    test('withDefault canonical default API', () {
      final schema = Flod.string().withDefault('guest');

      expect(schema.safeParse(null), isA<FlodSuccess>());
      expect((schema.safeParse(null) as FlodSuccess).data, 'guest');
    });

    test('number sign rules on IntValidator', () {
      expect(Flod.int().positive().safeParse(1), isA<FlodSuccess>());
      expect(Flod.int().positive().safeParse(0), isA<FlodFailure>());
    });

    test('number sign rules on DoubleValidator', () {
      expect(Flod.double().nonNegative().safeParse(0.0), isA<FlodSuccess>());
      expect(Flod.double().nonNegative().safeParse(-1.0), isA<FlodFailure>());
    });
  });

  group('Debug mode (15.3)', () {
    tearDown(() {
      FlodConfig.debug = false;
      FlodConfig.onTrace = null;
    });

    test('FlodDebug.trace emits when debug enabled', () {
      final traces = <String>[];
      FlodConfig.debug = true;
      FlodConfig.onTrace = traces.add;

      Flod.object({'name': Flod.string()}).safeParse({'name': 'Alice'});

      expect(traces, isNotEmpty);
      expect(traces.any((t) => t.contains('ObjectValidator')), isTrue);
    });

    test('FlodDebug.trace silent when debug disabled', () {
      final traces = <String>[];
      FlodConfig.debug = false;
      FlodConfig.onTrace = traces.add;

      Flod.string().safeParse('hello');

      expect(traces, isEmpty);
    });
  });

  group('SuperRefine & async refine (21.3)', () {
    test('superRefine adds multiple targeted issues', () {
      final schema = Flod.object({
        'password': Flod.string().min(8),
        'confirmPassword': Flod.string(),
      }).superRefine((val, ctx) {
        if (val['password'] != val['confirmPassword']) {
          ctx.addIssue(
            path: ['confirmPassword'],
            code: 'password_mismatch',
          );
        }
        if (val['password'] == 'weakpass') {
          ctx.addIssue(
            path: ['password'],
            code: 'password_too_common',
          );
        }
      });

      final result = schema.safeParse({
        'password': 'weakpass',
        'confirmPassword': 'different',
      });

      expect(result, isA<FlodFailure>());
      final errors = (result as FlodFailure).errors;
      expect(errors.length, 2);
      expect(
        errors.any((e) => e.path.toReadable().contains('confirmPassword')),
        isTrue,
      );
      expect(
        errors.any((e) => e.path.toReadable().contains('password')),
        isTrue,
      );
    });

    test('refineAsync validates asynchronously', () async {
      final schema = Flod.object({
        'token': Flod.string(),
      }).refineAsync((val) async {
        await Future<void>.delayed(Duration.zero);
        return val['token'] == 'valid';
      }, code: 'invalid_token');

      expect(schema.safeParse({'token': 'bad'}), isA<FlodFailure>());
      expect(
        schema.safeParse({'token': 'bad'}) as FlodFailure,
        predicate<FlodFailure>(
          (f) => f.errors.first.code == FlodErrorCodes.asyncParseRequired,
        ),
      );

      final result = await schema.safeParseAsync({'token': 'valid'});
      expect(result, isA<FlodSuccess>());
    });

    test('superRefineAsync validates asynchronously', () async {
      final schema = Flod.object({
        'a': Flod.int(),
        'b': Flod.int(),
      }).superRefineAsync((val, ctx) async {
        await Future<void>.delayed(Duration.zero);
        if ((val['a'] as int) + (val['b'] as int) > 10) {
          ctx.addIssue(path: ['b'], code: 'sum_too_large');
        }
      });

      final fail = await schema.safeParseAsync({'a': 6, 'b': 5});
      expect(fail, isA<FlodFailure>());

      final ok = await schema.safeParseAsync({'a': 3, 'b': 4});
      expect(ok, isA<FlodSuccess>());
    });
  });
}
