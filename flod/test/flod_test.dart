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
    test('ListValidator.min/max aliases', () {
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

    test('withDefault alias', () {
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
}
