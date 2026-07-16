import 'package:flod/flod.dart';
import 'package:test/test.dart';

/// Shared mega-schema builder used by omnibus stress assertions.
Validator buildCheckoutSchema() {
  final baseUser = Flod.object({
    'id': Flod.int().positive(),
    'email': Flod.string().trim().toLowerCase().email(),
    'role': Flod.literal('user'),
  });

  final baseProfile = Flod.object({
    'displayName': Flod.string().min(2).max(64).trim(),
    'age': Flod.int().min(13).max(120).optional(),
    'tags': Flod.list(schema: Flod.string().trim()).max(10).uniqueItems(),
  });

  final checkoutBase = baseUser
      .extend({
        'profile': baseProfile,
        'billing': Flod.object({
          'country': Flod.string().fixedLength(2),
          'zip': Flod.string().min(3).max(12),
        }),
      })
      .merge(Flod.object({
        'loyaltyPoints': Flod.int().nonNegative().defaultValue(0),
      }));

  final paymentUnion = Flod.union([
    Flod.object({
      'method': Flod.literal('card'),
      'pan': Flod.string().creditCard().secret(),
      'cvv': Flod.string().cvv().secret(),
      'exp': Flod.string().regex(RegExp(r'^\d{2}/\d{2}$')),
    }),
    Flod.object({
      'method': Flod.literal('crypto'),
      'wallet': Flod.string().fixedLength(42),
      'chain': Flod.literal('eth'),
    }),
  ]).discriminatedBy('method');

  return checkoutBase
      .extend({
        'password': Flod.string().min(8).minNumbers(2).minUppercase(1).secret(),
        'confirmPassword': Flod.string().secret(),
        'payment': paymentUnion,
        'items': Flod.list(
          schema: Flod.object({
            'sku': Flod.string().min(3),
            'qty': Flod.int().positive(),
            'price': Flod.double().nonNegative(),
          }),
        ).min(1),
        'metadata': Flod.object({
          'source': Flod.string().defaultValue('web'),
          'campaign': Flod.string().nullable(),
        }).passthrough(),
      })
      .refine(
        (data) => data['password'] == data['confirmPassword'],
        code: 'passwords_match',
        path: ['confirmPassword'],
      );
}

Map<String, dynamic> validCheckoutPayload() => {
      'id': 42,
      'email': '  User@Test.COM  ',
      'role': 'user',
      'profile': {
        'displayName': '  Alice  ',
        'tags': ['a', 'b'],
      },
      'billing': {'country': 'UA', 'zip': '01001'},
      'password': 'SecurePass99',
      'confirmPassword': 'SecurePass99',
      'payment': {
        'method': 'card',
        'pan': '4111111111111111',
        'cvv': '123',
        'exp': '12/30',
      },
      'items': [
        {'sku': 'SKU-1', 'qty': 1, 'price': 9.99},
      ],
      'metadata': {'extra': true},
    };

