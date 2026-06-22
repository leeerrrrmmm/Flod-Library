typedef Transformer<T> = T Function(dynamic value);

mixin Transformable<T> {
  final List<Transformer<T>> _transforms = [];

  void addTransform(Transformer<T> transform) => _transforms.add(transform);

  dynamic applyTransforms(dynamic value) {
    dynamic transformed = value;
    for (final transform in _transforms) {
      transformed = transform(transformed);
    }
    return transformed;
  }
}
