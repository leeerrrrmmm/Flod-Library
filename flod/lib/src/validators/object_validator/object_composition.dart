import 'package:flod/flod.dart';

/// Recursively makes every field in [schema] optional.
/// When [deep] is true, nested [ObjectValidator]s and list item schemas
/// are partialized as well (Zod `.partial()` / `.deepPartial()` semantics).
Map<String, Validator> partializeSchema(
  Map<String, Validator> schema, {
  bool deep = true,
}) {
  return {
    for (final entry in schema.entries)
      entry.key: partializeField(entry.value, deep: deep),
  };
}

Validator partializeField(Validator validator, {bool deep = true}) {
  if (validator is OptionalValidator) {
    return OptionalValidator(
      _partializeInner(validator.inner, deep: deep),
      transformers: validator.transformers,
      isSecret: validator.isSecret,
    );
  }

  if (validator is NullableValidator) {
    return NullableValidator(
      _partializeInner(validator.inner, deep: deep),
      transformers: validator.transformers,
      isSecret: validator.isSecret,
    );
  }

  return _partializeInner(validator, deep: deep).optional();
}

Validator _partializeInner(Validator validator, {required bool deep}) {
  if (deep && validator is ObjectValidator) {
    return validator.partial(deep: deep);
  }

  if (deep && validator is ListValidator) {
    final itemSchema = validator.schema;
    if (itemSchema != null) {
      return validator.copyWith(
        schema: _partializeInner(itemSchema, deep: deep),
      );
    }
  }

  return validator;
}
