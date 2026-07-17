import 'package:flod/flod.dart';
import 'package:test/test.dart';

void main() {
  group('withDefault / withDefaultFactory', () {
    test('immutable withDefault still works', () {
      final schema = Flod.string().withDefault('guest');
      final r = schema.safeParse(null) as FlodSuccess<String>;
      expect(r.data, 'guest');
    });

    test('withDefault([]) does not share list instances across parses', () {
      final schema = Flod.list(schema: Flod.string()).withDefault(<String>[]);

      final a = (schema.safeParse(null) as FlodSuccess<List<String>>).data;
      a.add('mutated');
      final b = (schema.safeParse(null) as FlodSuccess<List<String>>).data;

      expect(b, isEmpty);
      expect(identical(a, b), isFalse);
    });

    test('withDefault({}) does not share map instances across parses', () {
      final schema = Flod.object({
        'n': Flod.int().optional(),
      }).passthrough().withDefault(<String, dynamic>{});

      final a =
          (schema.safeParse(null) as FlodSuccess<Map<String, dynamic>>).data;
      a['x'] = 1;
      final b =
          (schema.safeParse(null) as FlodSuccess<Map<String, dynamic>>).data;

      expect(b.containsKey('x'), isFalse);
      expect(identical(a, b), isFalse);
    });

    test('withDefaultFactory creates a fresh value each time', () {
      var calls = 0;
      final schema = Flod.list(schema: Flod.int()).withDefaultFactory(() {
        calls++;
        return <int>[calls];
      });

      final a = (schema.safeParse(null) as FlodSuccess<List<int>>).data;
      final b = (schema.safeParse(null) as FlodSuccess<List<int>>).data;

      expect(a, [1]);
      expect(b, [2]);
      expect(calls, 2);
    });
  });

  group('inline message:', () {
    test('string.min message bypasses i18n resolver', () {
      final schema = Flod.string().min(5, message: 'Too short');
      final failure = schema.safeParse('hi') as FlodFailure<String>;

      expect(failure.getMessages(), ['Too short']);
      expect(failure.errors.single.message, 'Too short');
      expect(failure.errors.single.code, FlodErrorCodes.stringMin);
    });

    test('int.min message works', () {
      final schema = Flod.int().min(18, message: 'Must be 18+');
      final failure = schema.safeParse(10) as FlodFailure<int>;
      expect(failure.getMessages().single, 'Must be 18+');
    });

    test('leaf refine message works on primitives', () {
      final schema = Flod.string().email().refine(
        (v) => !v.endsWith('@tempmail.com'),
        message: 'Disposable emails are not allowed',
      );
      final failure =
          schema.safeParse('a@tempmail.com') as FlodFailure<String>;
      expect(
        failure.getMessages().single,
        'Disposable emails are not allowed',
      );
    });

    test('without message, default locale still applies', () {
      final schema = Flod.string().min(5);
      final failure = schema.safeParse('hi') as FlodFailure<String>;
      expect(failure.getMessages().single, isNot(equals('Too short')));
      expect(failure.errors.single.message, isNull);
    });
  });

  group('Flod.coerce', () {
    test('coerce.int from String', () {
      final schema = Flod.coerce.int().min(18);
      expect(schema.safeParse('21'), isA<FlodSuccess<int>>());
      expect((schema.safeParse('21') as FlodSuccess<int>).data, 21);
      expect(schema.safeParse('10'), isA<FlodFailure>());
      expect(schema.safeParse('nope'), isA<FlodFailure>());
    });

    test('coerce.int from num and bool', () {
      expect(
        (Flod.coerce.int().safeParse(3.9) as FlodSuccess<int>).data,
        3,
      );
      expect(
        (Flod.coerce.int().safeParse(true) as FlodSuccess<int>).data,
        1,
      );
    });

    test('coerce.double from String', () {
      final schema = Flod.coerce.double().nonNegative();
      expect(
        (schema.safeParse('3.14') as FlodSuccess<double>).data,
        closeTo(3.14, 1e-9),
      );
      expect(schema.safeParse('-1'), isA<FlodFailure>());
    });

    test('coerce.boolean from common strings', () {
      final schema = Flod.coerce.boolean();
      expect((schema.safeParse('true') as FlodSuccess<bool>).data, isTrue);
      expect((schema.safeParse('FALSE') as FlodSuccess<bool>).data, isFalse);
      expect((schema.safeParse('1') as FlodSuccess<bool>).data, isTrue);
      expect((schema.safeParse('0') as FlodSuccess<bool>).data, isFalse);
      expect(schema.safeParse('maybe'), isA<FlodFailure>());
    });

    test('coerce.string from numbers', () {
      final schema = Flod.coerce.string().min(2);
      expect(
        (schema.safeParse(42) as FlodSuccess<String>).data,
        '42',
      );
    });

    test('form-shaped object with coerce fields', () {
      final schema = Flod.object({
        'age': Flod.coerce.int().min(18),
        'price': Flod.coerce.double().nonNegative(),
        'active': Flod.coerce.boolean(),
      });

      final ok = schema.safeParse({
        'age': '22',
        'price': '9.99',
        'active': 'yes',
      });
      expect(ok, isA<FlodSuccess<Map<String, dynamic>>>());
      final data = (ok as FlodSuccess<Map<String, dynamic>>).data;
      expect(data['age'], 22);
      expect(data['price'], closeTo(9.99, 1e-9));
      expect(data['active'], isTrue);
    });
  });

  group('Flod.lazy', () {
    test('recursive category tree validates', () {
      late final Validator<Map<String, dynamic>> category;
      category = Flod.object({
        'name': Flod.string().min(1),
        'children': Flod.list(schema: Flod.lazy(() => category)),
      });

      final ok = category.safeParse({
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
      expect(ok, isA<FlodSuccess>());

      final bad = category.safeParse({
        'name': 'root',
        'children': [
          {'name': '', 'children': <dynamic>[]},
        ],
      });
      expect(bad, isA<FlodFailure>());
      final keys =
          (bad as FlodFailure<Map<String, dynamic>>).getFieldsMap().keys;
      expect(keys.any((k) => k.contains('children[0].name')), isTrue);
    });

    test('compile leaves lazy intact (no stack overflow)', () {
      late final Validator<Map<String, dynamic>> node;
      node = Flod.object({
        'v': Flod.int(),
        'next': Flod.lazy(() => node).optional(),
      });

      final compiled = node.compile();
      final r = compiled.safeParse({
        'v': 1,
        'next': {
          'v': 2,
          'next': {'v': 3},
        },
      });
      expect(r, isA<FlodSuccess>());
    });
  });
}
