import 'dart:math';

abstract class PickupCodeGenerator {
  String generate(int length);
}

class RandomPickupCodeGenerator implements PickupCodeGenerator {
  static const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  final Random _random;

  RandomPickupCodeGenerator({Random? random})
    : _random = random ?? Random.secure();

  @override
  String generate(int length) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'Must be positive.');
    }
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}
