import 'package:flod/flod.dart';
import 'package:flod/src/extensions/string_format_extension.dart';
import 'package:flod/src/res/validation_result.dart';

void main() {
  // 1. Создаем схему валидации элементов (Email)
  final emailSchema = Flod.string().email(
    'Некорректный email',
    'invalid_email',
  );

  // 2. Создаем схему списка (List)
  final emailListValidator = Flod.list(
    schema: emailSchema,
  ).minItems(1).maxItems(3).unique();
  // 3. Тестируем
  final data = ['test@mail.com', 'user@domain.com', 'test@mail.com'];

  final result = emailListValidator.validate(data);

  if (result is FlodFailure) {
    for (var error in result.errors) {
      // Выведет ошибку: [2] Expected unique items
      print('[${error.path}] ${error.code}: ${error.message}');
    }
  } else {
    print('Список валиден!');
  }
}
