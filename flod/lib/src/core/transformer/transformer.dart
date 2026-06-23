typedef Transformer<T> = T Function(dynamic value);

mixin Transformable<T> {
  // Миксин больше ничего не хранит сам. Он лишь требует список от наследника
  List<Transformer<T>> get transformers;

  dynamic applyTransforms(dynamic value) {
    dynamic transformed = value;
    for (final transform in transformers) {
      transformed = transform(transformed);
    }
    return transformed;
  }
}
