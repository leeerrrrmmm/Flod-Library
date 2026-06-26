import 'package:flod/src/i18n/resolver.dart';

class FlodConfig {
  FlodConfig._();

  // Resolver for error messages localization
  static FlodI18nResolver errorResolver = const FlodI18nResolver();

  static void setup({FlodLocaleCompiler? localeCompiler}) {
    if (localeCompiler != null) {
      errorResolver = FlodI18nResolver(localeCompiler);
    }
  }
}
