abstract class BaseRule<T> {
  final String message;
  final String code;

  BaseRule({required this.message, required this.code});

  bool check(T value);
}
