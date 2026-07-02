// lib/src/res/parse_result.dart
import 'package:flod/flod.dart';

sealed class ParseResult<Out> {
  const ParseResult();
}

class FlodSuccess<Out> extends ParseResult<Out> {
  final Out data;
  const FlodSuccess(this.data);
}

class FlodFailure<Out> extends ParseResult<Out> {
  final List<FlodError> errors;
  const FlodFailure(this.errors);

  /// Returns human-readable messages using the resolver.
  /// Pass a local resolver, otherwise the global one is used.
  List<String> getMessages({FlodI18nResolver? customResolver}) {
    final resolver = customResolver ?? FlodConfig.errorResolver;
    return errors.map((err) => resolver.translate(err)).toList();
  }

  /// Error map like {"user.age": "Value must be greater than or equal to 18"}
  /// Ideal for Flutter Form / Form Validation Map.
  Map<String, String> getFieldsMap({FlodI18nResolver? customResolver}) {
    final resolver = customResolver ?? FlodConfig.errorResolver;
    final Map<String, String> map = {};
    for (final error in errors) {
      // Use existing error.pathContext or cached path
      map[error.path.toReadable()] = resolver.translate(error);
    }
    return map;
  }

  /// Returns a map grouping ALL localized errors per field.
  /// Ideal for advanced UI components with Multi-Error support
  Map<String, List<String>> getGroupedFieldsMap({
    FlodI18nResolver? customResolver,
  }) {
    final resolver = customResolver ?? FlodConfig.errorResolver;
    final Map<String, List<String>> map = {};

    for (final error in errors) {
      final pathKey = error.path.toReadable();
      final translatedMessage = resolver.translate(error);
      map.putIfAbsent(pathKey, () => []).add(translatedMessage);
    }
    return map;
  }
}

extension ParseResultReadable<T> on ParseResult<T> {
  String toReadable({FlodI18nResolver? customResolver}) {
    if (this is FlodSuccess<T>) {
      final success = this as FlodSuccess<T>;
      return success.data.toString();
    }

    final failure = this as FlodFailure<T>;

    return failure.getMessages(customResolver: customResolver).join('\n');
  }
}
