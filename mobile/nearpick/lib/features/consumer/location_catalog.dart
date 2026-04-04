import 'package:cloud_firestore/cloud_firestore.dart';

class PredefinedCity {
  final String id;
  final String name;
  final String countryName;
  final GeoPoint center;

  const PredefinedCity({
    required this.id,
    required this.name,
    required this.countryName,
    required this.center,
  });

  String get displayLabel => '$name ($countryName)';
}

const List<PredefinedCity> predefinedConsumerCities = [
  PredefinedCity(
    id: 'budapest',
    name: 'Budapest',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.497913, 19.040236),
  ),
  PredefinedCity(
    id: 'debrecen',
    name: 'Debrecen',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.531605, 21.627312),
  ),
  PredefinedCity(
    id: 'szeged',
    name: 'Szeged',
    countryName: 'Magyarorszag',
    center: GeoPoint(46.253010, 20.141426),
  ),
  PredefinedCity(
    id: 'pecs',
    name: 'Pecs',
    countryName: 'Magyarorszag',
    center: GeoPoint(46.072735, 18.232266),
  ),
  PredefinedCity(
    id: 'gyor',
    name: 'Gyor',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.687457, 17.650398),
  ),
  PredefinedCity(
    id: 'miskolc',
    name: 'Miskolc',
    countryName: 'Magyarorszag',
    center: GeoPoint(48.103064, 20.778438),
  ),
  PredefinedCity(
    id: 'kecskemet',
    name: 'Kecskemet',
    countryName: 'Magyarorszag',
    center: GeoPoint(46.906176, 19.691686),
  ),
  PredefinedCity(
    id: 'nyiregyhaza',
    name: 'Nyiregyhaza',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.949532, 21.724405),
  ),
  PredefinedCity(
    id: 'szekesfehervar',
    name: 'Szekesfehervar',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.186026, 18.422135),
  ),
  PredefinedCity(
    id: 'szombathely',
    name: 'Szombathely',
    countryName: 'Magyarorszag',
    center: GeoPoint(47.230685, 16.621844),
  ),
  PredefinedCity(
    id: 'magyarkanizsa',
    name: 'Magyarkanizsa',
    countryName: 'Szerbia',
    center: GeoPoint(46.066944, 20.048611),
  ),
  PredefinedCity(
    id: 'zenta',
    name: 'Zenta',
    countryName: 'Szerbia',
    center: GeoPoint(45.927500, 20.074444),
  ),
];

PredefinedCity? predefinedCityById(String? id) {
  if (id == null || id.trim().isEmpty) {
    return null;
  }

  for (final city in predefinedConsumerCities) {
    if (city.id == id.trim()) {
      return city;
    }
  }

  return null;
}
