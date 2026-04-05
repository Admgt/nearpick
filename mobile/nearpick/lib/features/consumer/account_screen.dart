import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../ui/app_chrome.dart';
import 'consumer_navigation.dart';
import 'favorites_screen.dart';
import 'location_catalog.dart';
import 'location_preferences.dart';
import 'my_reservations_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  List<String> _selectedCategories = [];
  bool _loading = true;
  bool _savingCategories = false;
  bool _savingLocation = false;
  bool _fetchingLocation = false;
  ConsumerLocationMode _locationMode = ConsumerLocationMode.exact;
  String? _selectedCityId;
  double _preferredRadiusKm = LocationPreferences.defaultPreferredRadiusKm;
  String _email = '';
  String _displayName = '';
  String? _categoriesMessage;
  String? _locationMessage;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();
    final locationPreferences = LocationPreferences.fromUserData(data);
    final homeLocation = locationPreferences.homeLocation;
    if (homeLocation != null) {
      _latCtrl.text = homeLocation.latitude.toStringAsFixed(6);
      _lngCtrl.text = homeLocation.longitude.toStringAsFixed(6);
    }

    if (!mounted) return;
    setState(() {
      _selectedCategories = List<String>.from(
        data?['favoriteCategories'] ?? const <String>[],
      );
      _email = (data?['email'] as String?)?.trim() ?? (user.email ?? '');
      _displayName =
          (data?['displayName'] as String?)?.trim() ?? user.displayName ?? '';
      _preferredRadiusKm = locationPreferences.preferredRadiusKm;
      _locationMode = locationPreferences.locationMode;
      _selectedCityId = locationPreferences.selectedCity?.id;
      _loading = false;
    });
  }

  void _openTopDestination(ConsumerTopDestination destination) {
    switch (destination) {
      case ConsumerTopDestination.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case ConsumerTopDestination.reservations:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
        );
      case ConsumerTopDestination.favorites:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
      case ConsumerTopDestination.account:
        return;
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationMessage = null;
      _locationError = null;
    });

    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
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
          'A pontos hely nincs engedelyezve. Kapcsold be a pontos helyet a Beallitasokban.',
        );
      } else if (kIsWeb) {
        _showSnackBar(
          'A bongeszoben a helyhozzaferes le van tiltva. Engedelyezd a cimsor melletti beallitasoknal.',
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

  Future<void> _saveCategories() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _savingCategories = true;
      _categoriesMessage = null;
    });

    try {
      await _db.collection('users').doc(user.uid).set({
        'favoriteCategories': _selectedCategories,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _savingCategories = false;
        _categoriesMessage = 'Kedvenc kategoriak mentve.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingCategories = false;
        _categoriesMessage = e.toString();
      });
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    GeoPoint? location;
    PredefinedCity? selectedCity;
    if (_locationMode == ConsumerLocationMode.exact) {
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());
      location = GeoPoint(lat, lng);
    } else {
      selectedCity = predefinedCityById(_selectedCityId);
      if (selectedCity == null) {
        setState(() => _locationError = 'Valassz egy varost a listabol.');
        return;
      }
      location = selectedCity.center;
    }

    setState(() {
      _savingLocation = true;
      _locationMessage = null;
      _locationError = null;
    });

    try {
      await _db.collection('users').doc(user.uid).set({
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
      if (!mounted) return;
      setState(() {
        _savingLocation = false;
        _locationMessage = 'Hely beallitasai mentve.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  Widget _buildInfoCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bejelentkezett fiok',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: const Text('Felhasznalonev'),
            subtitle: Text(
              _displayName.isEmpty ? 'Nincs megadva' : _displayName,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alternate_email_outlined),
            title: const Text('Email'),
            subtitle: Text(_email.isEmpty ? 'Nincs megadva' : _email),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return SurfaceCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hely beallitasa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                  _locationMessage = null;
                  _locationError = null;
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
                  if (_locationMode != ConsumerLocationMode.exact) {
                    return null;
                  }
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  if (_locationMode != ConsumerLocationMode.exact) {
                    return null;
                  }
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
                    _locationMessage = null;
                    _locationError = null;
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
              const Text(
                'Varos modban a rendszer a kivalasztott telepules kozeppontjaval szamol, ezert a tavolsag csak kozelito ertek lesz.',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Ajanlott keresesi sugar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
              'Jelenlegi sugar: ${LocationPreferences.radiusLabel(_preferredRadiusKm)}. Az app ezt veszi alapul a kozeledben levo ajanlatok erositesenel es a terkepezesnel.',
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 12),
              Text(_locationError!, style: const TextStyle(color: Colors.red)),
            ],
            if (_locationMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _locationMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingLocation ? null : _saveLocation,
                child: _savingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Hely mentese'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erdeklodesi kategoriak',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Milyen termekek erdekelnek leginkabb?'),
          const SizedBox(height: 12),
          ..._allCategories.map((category) {
            final selected = _selectedCategories.contains(category);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category),
              value: selected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                  _categoriesMessage = null;
                });
              },
            );
          }),
          if (_categoriesMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _categoriesMessage!,
              style: TextStyle(
                color: _categoriesMessage!.startsWith('Kedvenc')
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingCategories ? null : _saveCategories,
              child: _savingCategories
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kategoriak mentese'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return SurfaceCard(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await AuthService().logout();
            if (!mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Kijelentkezes'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiokom'),
        actions: buildConsumerAppBarActions(
          context,
          current: ConsumerTopDestination.account,
          onSelected: _openTopDestination,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NearPickBackground(
              maxWidth: 840,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildCategoriesCard(),
                    const SizedBox(height: 16),
                    _buildLogoutCard(),
                  ],
                ),
              ),
            ),
    );
  }
}

const List<String> _allCategories = [
  'Peksutemeny',
  'Tejtermek',
  'Zoldseg / gyumolcs',
  'Keszetel',
  'Egyeb',
];
