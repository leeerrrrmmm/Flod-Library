import 'package:flod/flod.dart';
import 'package:flod/src/core/decorator/default_decorator.dart';
import 'package:flod/src/validators/transform_validator/transform_validator.dart';

/// 12.3 Caching — compiles validator trees into optimized runtime forms.
final class ValidatorCompiler {
  ValidatorCompiler._();

  static final ValidatorCompiler instance = ValidatorCompiler._();

  final Map<int, Validator> _cache = {};

  /// Clears the compiled-validator cache.
  void clearCache() => _cache.clear();

  int get cacheSize => _cache.length;

  /// Compiles [validator] into an optimized form and caches by identity.
  Validator<T> compile<T>(Validator<T> validator) {
    if (!FlodConfig.enablePerformanceCache) {
      return _compileTree(validator);
    }

    if (validator.isCompiled) return validator;

    final key = identityHashCode(validator);
    final cached = _cache[key];
    if (cached != null) return cached as Validator<T>;

    final compiled = _compileTree(validator);
    _evictIfNeeded();
    _cache[key] = compiled;
    return compiled;
  }

  void _evictIfNeeded() {
    if (_cache.length >= FlodConfig.maxValidatorCacheSize) {
      _cache.clear();
    }
  }

  Validator<T> _compileTree<T>(Validator<T> validator) {
    if (validator.isCompiled) return validator;

    final dynamic node = validator;

    if (node is ObjectValidator) {
      return _compileObject(node) as Validator<T>;
    }
    if (node is ListValidator) {
      return _compileListAs<T>(node);
    }
    if (node is NullableValidator) {
      return _compileNullable(node) as Validator<T>;
    }
    if (node is OptionalValidator) {
      return _compileOptional(node) as Validator<T>;
    }
    if (validator is DefaultDecorator<T>) {
      return _compileDefault(validator);
    }
    if (validator is RefineValidator<T>) {
      return _compileRefine(validator);
    }
    if (validator is SuperRefineValidator<T>) {
      return _compileSuperRefine(validator);
    }
    if (validator is AsyncRefineValidator<T>) {
      return _compileAsyncRefine(validator);
    }
    if (validator is AsyncSuperRefineValidator<T>) {
      return _compileAsyncSuperRefine(validator);
    }
    if (validator is TransformValidator<dynamic, T>) {
      return _compileTransform(validator);
    }
    if (validator is UnionValidator<T>) {
      return _compileUnion(validator);
    }

    return validator;
  }

  CompiledObjectValidator _compileObject(ObjectValidator source) {
    final parentSecret = source.isSecret;
    final fields = <CompiledObjectField>[];

    for (final entry in source.schema.entries) {
      var fieldValidator = compile(entry.value);
      if (parentSecret && !fieldValidator.isSecret) {
        fieldValidator = fieldValidator.secret();
      }
      fields.add(CompiledObjectField(entry.key, fieldValidator));
    }

    return CompiledObjectValidator(
      fields: List.unmodifiable(fields),
      schemaKeys: source.schema.keys.toSet(),
      mode: source.mode,
      abortEarly: source.abortEarly,
      transformers: source.transformers,
      isSecret: source.isSecret,
    );
  }

  Validator<T> _compileListAs<T>(ListValidator source) {
    Validator? itemSchema = source.schema;
    if (itemSchema != null) {
      itemSchema = compile(itemSchema);
      if (source.isSecret && !itemSchema.isSecret) {
        itemSchema = itemSchema.secret();
      }
    }

    final optimized = source.copyWith(schema: itemSchema);
    return optimized as Validator<T>;
  }

  NullableValidator<E> _compileNullable<E>(NullableValidator<E> source) {
    return NullableValidator<E>(
      compile(source.inner),
      transformers: source.transformers,
      isSecret: source.isSecret,
    );
  }

  OptionalValidator<E> _compileOptional<E>(OptionalValidator<E> source) {
    return OptionalValidator<E>(
      compile(source.inner),
      transformers: source.transformers,
      isSecret: source.isSecret,
    );
  }

  DefaultDecorator<T> _compileDefault<T>(DefaultDecorator<T> source) {
    return DefaultDecorator<T>(
      compile(source.inner),
      source.defaultValue,
      transformers: source.transformers,
      isSecret: source.isSecret,
    );
  }

  RefineValidator<T> _compileRefine<T>(RefineValidator<T> source) {
    return RefineValidator<T>(
      compile(source.inner),
      source.predicate,
      source.customPath,
      source.errorCode,
      source.errorParams,
      isSecret: source.isSecret,
    );
  }

  SuperRefineValidator<T> _compileSuperRefine<T>(
    SuperRefineValidator<T> source,
  ) {
    return SuperRefineValidator<T>(
      compile(source.inner),
      source.callback,
      isSecret: source.isSecret,
    );
  }

  AsyncRefineValidator<T> _compileAsyncRefine<T>(
    AsyncRefineValidator<T> source,
  ) {
    return AsyncRefineValidator<T>(
      compile(source.inner),
      source.predicate,
      source.customPath,
      source.errorCode,
      source.errorParams,
      isSecret: source.isSecret,
    );
  }

  AsyncSuperRefineValidator<T> _compileAsyncSuperRefine<T>(
    AsyncSuperRefineValidator<T> source,
  ) {
    return AsyncSuperRefineValidator<T>(
      compile(source.inner),
      source.callback,
      isSecret: source.isSecret,
    );
  }

  TransformValidator<dynamic, T> _compileTransform<T>(
    TransformValidator<dynamic, T> source,
  ) {
    return TransformValidator<dynamic, T>(
      compile(source.parent),
      source.callback,
      isSecret: source.isSecret,
    );
  }

  UnionValidator<T> _compileUnion<T>(UnionValidator<T> source) {
    final compiledSchemas = source.schemas.map(compile).toList(growable: false);

    if (source.discriminator == null) {
      return UnionValidator<T>(
        compiledSchemas,
        transformers: source.transformers,
        isSecret: source.isSecret,
      );
    }

    return UnionValidator<T>(
      compiledSchemas,
      discriminator: source.discriminator,
      discriminatorIndex: _rebuildDiscriminatorIndex(
        compiledSchemas,
        source.discriminator!,
      ),
      transformers: source.transformers,
      isSecret: source.isSecret,
    );
  }

  Map<Object?, Validator> _rebuildDiscriminatorIndex(
    List<Validator> schemas,
    String key,
  ) {
    final index = <Object?, Validator>{};
    for (final schema in schemas) {
      final field = schema.getFieldSchema(key);
      if (field is LiteralValidator) {
        final value = field.expectedValue;
        index[value is Enum ? value.name : value] = schema;
      }
    }
    return index;
  }
}

extension CompileExtension<T> on Validator<T> {
  /// 12.3 — compiles this schema into a cached, optimized validator tree.
  Validator<T> compile() => ValidatorCompiler.instance.compile(this);
}
