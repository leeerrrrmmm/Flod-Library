/// Canonical i18n error codes emitted by Flod validators.
/// Use these codes in custom [FlodLocaleCompiler] implementations.
abstract final class FlodErrorCodes {
  // Infrastructure
  static const String required = 'required';
  static const String invalidType = 'invalid_type';
  static const String transformError = 'transform.error';

  // Union
  static const String union = 'union';
  static const String invalidUnionType = 'union.invalid_type';

  // Literal
  static const String invalidLiteral = 'invalid_literal';

  // Objects / Maps
  static const String objectStrict = 'object.strict';
  static const String unknownKey = 'unknown_key';

  // Strings
  static const String stringMin = 'string.min';
  static const String stringMax = 'string.max';
  static const String stringFixedLength = 'string.fixed_length';
  static const String stringEmail = 'string.email';
  static const String stringUrl = 'string.url';
  static const String stringUuid = 'string.uuid';
  static const String stringPhoneNumber = 'string.phone_number';
  static const String stringRegex = 'string.regex';
  static const String stringCreditCard = 'string.credit_card';
  static const String stringCvv = 'string.cvv';
  static const String stringMinUppercase = 'string.min_uppercase';
  static const String stringMinNumbers = 'string.min_numbers';
  static const String stringMinSymbols = 'string.min_symbols';

  // Numbers
  static const String numberMin = 'number.min';
  static const String numberMax = 'number.max';
  static const String numberPositive = 'number.positive';
  static const String numberNegative = 'number.negative';
  static const String numberNonPositive = 'number.non_positive';
  static const String numberNonNegative = 'number.non_negative';
  static const String numberMultipleOf = 'number.multiple_of';
  static const String invalidNumber = 'invalid_number';

  // Lists
  static const String listMinItems = 'list.min_items';
  static const String listMaxItems = 'list.max_items';
  static const String listUniqueItems = 'list.unique_items';
}
