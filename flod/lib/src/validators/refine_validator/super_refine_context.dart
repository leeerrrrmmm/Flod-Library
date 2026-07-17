import 'package:flod/flod.dart';

/// Context passed to [SuperRefineValidator] / [AsyncSuperRefineValidator] callbacks.
/// Allows attaching multiple targeted issues (Zod `.superRefine()` semantics).
final class SuperRefineContext {
  final FlodPath basePath;
  final bool isSecret;
  final dynamic value;
  final List<FlodError> _issues = [];

  SuperRefineContext({
    required this.basePath,
    required this.isSecret,
    required this.value,
  });

  /// Adds a validation issue, optionally scoped to a nested [path] segment list.
  void addIssue({
    List<String>? path,
    required String code,
    String? message,
    Map<String, dynamic>? params,
  }) {
    final targetPath = path != null
        ? FlodPath([...basePath.segments, ...path])
        : basePath;

    _issues.add(
      FlodError(
        path: targetPath,
        code: code,
        params: {'value': isSecret ? null : value, ...?params},
        message: message,
        value: isSecret ? null : value,
        isSecret: isSecret,
      ),
    );
  }

  List<FlodError> get issues => List.unmodifiable(_issues);

  bool get hasIssues => _issues.isNotEmpty;
}