void main() {
  group('Parse API', () {
    test('safeParse returns FlodSuccess on valid data', () {
      expect(Flod.string().safeParse('hello'), isA<FlodSuccess>());
    });

    test('safeParse returns FlodFailure on invalid data', () {
      expect(Flod.int().safeParse('x'), isA<FlodFailure>());
    });

    test('parse throws ValidationException', () {
      expect(() => Flod.int().parse('x'), throwsA(isA<ValidationException>()));
    });

    test('parse returns typed data on success', () {
      expect(Flod.int().parse(7), 7);
    });
  });

  group('Nullable & Optional', () {
    test('nullable accepts null', () {
      expect(Flod.string().nullable().safeParse(null), isA<FlodSuccess>());
    });

    test('nullable validates non-null values', () {
      expect(Flod.string().min(3).nullable().safeParse('ab'), isA<FlodFailure>());
    });

    test('optional accepts missing key via object', () {
      final schema = Flod.object({'name': Flod.string().optional()});
      expect(schema.safeParse({}), isA<FlodSuccess>());
    });
  });

  group('Object modes', () {
    test('strict rejects unknown keys', () {
      final schema = Flod.object({'a': Flod.string()}).strict();
      expect(schema.safeParse({'a': 'x', 'b': 1}), isA<FlodFailure>());
    });

    test('passthrough keeps extra keys', () {
      final schema = Flod.object({'a': Flod.string()}).passthrough();
      final result = schema.safeParse({'a': 'x', 'extra': 1});
      expect(result, isA<FlodSuccess>());
      expect((result as FlodSuccess).data['extra'], 1);
    });

    test('nested path on deep failure', () {
      final schema = Flod.object({
        'user': Flod.object({'age': Flod.int().min(18)}),
      });
      final result = schema.safeParse({'user': {'age': 10}});
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.first.path.toReadable(),
        contains('age'),
      );
    });
  });

  group('List validator', () {
    test('minItems and maxItems', () {
      final schema = Flod.list(schema: Flod.int()).min(1).max(2);
      expect(schema.safeParse([]), isA<FlodFailure>());
      expect(schema.safeParse([1]), isA<FlodSuccess>());
      expect(schema.safeParse([1, 2, 3]), isA<FlodFailure>());
    });

    test('uniqueItems after trim', () {
      final schema = Flod.list(schema: Flod.string().trim()).uniqueItems();
      expect(schema.safeParse(['a', '  a  ']), isA<FlodFailure>());
    });

    test('items schema validates element types', () {
      final schema = Flod.list(schema: Flod.int());
      expect(schema.safeParse([1, 'x']), isA<FlodFailure>());
    });
  });

  group('Transform pipeline', () {
    test('trim runs before length validation', () {
      final schema = Flod.string().trim().fixedLength(3);
      expect(schema.safeParse('  abc  '), isA<FlodSuccess>());
    });

    test('type-changing transform chain', () {
      final schema = Flod.string()
          .trim()
          .transform((v) => v.length)
          .transform((n) => n * 2);
      expect(schema.safeParse('  ab  '), isA<FlodSuccess<dynamic>>());
      expect((schema.safeParse('  ab  ') as FlodSuccess).data, 4);
    });
  });

  group('Union types', () {
    test('plain union accepts matching branch', () {
      final schema = Flod.union([Flod.string(), Flod.int()]);
      expect(schema.safeParse('x'), isA<FlodSuccess>());
      expect(schema.safeParse(1), isA<FlodSuccess>());
      expect(schema.safeParse(true), isA<FlodFailure>());
    });

    test('discriminated union routes by literal', () {
      final schema = Flod.union([
        Flod.object({
          'type': Flod.literal('a'),
          'value': Flod.string(),
        }),
        Flod.object({
          'type': Flod.literal('b'),
          'value': Flod.int(),
        }),
      ]).discriminatedBy('type');

      expect(schema.safeParse({'type': 'b', 'value': 1}), isA<FlodSuccess>());
      expect(
        schema.safeParse({'type': 'b', 'value': 'x'}),
        isA<FlodFailure>(),
      );
    });

    test('discriminated union secret() works after compile', () {
      final schema = Flod.union([
        Flod.object({
          'kind': Flod.literal('email'),
          'address': Flod.string().email().secret(),
        }),
        Flod.object({
          'kind': Flod.literal('phone'),
          'number': Flod.string().phoneNumber(),
        }),
      ]).discriminatedBy('kind').compile();

      expect(() => schema.secret(), returnsNormally);
    });
  });

  group('Default values', () {
    test('defaultValue fills null', () {
      final schema = Flod.string().defaultValue('guest');
      expect((schema.safeParse(null) as FlodSuccess).data, 'guest');
    });

    test('defaultValue with transform', () {
      final schema = Flod.object({
        'port': Flod.int().defaultValue(80).transform((v) => v + 20),
      });
      expect((schema.safeParse({}) as FlodSuccess).data['port'], 100);
    });
  });

  group('AbortEarly', () {
    test('stopOnFirstError returns single error', () {
      final schema = Flod.object({
        'a': Flod.string().email(),
        'b': Flod.int().positive(),
      }).stopOnFirstError();

      final result = schema.safeParse({'a': 'bad', 'b': -1});
      expect(result, isA<FlodFailure>());
      expect((result as FlodFailure).errors.length, 1);
    });

    test('safeParse abortEarly stops at first error', () {
      final schema = Flod.object({
        'a': Flod.string().email(),
        'b': Flod.int().positive(),
      });

      final result = schema.safeParse({'a': 'bad', 'b': -1}, abortEarly: true);
      expect(result, isA<FlodFailure>());
      expect((result as FlodFailure).errors.length, 1);
    });

    test('default collects multiple errors', () {
      final schema = Flod.object({
        'a': Flod.string().email(),
        'b': Flod.int().positive(),
      });
      final result = schema.safeParse({'a': 'bad', 'b': -1});
      expect((result as FlodFailure).errors.length, greaterThanOrEqualTo(2));
    });
  });

  group('Number validators', () {
    test('int min/max', () {
      expect(Flod.int().min(10).max(20).safeParse(15), isA<FlodSuccess>());
      expect(Flod.int().min(10).max(20).safeParse(5), isA<FlodFailure>());
    });

    test('double rejects NaN', () {
      expect(Flod.double().safeParse(double.nan), isA<FlodFailure>());
    });

    test('multipleOf', () {
      expect(Flod.int().multipleOf(7).safeParse(49), isA<FlodSuccess>());
      expect(Flod.int().multipleOf(7).safeParse(50), isA<FlodFailure>());
    });

    test('sign rules', () {
      expect(Flod.int().positive().safeParse(1), isA<FlodSuccess>());
      expect(Flod.int().negative().safeParse(-1), isA<FlodSuccess>());
      expect(Flod.int().nonNegative().safeParse(0), isA<FlodSuccess>());
      expect(Flod.int().nonPositive().safeParse(0), isA<FlodSuccess>());
    });
  });

  group('String formats', () {
    test('email', () {
      expect(Flod.string().email().safeParse('a@b.co'), isA<FlodSuccess>());
      expect(Flod.string().email().safeParse('bad'), isA<FlodFailure>());
    });

    test('url uuid phone creditCard cvv', () {
      expect(
        Flod.string().url().safeParse('https://example.com'),
        isA<FlodSuccess>(),
      );
      expect(
        Flod.string().uuid().safeParse('123e4567-e89b-12d3-a456-426614174000'),
        isA<FlodSuccess>(),
      );
      expect(
        Flod.string().phoneNumber().safeParse('+1234567890'),
        isA<FlodSuccess>(),
      );
      expect(
        Flod.string().creditCard().safeParse('4111111111111111'),
        isA<FlodSuccess>(),
      );
      expect(Flod.string().cvv().safeParse('123'), isA<FlodSuccess>());
    });

    test('password policy rules', () {
      final schema = Flod.string().minUppercase(2).minNumbers(2).minSymbols(1);
      expect(schema.safeParse('AB12!'), isA<FlodSuccess>());
      expect(schema.safeParse('ab12'), isA<FlodFailure>());
    });
  });

  group('Bool & Literal', () {
    test('bool validator', () {
      expect(Flod.boolean().safeParse(true), isA<FlodSuccess>());
      expect(Flod.boolean().safeParse('true'), isA<FlodFailure>());
    });

    test('literal validator', () {
      expect(Flod.literal('active').safeParse('active'), isA<FlodSuccess>());
      expect(Flod.literal('active').safeParse('inactive'), isA<FlodFailure>());
    });
  });

  group('Refine cross-field', () {
    test('refine with path target', () {
      final schema = buildCheckoutSchema();
      final payload = validCheckoutPayload()
        ..['confirmPassword'] = 'Mismatch123';

      final result = schema.safeParse(payload);
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.any((e) => e.code == 'passwords_match'),
        isTrue,
      );
    });
  });

  group('Secret privacy', () {
    test('secret masks values in errors', () {
      final schema = Flod.string().min(10).secret();
      final result = schema.safeParse('short');
      expect(result, isA<FlodFailure>());
      final err = (result as FlodFailure).errors.first;
      expect(err.isSecret, isTrue);
      expect(err.value == null || err.value.toString() == '[HIDDEN]', isTrue);
    });
  });

  group('i18n & DX', () {
    test('getMessages getFieldsMap toReadable', () {
      final result = Flod.object({
        'email': Flod.string().email(),
      }).safeParse({'email': 'bad'});

      expect(result, isA<FlodFailure>());
      final failure = result as FlodFailure;
      expect(failure.getMessages(), isNotEmpty);
      expect(failure.getFieldsMap(), isNotEmpty);
      expect(failure.toReadable(), isNotEmpty);
    });
  });

  group('Omnibus checkout stress', () {
    late Validator rawSchema;
    late Validator compiledSchema;

    setUp(() {
      ValidatorCompiler.instance.clearCache();
      rawSchema = buildCheckoutSchema();
      compiledSchema = rawSchema.compile();
    });

    test('valid checkout passes raw and compiled', () {
      final payload = validCheckoutPayload();
      expect(rawSchema.safeParse(payload), isA<FlodSuccess>());
      expect(compiledSchema.safeParse(payload), isA<FlodSuccess>());
    });

    test('email normalized by transforms', () {
      final result = compiledSchema.safeParse(validCheckoutPayload());
      expect(result, isA<FlodSuccess>());
      expect(
        (result as FlodSuccess).data['email'],
        'user@test.com',
      );
    });

    test('compiled/raw parity over 50 iterations', () {
      for (var i = 0; i < 50; i++) {
        final payload = validCheckoutPayload()..['id'] = i + 1;
        final r1 = rawSchema.safeParse(payload);
        final r2 = compiledSchema.safeParse(payload);
        expect(r1 is FlodSuccess, r2 is FlodSuccess);
      }
    });

    test('secret on compiled schema with union does not throw', () {
      expect(() => compiledSchema.secret(), returnsNormally);
    });
  });
}
