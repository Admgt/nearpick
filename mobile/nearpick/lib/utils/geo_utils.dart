import 'dart:math' as math;

class GeoUtils {
  static const double _earthRadiusKm = 6371.0;
  static const double _degToRadFactor = math.pi / 180.0;

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final lat1Rad = _degToRad(lat1);
    final lat2Rad = _degToRad(lat2);

    final sinHalfDLat = math.sin(dLat / 2);
    final sinHalfDLon = math.sin(dLon / 2);
    final a =
        sinHalfDLat * sinHalfDLat +
        sinHalfDLon * sinHalfDLon * math.cos(lat1Rad) * math.cos(lat2Rad);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * _degToRadFactor;
}
