import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../ui/app_chrome.dart';
import '../../widgets/profile_field_edit_dialog.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_home_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_reservations_screen.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final _locationFormKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _loading = true;
  bool _savingDisplayName = false;
  bool _savingCompanyName = false;
  bool _savingLocation = false;
  bool _fetchingLocation = false;
  String _displayName = '';
  String _email = '';
  String _companyName = '';
  String? _locationMessage;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (!mounted) return;
    setState(() {
      _displayName =
          (data?['displayName'] as String?)?.trim() ?? user.displayName ?? '';
      _email = (data?['email'] as String?)?.trim() ?? (user.email ?? '');
      _companyName = (data?['companyName'] as String?)?.trim() ?? '';
      final companyLocation = data?['companyLocation'] as GeoPoint?;
      _latCtrl.text = companyLocation?.latitude.toStringAsFixed(6) ?? '';
      _lngCtrl.text = companyLocation?.longitude.toStringAsFixed(6) ?? '';
      _loading = false;
    });
  }

  void _openTopDestination(MerchantTopDestination destination) {
    switch (destination) {
      case MerchantTopDestination.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantHomeScreen()),
        );
      case MerchantTopDestination.reservations:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantReservationsScreen()),
        );
      case MerchantTopDestination.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
        );
      case MerchantTopDestination.profile:
        return;
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editDisplayName() async {
    final updatedValue = await showProfileFieldEditDialog(
      context,
      title: 'Felhasznalonev szerkesztese',
      label: 'Felhasznalonev',
      initialValue: _displayName,
    );
    if (updatedValue == null || updatedValue == _displayName) {
      return;
    }

    setState(() => _savingDisplayName = true);
    try {
      await _authService.updateCurrentUserProfile(displayName: updatedValue);
      if (!mounted) return;
      setState(() {
        _displayName = updatedValue;
        _savingDisplayName = false;
      });
      _showSnackBar('Felhasznalonev mentve.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingDisplayName = false);
      _showSnackBar('A felhasznalonev mentese nem sikerult: $e');
    }
  }

  Future<void> _editCompanyName() async {
    final updatedValue = await showProfileFieldEditDialog(
      context,
      title: 'Cegnev szerkesztese',
      label: 'Ceg neve',
      initialValue: _companyName,
    );
    if (updatedValue == null || updatedValue == _companyName) {
      return;
    }

    setState(() => _savingCompanyName = true);
    try {
      await _authService.updateCurrentUserProfile(companyName: updatedValue);
      if (!mounted) return;
      setState(() {
        _companyName = updatedValue;
        _savingCompanyName = false;
      });
      _showSnackBar('Cegnev mentve.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingCompanyName = false);
      _showSnackBar('A cegnev mentese nem sikerult: $e');
    }
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

  Future<void> _saveLocation() async {
    if (!_locationFormKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _locationError = 'Nincs bejelentkezett felhasznalo.');
      return;
    }

    setState(() {
      _savingLocation = true;
      _locationMessage = null;
      _locationError = null;
    });

    try {
      final location = GeoPoint(
        double.parse(_latCtrl.text.trim()),
        double.parse(_lngCtrl.text.trim()),
      );
      await _authService.updateCurrentUserProfile(companyLocation: location);
      if (!mounted) return;
      setState(() {
        _savingLocation = false;
        _locationMessage = 'Ceg helye mentve.';
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
            'Kereskedo profil',
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
            trailing: _savingDisplayName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _editDisplayName,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Felhasznalonev modositasa',
                  ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alternate_email_outlined),
            title: const Text('Email'),
            subtitle: Text(_email.isEmpty ? 'Nincs megadva' : _email),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Ceg neve'),
            subtitle: Text(
              _companyName.isEmpty ? 'Nincs megadva' : _companyName,
            ),
            trailing: _savingCompanyName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _editCompanyName,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Cegnev modositasa',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return SurfaceCard(
      child: Form(
        key: _locationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hely beallitasa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Text(
              'Ez a hely automatikusan hozzaadodik az uj termekekhez.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_locationError != null)
              Text(
                _locationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_locationMessage != null)
              Text(
                _locationMessage!,
                style: const TextStyle(color: Colors.green),
              ),
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
                    : const Text('Mentes'),
              ),
            ),
          ],
        ),
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
        title: const Text('Profil'),
        actions: buildMerchantAppBarActions(
          context,
          current: MerchantTopDestination.profile,
          onSelected: _openTopDestination,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NearPickBackground(
              maxWidth: 760,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildLogoutCard(),
                  ],
                ),
              ),
            ),
    );
  }
}
