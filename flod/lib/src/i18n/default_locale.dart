import 'package:flod/src/i18n/errors/errors_codes.dart';

/// Built-in English locale used when no custom [FlodLocaleCompiler] is provided.
abstract final class FlodDefaultLocale {
  static String compile(String code, Map<String, dynamic> params) {
    switch (code) {
      case FlodErrorCodes.required:
        return 'This field is required.';
      case FlodErrorCodes.invalidType:
        return 'Expected type ${params['expected']}, but got ${params['actual']}.';
      case FlodErrorCodes.transformError:
        return 'Transformation failed.';
      case FlodErrorCodes.union:
        return 'Value does not match any allowed schema.';
      case FlodErrorCodes.invalidUnionType:
        return 'Union result has an invalid type.';
      case FlodErrorCodes.invalidLiteral:
        return 'Invalid literal value.';
      case FlodErrorCodes.objectStrict:
      case FlodErrorCodes.unknownKey:
        return 'Unknown key is not allowed: ${params['key']}.';
      case FlodErrorCodes.stringMin:
        return 'Must be at least ${params['limit']} characters long.';
      case FlodErrorCodes.stringMax:
        return 'Must be at most ${params['limit']} characters long.';
      case FlodErrorCodes.stringFixedLength:
        return 'Must be exactly ${params['limit']} characters long.';
      case FlodErrorCodes.stringEmail:
        return 'Invalid email address format.';
      case FlodErrorCodes.stringUrl:
        return 'Invalid URL format.';
      case FlodErrorCodes.stringUuid:
        return 'Invalid UUID format.';
      case FlodErrorCodes.stringPhoneNumber:
        return 'Invalid phone number format.';
      case FlodErrorCodes.stringRegex:
        return 'Invalid format.';
      case FlodErrorCodes.stringCreditCard:
        return 'Invalid credit card number.';
      case FlodErrorCodes.stringCvv:
        return 'Invalid CVV.';
      case FlodErrorCodes.stringMinUppercase:
        return 'Requires at least ${params['limit']} uppercase letters.';
      case FlodErrorCodes.stringMinNumbers:
        return 'Requires at least ${params['limit']} numbers.';
      case FlodErrorCodes.stringMinSymbols:
        return 'Requires at least ${params['limit']} special symbols.';
      case FlodErrorCodes.numberMin:
        return 'Value must be greater than or equal to ${params['limit']}.';
      case FlodErrorCodes.numberMax:
        return 'Value must be less than or equal to ${params['limit']}.';
      case FlodErrorCodes.numberPositive:
        return 'Value must be positive.';
      case FlodErrorCodes.numberNegative:
        return 'Value must be negative.';
      case FlodErrorCodes.numberNonPositive:
        return 'Value must be non-positive.';
      case FlodErrorCodes.numberNonNegative:
        return 'Value must be non-negative.';
      case FlodErrorCodes.numberMultipleOf:
        return 'Value must be a multiple of ${params['limit']}.';
      case FlodErrorCodes.invalidNumber:
        return 'Invalid number.';
      case FlodErrorCodes.listMinItems:
        return 'List must contain at least ${params['limit']} items.';
      case FlodErrorCodes.listMaxItems:
        return 'List must contain at most ${params['limit']} items.';
      case FlodErrorCodes.listUniqueItems:
        return 'All list items must be unique.';
      case FlodErrorCodes.refineException:
        return 'Custom refine check failed.';
      case FlodErrorCodes.asyncParseRequired:
        return 'This schema requires safeParseAsync() or parseAsync().';
      case FlodErrorCodes.guardInvalidJson:
        return 'Invalid JSON payload.';
      case FlodErrorCodes.guardMaxDepth:
        return 'JSON exceeds maximum nesting depth of ${params['limit']}.';
      case FlodErrorCodes.guardMaxKeys:
        return 'JSON exceeds maximum key count of ${params['limit']}.';
      case FlodErrorCodes.guardMaxStringLength:
        return 'String exceeds maximum length of ${params['limit']}.';
      case FlodErrorCodes.guardMaxArrayLength:
        return 'Array exceeds maximum length of ${params['limit']}.';
      case FlodErrorCodes.guardPrototypeKey:
        return 'Blocked unsafe key: ${params['key']}.';
      case FlodErrorCodes.guardInvalidKeyType:
        return 'Object key must be a string, got ${params['actual']}.';
      case FlodErrorCodes.guardUnsupportedType:
        return 'Unsupported JSON value type: ${params['actual']}.';
      default:
        return 'Invalid value.';
    }
  }
}
