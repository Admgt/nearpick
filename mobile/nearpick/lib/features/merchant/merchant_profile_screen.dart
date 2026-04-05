import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../ui/app_chrome.dart';
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

  bool _loading = true;
  String _displayName = '';
  String _email = '';
  String _companyName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
                    _buildLogoutCard(),
                  ],
                ),
              ),
            ),
    );
  }
}
