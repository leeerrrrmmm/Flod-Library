import 'package:flod/src/cfg/flog_config.dart';
import 'package:flod/src/types/path.dart';

/// 15.3 — runtime validation tracing when [FlodConfig.debug] is enabled.
abstract final class FlodDebug {
  static void trace(
    String phase, {
    required String validator,
    FlodPath path = const FlodPath([]),
    dynamic value,
    bool isSecret = false,
    String? detail,
  }) {
    if (!FlodConfig.debug) return;

    final pathStr = path.toReadable();
    final valueStr = isSecret ? '[HIDDEN]' : _formatValue(value);
    final suffix = detail != null ? ' ($detail)' : '';
    final message = '[$phase] $validator @ $pathStr → $valueStr$suffix';

    final sink = FlodConfig.onTrace;
    if (sink != null) {
      sink(message);
    } else {
      // ignore: avoid_print
      print('[Flod] $message');
    }
  }

  static String _formatValue(dynamic value) {
    if (value == null) return 'null';
    final text = value.toString();
    if (text.length > 80) return '${text.substring(0, 77)}...';
    return text;
  }
}
