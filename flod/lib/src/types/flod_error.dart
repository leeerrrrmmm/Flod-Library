import 'package:flod/flod.dart';

class FlodError {
  /// Путь к полю, где произошла ошибка
  final FlodPath path;

  /// Строковый i18n-код ошибки (например, 'string.min')
  final String code;

  /// Динамические параметры правила (например, {'limit': 5})
  final Map<String, dynamic> params;

  /// Сырое значение, которое не прошло валидацию (внутреннее поле)
  final dynamic _rawValue;

  /// Флаг конфиденциальности данных
  final bool isSecret;

  const FlodError({
    required this.path,
    required this.code,
    required this.params,
    required dynamic value,
    this.isSecret = false,
  }) : _rawValue = value;

  /// Безопасный геттер для значения.
  /// Если поле помечено как секретное, оно жестко маскируется для внешнего мира.
  dynamic get value => isSecret ? '[HIDDEN]' : _rawValue;

  /// Хелпер для получения реального значения внутри библиотеки
  /// (если оно вдруг понадобится для внутренних не-лог вычислений)
  dynamic get rawValue => _rawValue;

  /// Сериализация в Map с автоматическим сокрытием приватных данных
  Map<String, dynamic> toMap() {
    return {
      'path': path
          .toString(), // Или path.segments, смотря как устроен твой FlodPath
      'code': code,
      'params': params,
      'value': value, // Использует безопасный геттер с маскированием!
    };
  }

  @override
  String toString() {
    final pathStr = path.toString().isEmpty ? '_root_' : path.toString();
    // Полностью исключаем утечку сырого значения, если isSecret = true
    final displayValue = value;
    return "FlodError(path: '$pathStr', code: '$code', params: $params, value: $displayValue)";
  }
}
