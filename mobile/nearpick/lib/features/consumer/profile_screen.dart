import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<String> _selectedCategories = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _selectedCategories =
          List<String>.from(data?['favoriteCategories'] ?? []);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'favoriteCategories': _selectedCategories,
    });

    setState(() {
      _message = 'Mentve!';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil – Kedvenc kategóriák')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milyen termékek érdekelnek leginkább?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: _allCategories.map((category) {
                  final selected = _selectedCategories.contains(category);
                  return CheckboxListTile(
                    title: Text(category),
                    value: selected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.green)),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Mentés'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _allCategories = [
  'Péksütemény',
  'Tejtermék',
  'Zöldség / gyümölcs',
  'Készétel',
  'Egyéb',
];
