import 'package:flod/src/i18n/resolver.dart';

typedef FlodTraceCallback = void Function(String message);

class FlodConfig {
  FlodConfig._();

  // Resolver for error messages localization
  static FlodI18nResolver errorResolver = const FlodI18nResolver();

  /// 12.3 — enables compiled-validator identity cache (default: true).
  static bool enablePerformanceCache = true;

  /// 12.3 — max entries before the validator cache is cleared.
  static int maxValidatorCacheSize = 256;

  /// 15.3 — enables runtime validation tracing (default: false).
  static bool debug = false;

  /// 15.3 — optional custom sink for debug traces; defaults to stdout.
  static FlodTraceCallback? onTrace;

  static void setup({
    FlodLocaleCompiler? localeCompiler,
    bool? enablePerformanceCache,
    int? maxValidatorCacheSize,
    bool? debug,
    FlodTraceCallback? onTrace,
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
    if (debug != null) {
      FlodConfig.debug = debug;
    }
    if (onTrace != null) {
      FlodConfig.onTrace = onTrace;
    }
  }
}
