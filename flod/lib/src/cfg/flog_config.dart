import 'package:flod/src/i18n/resolver.dart';

class FlodConfig {
  FlodConfig._();

  // Resolver for error messages localization
  static FlodI18nResolver errorResolver = const FlodI18nResolver();

  /// 12.3 — enables compiled-validator identity cache (default: true).
  static bool enablePerformanceCache = true;

  /// 12.3 — max entries before the validator cache is cleared.
  static int maxValidatorCacheSize = 256;

  static void setup({
    FlodLocaleCompiler? localeCompiler,
    bool? enablePerformanceCache,
    int? maxValidatorCacheSize,
  }) {
    if (localeCompiler != null) {
      errorResolver = FlodI18nResolver(localeCompiler);
    }
    if (enablePerformanceCache != null) {
      FlodConfig.enablePerformanceCache = enablePerformanceCache;
    }
    if (maxValidatorCacheSize != null) {
      FlodConfig.maxValidatorCacheSize = maxValidatorCacheSize;
    }
  }
}
