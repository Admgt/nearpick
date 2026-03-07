import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/services/pickup_code_generator.dart';

void main() {
  test('RandomPickupCodeGenerator generates codes with expected length', () {
    final generator = RandomPickupCodeGenerator(random: Random(1));
    final code = generator.generate(6);

    expect(code, hasLength(6));
  });

  test('RandomPickupCodeGenerator only uses allowed characters', () {
    final generator = RandomPickupCodeGenerator(random: Random(2));
    final code = generator.generate(32);

    expect(code, matches(RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$')));
  });
}
