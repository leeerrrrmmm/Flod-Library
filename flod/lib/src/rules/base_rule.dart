abstract class BaseRule<T> {
  final String code;

  const BaseRule({required this.code});

  bool check(T value);
}
