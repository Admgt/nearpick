class ParsedPickupToken {
  final String? reservationId;
  final String pickupCode;

  const ParsedPickupToken({
    required this.reservationId,
    required this.pickupCode,
  });
}

ParsedPickupToken parsePickupToken(String rawInput) {
  final value = rawInput.trim();
  if (value.isEmpty) {
    throw const FormatException('Ures atveteli kod.');
  }

  if (!value.startsWith('NEARPICK:')) {
    return ParsedPickupToken(reservationId: null, pickupCode: value);
  }

  final parts = value.split(':');
  if (parts.length != 3 || parts[1].isEmpty || parts[2].isEmpty) {
    throw const FormatException('Ervenytelen QR token.');
  }

  return ParsedPickupToken(reservationId: parts[1], pickupCode: parts[2]);
}
