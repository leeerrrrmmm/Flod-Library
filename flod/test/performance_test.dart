import 'package:flod/flod.dart';
import 'package:test/test.dart';

void main() {
  group('Performance Layer (12)', () {
    test('12.1 SchemaPool returns shared base instances', () {
      expect(identical(Flod.string(), Flod.string()), isTrue);
      expect(identical(Flod.int(), Flod.int()), isTrue);
      expect(identical(Flod.double(), Flod.double()), isTrue);
      expect(identical(Flod.boolean(), Flod.boolean()), isTrue);
      expect(identical(SchemaPool.string, Flod.string()), isTrue);
    });

    test('12.2 chain copyWith returns same instance when unchanged', () {
      final schema = Flod.string().min(1).max(10);
      final secret = schema.secret();
      expect(identical(secret.secret(), secret), isTrue);
      expect(identical(SchemaPool.string, Flod.string()), isTrue);
    });

    test('12.2 isPure fast path for base string validator', () {
      expect(SchemaPool.string.isPure, isTrue);
      expect(SchemaPool.string.safeParse('hello'), isA<FlodSuccess>());
    });

    test('12.3 compile produces CompiledObjectValidator', () {
      final schema = Flod.object({
        'name': Flod.string().min(1),
        'age': Flod.int().min(0),
      });

      final compiled = schema.compile();
      expect(compiled.isCompiled, isTrue);
      expect(compiled, isA<CompiledObjectValidator>());

      final input = {'name': 'Alice', 'age': 30};
      expect(compiled.safeParse(input), isA<FlodSuccess>());
      expect(schema.safeParse(input), isA<FlodSuccess>());
    });

    test('12.3 compile caches by validator identity', () {
      ValidatorCompiler.instance.clearCache();
      final schema = Flod.object({'id': Flod.int()});

      final first = schema.compile();
      final second = schema.compile();

      expect(identical(first, second), isTrue);
      expect(ValidatorCompiler.instance.cacheSize, greaterThan(0));
    });

    test('12.3 compiled list hoists item schema', () {
      final raw = Flod.list(schema: Flod.int()).min(1);
      final schema = raw.compile();
      expect(schema.safeParse([1, 2, 3]), isA<FlodSuccess>());
      expect(schema.safeParse([]), isA<FlodFailure>());
      expect(identical(schema.compile(), schema), isTrue);
    });

    test('12.3 compiled object pre-resolves secret fields', () {
      final schema = Flod.object({
        'password': Flod.string().min(8),
      }).secret().compile();

      expect(schema, isA<CompiledObjectValidator>());
      final result = schema.safeParse({'password': '12345678'});
      expect(result, isA<FlodSuccess>());
    });

    test('12.3 compile preserves validation semantics for nested objects', () {
      final base = Flod.object({
        'name': Flod.string(),
        'age': Flod.int(),
        'address': Flod.object({
          'city': Flod.string(),
          'zip': Flod.string(),
        }),
      });

      final compiled = base.compile();
      final input = {
        'name': 'Bob',
        'age': 25,
        'address': {'city': 'Kyiv', 'zip': '01001'},
      };

      expect(compiled.safeParse(input), isA<FlodSuccess>());
    });
  });
}
