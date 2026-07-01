import 'package:flod/flod.dart';
import 'package:flod/src/core/transformer/transformer.dart';

class UnionValidator<T> extends Validator<T> with Transformable<T> {
  final List<Validator> schemas;
  final String? discriminator;
  final Map<Object?, Validator> discriminatorIndex;

  @override
  final List<Transformer<T>> transformers;

  const UnionValidator(
    this.schemas, {
    this.discriminator,
    this.discriminatorIndex = const {},
    this.transformers = const [],
    super.isSecret = false,
  });

  @override
  UnionValidator<T> secret() {
    final secretSchemas = schemas.map((s) => s.secret()).toList();

    final next = copyWith(schemas: secretSchemas, isSecret: true);

    // rebuild index only if discriminator exists
    if (discriminator != null) {
      return next.copyWith(
        discriminatorIndex: _buildIndex(secretSchemas, discriminator),
      );
    }

    return next;
  }

  UnionValidator<T> discriminatedBy(String key) {
    return copyWith(
      discriminator: key,
      discriminatorIndex: _buildIndex(schemas, key),
    );
  }

  Object? _normalizeKey(Object? key) {
    if (key == null) return null;
    if (key is Enum) return key.name;
    return key;
  }

  Map<Object?, Validator> _buildIndex(List<Validator> schemas, String? key) {
    if (key == null) return const {};

    final index = <Object?, Validator>{};

    for (final schema in schemas) {
      final field = schema.getFieldSchema(key);

      if (field == null) {
        throw StateError('Schema does not contain discriminator "$key".');
      }

      if (field is! LiteralValidator) {
        throw StateError('Discriminator "$key" must be a LiteralValidator.');
      }

      final value = _normalizeKey(field.expectedValue);

      if (index.containsKey(value)) {
        throw StateError('Duplicate discriminator value "$value".');
      }

      index[value] = schema;
    }

    return index;
  }

  UnionValidator<T> copyWith({
    List<Validator>? schemas,
    String? discriminator,
    Map<Object?, Validator>? discriminatorIndex,
    List<Transformer<T>>? transformers,
    bool? isSecret,
  }) {
    final nextSchemas = schemas ?? this.schemas;
    final nextDiscriminator = discriminator ?? this.discriminator;

    final nextIndex =
        discriminatorIndex ?? _buildIndex(nextSchemas, nextDiscriminator);

    return UnionValidator<T>(
      nextSchemas,
      discriminator: nextDiscriminator,
      discriminatorIndex: nextIndex,
      transformers: transformers ?? this.transformers,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  @override
  ParseResult<T> validate(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly = false,
  }) {
    final transformedValue = applyTransforms(value, path);

    // =========================
    // FAST PATH O(1)
    // =========================
    if (discriminator != null &&
        transformedValue is Map &&
        transformedValue.containsKey(discriminator)) {
      final rawKey = _normalizeKey(transformedValue[discriminator]);
      final schema = discriminatorIndex[rawKey];

      if (schema != null) {
        final result = schema.validate(
          transformedValue,
          path: path,
          abortEarly: abortEarly,
        );

        if (result is FlodSuccess) {
          final data = result.data;

          if (data is T) {
            return FlodSuccess<T>(data);
          }

          return FlodFailure<T>([
            FlodError(
              path: path,
              code: FlodErrorCodes.invalidUnionType,
              params: {},
              value: isSecret ? null : transformedValue,
              isSecret: isSecret,
            ),
          ]);
        }

        if (result is FlodFailure) {
          return FlodFailure<T>(result.errors);
        }
      }
    }

    // =========================
    // SLOW PATH O(n)
    // =========================
    final allErrors = <FlodError>[];

    for (final schema in schemas) {
      final result = schema.validate(transformedValue, path: path);

      if (result is FlodSuccess) {
        final data = result.data;

        if (data is T) {
          return FlodSuccess<T>(data);
        }

        allErrors.add(
          FlodError(
            path: path,
            code: FlodErrorCodes.invalidUnionType,
            params: {},
            value: isSecret ? null : transformedValue,
            isSecret: isSecret,
          ),
        );
      } else if (result is FlodFailure) {
        allErrors.addAll(result.errors);
      }
    }

    return FlodFailure<T>([
      FlodError(
        path: path,
        code: FlodErrorCodes.union,
        params: {},
        value: isSecret ? null : transformedValue,
        isSecret: isSecret,
      ),
      ...allErrors,
    ]);
  }
}
