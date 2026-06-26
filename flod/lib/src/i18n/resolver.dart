import 'package:flod/src/i18n/default_locale.dart';
import 'package:flod/src/types/flod_error.dart';

/// Signature for external locale compilers: `(code, params) => String`.
typedef FlodLocaleCompiler =
    String Function(String code, Map<String, dynamic> params);

class FlodI18nResolver {
  final FlodLocaleCompiler _compiler;

  const FlodI18nResolver([FlodLocaleCompiler? compiler])
    : _compiler = compiler ?? FlodDefaultLocale.compile;

  /// Resolves a [FlodError] into a user-facing message.
  String translate(FlodError error) {
    return _compiler(error.code, error.params);
  }
}
