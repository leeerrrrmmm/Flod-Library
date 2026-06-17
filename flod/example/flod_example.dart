import 'package:flod/flod.dart';
import 'package:flod/src/types/path.dart';
import 'package:flod/src/validators/nullable_validator.dart';
import 'package:flod/src/validators/optional_validator.dart';
import 'package:flod/src/validators/validator.dart';

void main() {
  final testMin = Flod.string().min(
    3,
    'Value must be at least 3 characters long',
    'min_length',
  );
  final testMax = Flod.string().max(
    10,
    'Value must be at most 10 characters long',
    'max_length',
  );
  final testMinMax = Flod.string()
      .min(3, 'Value must be at least 3 characters long', 'min_length')
      .max(
        10,
        'Value must be between 3 and 10 characters long',
        'min_max_length',
      );

  final testObject = Flod.object({
    'name': Flod.string().min(
      5,
      'Name must be at least 3 characters long',
      'name_min_length',
    ),
    'bio': Flod.string().max(
      4,
      'BIO must be at most 4 characters long',
      'bio_max_length',
    ),
  });

  final safeRes = Flod.string()
      .min(
        3,
        'Value must be at least 3 characters long',
        'SAFE PARSE OF min_length',
      )
      .safeParse('1');

  final userSchema = Flod.object({
    'username': Flod.string().min(
      3,
      'UserName must be at least 3 chapters long',
      'username_min_length',
    ),
    'bio': Flod.string()
        .max(
          10,
          'BIO OPTIONAL must be at most 10 characters long',
          'bio_max_length',
        )
        .optional(),
    'website': Flod.string()
        .min(
          3,
          'Website NULLABLE must be at least 3 characters long',
          'website_min_length',
        )
        .nullable(),
  });

  final minIntValue = Flod.int().min(
    10,
    'Value must be greater than 10',
    'min_int_value',
  );
  final minDoubleValue = Flod.double().min(
    10.0,
    'Value must be greater than 10',
    'min_double_value',
  );

  final maxIntValue = Flod.int().max(
    10,
    'Value must be less than 10',
    'max_int_value',
  );
  final maxDoubleValue = Flod.double().max(
    10.0,
    'Value must be less than 10',
    'max_double_value',
  );

  // final parseRes = Flod.string()
  //     .min(3, 'Value must be at least 3 characters long', 'PARSE OF min_length')
  //     .parse('1');

  // ===============================================
  // Validation
  // ===============================================

  final minRes = testMin.validate('12');

  if (minRes.isFailure) {
    print(minRes.errors.first.path.toReadable());
    print(minRes.errors.first.code);
    print(minRes.errors.first.message);
  }

  final maxRes = testMax.validate('12345678901');

  if (maxRes.isFailure) {
    print(maxRes.errors.first.path.toReadable());
    print(maxRes.errors.first.code);
    print(maxRes.errors.first.message);
  }

  final minMaxRes = testMinMax.validate('12345678901');

  if (minMaxRes.isFailure) {
    print(minMaxRes.errors.first.path.toReadable());
    print(minMaxRes.errors.first.code);
    print(minMaxRes.errors.first.message);
  }

  final objectRes = testObject.validate({
    'name': 'John',
    'bio': 'I am a software engineer',
  });

  if (objectRes.isFailure) {
    print('\n${objectRes.errors[0].path.toReadable()}');
    print(objectRes.errors[0].code);
    print(objectRes.errors[0].message);
  }

  if (objectRes.isFailure) {
    print('\n${objectRes.errors[1].path.toReadable()}\n');
    print(objectRes.errors[1].code);
    print(objectRes.errors[1].message);
  }

  if (safeRes.success) {
    print('Data: ${safeRes.data?.toString()}');
  } else {
    for (final error in safeRes.errors!) {
      print('Ошибка: ${error.message} (код: ${error.code})');
    }
  }

  final data = {
    'username': 'lermmmmmm',
    // 'bio' : 'I am a software engineer',
    'website': null,
  };

  final optionalAndNullableResult = userSchema.safeParse(data);

  if (optionalAndNullableResult.success) {
    print('Data SUCCESSFULLY PARSED: ${optionalAndNullableResult.data}');
  } else {
    optionalAndNullableResult.errors?.forEach(
      (err) => print('Error: ${err.message} (code: ${err.code})'),
    );
  }

  final minIntValueRes = minIntValue.validate(9);
  final maxIntValueRes = maxIntValue.validate(11);

  final minDoubleValueRes = minDoubleValue.validate(9.0);
  final maxDoubleValueRes = maxDoubleValue.validate(11.0);

  if (minIntValueRes.isFailure) {
    print(minIntValueRes.errors.first.path.toReadable());
    print(minIntValueRes.errors.first.code);
    print(minIntValueRes.errors.first.message);

    print('====================================================');
  }

  if (maxIntValueRes.isFailure) {
    print(maxIntValueRes.errors.first.path.toReadable());
    print(maxIntValueRes.errors.first.code);
    print(maxIntValueRes.errors.first.message);

    print('====================================================');
  }

  if (minDoubleValueRes.isFailure) {
    print(minDoubleValueRes.errors.first.path.toReadable());
    print(minDoubleValueRes.errors.first.code);
    print(minDoubleValueRes.errors.first.message);

    print('====================================================');
  }

  if (maxDoubleValueRes.isFailure) {
    print(maxDoubleValueRes.errors.first.path.toReadable());
    print(maxDoubleValueRes.errors.first.code);
    print(maxDoubleValueRes.errors.first.message);

    print('====================================================');
  }
  print('====================================================');
}
