abstract class BaseRule<T> {
  final String code;

  /// Optional inline message; when set, skips i18n for this rule's errors.
  final String? message;

  const BaseRule({required this.code, this.message});

  bool check(T value);
}
