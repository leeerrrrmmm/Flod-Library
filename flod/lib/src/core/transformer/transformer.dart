import 'package:flod/flod.dart';

typedef Transformer<T> = T Function(dynamic value);

mixin Transformable<T> {
  // Mixin stores nothing itself. It only requires a list from the subclass
  List<Transformer<T>> get transformers;

  dynamic applyTransforms(dynamic initialValue, FlodPath path) {
    dynamic current = initialValue;
    for (final transformer in transformers) {
      final result = transformer(current);

      // If transformer returned nested validation failure — intercept it!
      if (result is FlodFailure) {
        // Throw a special internal Exception that validator core
        // will catch and add to the shared error array.
        throw FlodTransformerException(result.errors);
      }

      current = result;
    }
    return current;
  }
}

/// Special exception for interrupting the transform pipeline
class FlodTransformerException implements Exception {
  final List<FlodError> errors;
  const FlodTransformerException(this.errors);
}
