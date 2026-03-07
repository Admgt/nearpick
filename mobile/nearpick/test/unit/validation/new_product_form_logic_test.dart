import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/merchant/new_product_form_logic.dart';

void main() {
  test(
    'parseOptionalLocation returns null when both coordinate fields are empty',
    () {
      expect(
        parseOptionalLocation(latitudeText: '', longitudeText: ''),
        isNull,
      );
    },
  );

  test('parseOptionalLocation throws when only one coordinate is provided', () {
    expect(
      () => parseOptionalLocation(latitudeText: '47.5', longitudeText: ''),
      throwsFormatException,
    );
  });

  test('parseOptionalLocation throws when coordinates are not numeric', () {
    expect(
      () => parseOptionalLocation(latitudeText: 'abc', longitudeText: '19.0'),
      throwsFormatException,
    );
  });

  test('parseOptionalLocation parses valid coordinates', () {
    expect(
      parseOptionalLocation(latitudeText: '47.5', longitudeText: '19.0'),
      const GeoPoint(47.5, 19.0),
    );
  });

  test('parsePositiveInt throws for zero or negative values', () {
    expect(
      () => parsePositiveInt('0', fieldLabel: 'A mennyiseg'),
      throwsFormatException,
    );
    expect(
      () => parsePositiveInt('-2', fieldLabel: 'A mennyiseg'),
      throwsFormatException,
    );
  });
}
