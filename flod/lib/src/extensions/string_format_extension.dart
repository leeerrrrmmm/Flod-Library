// import 'package:flod/src/rules/string/regex_rule.dart';
// import 'package:flod/src/validators/string_validator.dart';

// /// Расширения для [StringValidator], добавляющие доменную логику.
// /// Все методы требуют явного указания [message] и [code] для поддержки i18n.
// extension StringFormatExtensions on StringValidator {
//   /// 20.5 Custom Interface: Базовый метод для любой пользовательской регулярки
//   StringValidator regex(RegExp pattern, String message, String code) {
//     return StringValidator([
//       ...rules,
//       RegexRule(pattern, message: message, code: code),
//     ]);
//   }

//   /// 20.2 Email Validator
//   StringValidator email(String message, String code) => regex(
//     RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
//     message,
//     code,
//   );

//   /// 20.6 HTML5 Email Validation
//   StringValidator html5Email(String message, String code) => regex(
//     RegExp(
//       r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$''',
//     ),
//     message,
//     code,
//   );

//   /// 20.4 Specialized: URL Validator
//   StringValidator url(String message, String code) =>
//       regex(RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$'), message, code);

//   StringValidator phoneNumber(String message, String code) =>
//       regex(RegExp(r'^\+?[1-9]\d{6,14}$'), message, code);

//   // Теперь любая строка может стать "специальной" через цепочку
//   StringValidator customPattern(RegExp pattern, String message, String code) =>
//       regex(pattern, message, code);

//   /// 20.4 Specialized: UUID v4
//   StringValidator uuid(String message, String code) => regex(
//     RegExp(
//       r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
//     ),
//     message,
//     code,
//   );

//   /// 20.3 Password Policies: Минимум N заглавных букв
//   StringValidator minUppercase(int n, String message, String code) =>
//       regex(RegExp('^(.*?[A-Z]){$n,}'), message, code);

//   /// 20.3 Password Policies: Минимум N цифр
//   StringValidator minNumbers(int n, String message, String code) =>
//       regex(RegExp('^(.*?[0-9]){$n,}'), message, code);

//   /// 20.3 Password Policies: Минимум N спецсимволов
//   StringValidator minSymbols(int n, String message, String code) => regex(
//     RegExp(
//       r'^(.*?[!@#\$&*~]){'
//       '$n'
//       r',}',
//     ),
//     message,
//     code,
//   );
// }
