import 'package:flod/dio.dart';
import 'package:flod/form.dart';
import 'package:flod/guard.dart';
import 'package:flod/flod.dart';
import 'package:test/test.dart';

void main() {
  group('JsonGuard', () {
    const guard = JsonGuard();
    final userSchema = Flod.object({
      'name': Flod.string().min(2),
      'age': Flod.int().positive(),
    });

    test('parseJson accepts valid payload', () {
      final result = guard.parseJson('{"name":"Ada","age":30}', userSchema);
      expect(result, isA<FlodSuccess>());
      expect((result as FlodSuccess).data['name'], 'Ada');
    });

    test('parseJson rejects malformed JSON', () {
      final result = guard.parseJson('{bad json', userSchema);
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.first.code,
        FlodErrorCodes.guardInvalidJson,
      );
    });

    test('blocks prototype pollution keys', () {
      final result = guard.parseJson(
        '{"name":"Ada","age":30,"__proto__":{"admin":true}}',
        userSchema,
      );
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.first.code,
        FlodErrorCodes.guardPrototypeKey,
      );
    });

    test('enforces max depth', () {
      const shallow = JsonGuard(options: JsonGuardOptions(maxDepth: 2));
      final result = shallow.guard({
        'a': {'b': {'c': 1}},
      }, userSchema);
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.first.code,
        FlodErrorCodes.guardMaxDepth,
      );
    });

    test('enforces max keys budget', () {
      const tight = JsonGuard(options: JsonGuardOptions(maxKeys: 1));
      final result = tight.guard({'name': 'Ada', 'age': 30}, userSchema);
      expect(result, isA<FlodFailure>());
      expect(
        (result as FlodFailure).errors.first.code,
        FlodErrorCodes.guardMaxKeys,
      );
    });

    test('parseJsonOrThrow throws on guard failure', () {
      expect(
        () => guard.parseJsonOrThrow('not-json', userSchema),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('FlodFormAdapter', () {
    final schema = Flod.object({
      'email': Flod.string().email(),
      'password': Flod.string().min(8),
      'confirmPassword': Flod.string(),
    }).refine(
      (d) => d['password'] == d['confirmPassword'],
      code: 'passwords_match',
      path: ['confirmPassword'],
    );

    final adapter = FlodFormAdapter(schema);

    test('validate returns field map via getFieldsMap', () {
      final fields = adapter.validate({
        'email': 'bad',
        'password': 'short',
        'confirmPassword': 'other',
      });
      expect(fields, isNotEmpty);
      expect(fields.keys, contains('email'));
    });

    test('errorFor returns message for single field', () {
      final msg = adapter.errorFor('email', {'email': 'bad'});
      expect(msg, isNotNull);
    });

    test('fieldValidator returns null when field is valid in context', () {
      final validator = adapter.fieldValidator(
        'email',
        () => {
          'email': 'user@example.com',
          'password': 'longenough',
          'confirmPassword': 'longenough',
        },
      );
      expect(validator(null), isNull);
    });

    test('validateGrouped collects multiple messages per field', () {
      final grouped = adapter.validateGrouped({'email': 'bad', 'password': 'x'});
      expect(grouped['email'], isNotNull);
      expect(grouped['password'], isNotNull);
    });
  });

  group('FlodValidateInterceptor', () {
    final schema = Flod.object({'id': Flod.int(), 'title': Flod.string()});

    test('validatePayload accepts valid data', () {
      final result = FlodValidateInterceptor.validatePayload(
        raw: {'id': 1, 'title': 'Hello'},
        schema: schema,
      );
      expect(result, isA<FlodSuccess>());
    });

    test('validatePayload rejects invalid schema data', () {
      final result = FlodValidateInterceptor.validatePayload(
        raw: {'id': 'not-int', 'title': 'Hello'},
        schema: schema,
      );
      expect(result, isA<FlodFailure>());
    });

    test('validatePayload uses JsonGuard when configured', () {
      const tightGuard = JsonGuard(options: JsonGuardOptions(maxKeys: 1));
      final result = FlodValidateInterceptor.validatePayload(
        raw: {'id': 1, 'title': 'Hello'},
        schema: schema,
        guard: tightGuard,
      );
      expect(result, isA<FlodFailure>());
    });

    test('onResponse replaces response.data on success', () async {
      final interceptor = FlodValidateInterceptor(schema: schema);
      final response = Response(
        requestOptions: RequestOptions(path: '/posts/1'),
        data: {'id': 1, 'title': 'Hello'},
      );
      final handler = _CapturingResponseHandler();
      interceptor.onResponse(response, handler);
      final state = await handler.completedResponse();
      expect(state.data, isA<Map>());
      expect((state.data as Map)['id'], 1);
    });

    test('onResponse rejects invalid payload', () async {
      final interceptor = FlodValidateInterceptor(schema: schema);
      final response = Response(
        requestOptions: RequestOptions(path: '/posts/1'),
        data: {'id': 'bad', 'title': 'Hello'},
      );
      final handler = _CapturingResponseHandler();
      interceptor.onResponse(response, handler);
      try {
        await handler.whenComplete();
        fail('expected reject');
      } catch (e) {
        expect(e.toString(), contains('Validation Exception'));
      }
    });

    test('extractData pulls nested payload via onResponse', () async {
      final interceptor = FlodValidateInterceptor(
        schema: schema,
        extractData: (r) => (r.data as Map)['data'],
      );
      final response = Response(
        requestOptions: RequestOptions(path: '/posts/1'),
        data: {
          'meta': {'ok': true},
          'data': {'id': 2, 'title': 'Nested'},
        },
      );
      final handler = _CapturingResponseHandler();
      interceptor.onResponse(response, handler);
      final state = await handler.completedResponse();
      expect((state.data as Map)['id'], 2);
    });
  });
}

/// Exposes [ResponseInterceptorHandler.future] for tests (protected in Dio).
final class _CapturingResponseHandler extends ResponseInterceptorHandler {
  Future<Response> completedResponse() async {
    final state = await future;
    return (state as dynamic).data as Response;
  }

  Future<void> whenComplete() => future;
}
