import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import 'location_catalog.dart';
import 'location_preferences.dart';
import '../../services/location_service.dart';
import '../../ui/app_chrome.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  ConsumerLocationMode _locationMode = ConsumerLocationMode.exact;
  String? _selectedCityId;
  bool _loading = false;
  bool _fetchingLocation = false;
  double _preferredRadiusKm = LocationPreferences.defaultPreferredRadiusKm;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingLocation();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final preferences = LocationPreferences.fromUserData(doc.data());
    if (mounted) {
      setState(() {
        _preferredRadiusKm = preferences.preferredRadiusKm;
        _locationMode = preferences.locationMode;
        _selectedCityId = preferences.selectedCity?.id;
      });
    } else {
      _preferredRadiusKm = preferences.preferredRadiusKm;
      _locationMode = preferences.locationMode;
      _selectedCityId = preferences.selectedCity?.id;
    }

    final location = preferences.homeLocation;
    if (location == null) return;

    _latCtrl.text = location.latitude.toStringAsFixed(6);
    _lngCtrl.text = location.longitude.toStringAsFixed(6);
    if (mounted) {
      setState(() {});
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _fetchingLocation = true;
      _message = null;
      _error = null;
    });

    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _locationMode = ConsumerLocationMode.exact;
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
      _showSnackBar('Hely meghatarozva.');
    } on LocationServiceException catch (e) {
      if (e.code == LocationServiceError.serviceDisabled) {
        _showSnackBar('A helymeghatarozas ki van kapcsolva.');
      } else if (e.code == LocationServiceError.reducedAccuracy) {
        _showSnackBar(
          'A pontos hely nincs engedelyezve. Kapcsold be a pontos helyet a '
          'Beallitasokban.',
        );
      } else if (kIsWeb) {
        _showSnackBar(
          'A bongeszoben a helyhozzaferes le van tiltva. Engedelyezd a cimsor '
          'melletti beallitasoknal.',
        );
      } else {
        _showSnackBar('Hozzaferes megtagadva. Engedelyezd a Beallitasokban.');
      }
    } catch (_) {
      _showSnackBar('Nem sikerult meghatarozni a helyet.');
    } finally {
      if (mounted) {
        setState(() => _fetchingLocation = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Nincs bejelentkezett felhasznalo.');
      return;
    }

    GeoPoint? location;
    PredefinedCity? selectedCity;
    if (_locationMode == ConsumerLocationMode.exact) {
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());
      location = GeoPoint(lat, lng);
    } else {
      selectedCity = predefinedCityById(_selectedCityId);
      if (selectedCity == null) {
        setState(() => _error = 'Valassz egy varost a listabol.');
        return;
      }
      location = selectedCity.center;
    }

    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'homeLocation': location,
        'homeLocationMode': _locationMode == ConsumerLocationMode.city
            ? 'city'
            : 'exact',
        'homeLocationCityId': _locationMode == ConsumerLocationMode.city
            ? selectedCity!.id
            : FieldValue.delete(),
        'preferredRadiusKm': LocationPreferences.normalizePreferredRadiusKm(
          _preferredRadiusKm,
        ),
      }, SetOptions(merge: true));
      setState(() => _message = 'Mentve.');
    } catch (e) {
      setState(() => _error = appErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hely beallitasa')),
      body: NearPickBackground(
        maxWidth: 720,
        child: SurfaceCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SegmentedButton<ConsumerLocationMode>(
                  segments: const [
                    ButtonSegment<ConsumerLocationMode>(
                      value: ConsumerLocationMode.exact,
                      icon: Icon(Icons.my_location_outlined),
                      label: Text('Pontos hely'),
                    ),
                    ButtonSegment<ConsumerLocationMode>(
                      value: ConsumerLocationMode.city,
                      icon: Icon(Icons.location_city_outlined),
                      label: Text('Csak varos'),
                    ),
                  ],
                  selected: {_locationMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _locationMode = selection.first;
                      _message = null;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_locationMode == ConsumerLocationMode.exact) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fetchingLocation ? null : _fetchLocation,
                      icon: _fetchingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Aktualis hely meghatarozasa'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kotelezo mezo';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < -90 || parsed > 90) {
                        return 'Adj meg -90 es 90 kozotti erteket';
                      }
                      return null;
                    },
                  ),
                ],
                if (_locationMode == ConsumerLocationMode.exact) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kotelezo mezo';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < -180 || parsed > 180) {
                        return 'Adj meg -180 es 180 kozotti erteket';
                      }
                      return null;
                    },
                  ),
                ],
                if (_locationMode == ConsumerLocationMode.city) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('consumer_city_${_selectedCityId ?? 'none'}'),
                    initialValue: _selectedCityId,
                    decoration: const InputDecoration(labelText: 'Varos'),
                    items: predefinedConsumerCities
                        .map(
                          (city) => DropdownMenuItem<String>(
                            value: city.id,
                            child: Text(city.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                        _message = null;
                        _error = null;
                      });
                    },
                    validator: (value) {
                      if (_locationMode != ConsumerLocationMode.city) {
                        return null;
                      }
                      if (value == null || predefinedCityById(value) == null) {
                        return 'Valassz egy varost';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Varos modban a rendszer a kivalasztott telepules '
                      'kozeppontjaval szamol, ezert a tavolsag csak kozelito '
                      'ertek lesz.',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajanlott keresesi sugar',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 6),
                Slider(
                  value: _preferredRadiusKm,
                  min: LocationPreferences.minPreferredRadiusKm,
                  max: LocationPreferences.maxPreferredRadiusKm,
                  divisions: 19,
                  label: LocationPreferences.radiusLabel(_preferredRadiusKm),
                  onChanged: (value) {
                    setState(() {
                      _preferredRadiusKm = value;
                    });
                  },
                ),
                Text(
                  'Jelenlegi sugar: ${LocationPreferences.radiusLabel(_preferredRadiusKm)}. '
                  'Az app ezt veszi alapul a kozeledben levo ajanlatok '
                  'erositesenel es a terkepezesnel.',
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_message != null)
                  Text(_message!, style: const TextStyle(color: Colors.green)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Mentes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
