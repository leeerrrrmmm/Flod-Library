import 'package:flod/flod.dart';

/// Contract for validators that require [ValidatorExtensions.safeParseAsync].
abstract interface class AsyncValidator<T> {
  Future<ParseResult<T>> validateAsync(
    dynamic value, {
    FlodPath path = const FlodPath([]),
    bool? abortEarly,
  });
}
