String formatDate(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

String formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime value) {
  return '${formatDate(value)} ${formatTime(value)}';
}

String formatPickupWindow({
  required DateTime? pickupStartAt,
  required DateTime? pickupEndAt,
  String emptyLabel = 'Nincs megadva',
}) {
  if (pickupStartAt == null || pickupEndAt == null) {
    return emptyLabel;
  }

  final sameDay =
      pickupStartAt.year == pickupEndAt.year &&
      pickupStartAt.month == pickupEndAt.month &&
      pickupStartAt.day == pickupEndAt.day;
  if (sameDay) {
    return '${formatDate(pickupStartAt)} ${formatTime(pickupStartAt)}-${formatTime(pickupEndAt)}';
  }

  return '${formatDateTime(pickupStartAt)} - ${formatDateTime(pickupEndAt)}';
}
