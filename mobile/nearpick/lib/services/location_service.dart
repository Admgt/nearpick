import 'package:geolocator/geolocator.dart';

enum LocationServiceError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  reducedAccuracy,
}

class LocationServiceException implements Exception {
  LocationServiceException(this.code);

  final LocationServiceError code;
}

class LocationService {
  static Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationServiceException(LocationServiceError.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(LocationServiceError.permissionDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        LocationServiceError.permissionDeniedForever,
      );
    }

    try {
      final accuracyStatus = await Geolocator.getLocationAccuracy();
      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        throw LocationServiceException(LocationServiceError.reducedAccuracy);
      }
    } catch (_) {
      // If accuracy status is unavailable on this platform, continue.
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }
}
