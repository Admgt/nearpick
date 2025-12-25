import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  final ProductService _productService = ProductService();

  List<String> _favoriteCategories = [];

  String _selectedCategory = _allCategories.first;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      _favoriteCategories =
          List<String>.from(doc.data()?['favoriteCategories'] ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NearPick - Ajánlatok a közelben'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
            icon: const Icon(Icons.favorite),
            tooltip: 'Kedvencek',
          ),
          IconButton(
            onPressed: () => AuthService().logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Kijelentkezés',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Kategória:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _allCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productService.activeProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Hiba a termékek betöltésekor: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final quantity = data['quantity'] as int? ?? 0;
                  if (quantity <= 0) return false;

                  if (_selectedCategory == _allCategories.first) {
                    return true;
                  }

                  final category = data['category'] as String? ?? '';
                  return category == _selectedCategory;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('Jelenleg nincs elérhető ajánlat ebben a kategóriában.'),
                  );
                }

                filteredDocs.sort((a, b) {
                  final aCat = a['category'];
                  final bCat = b['category'];

                  final aFav = _favoriteCategories.contains(aCat);
                  final bFav = _favoriteCategories.contains(bCat);

                  if (aFav && !bFav) return -1;
                  if (!aFav && bFav) return 1;
                  return 0;
                });

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    final name =
                        data['name'] as String? ?? 'Névtelen termék';
                    final category =
                        data['category'] as String? ?? 'Ismeretlen kategória';
                    final discounted = data['discountedPrice'] as int? ?? 0;
                    final original = data['originalPrice'] as int? ?? 0;
                    final quantity = data['quantity'] as int? ?? 0;
                    final expiresAt =
                        (data['expiresAt'] as Timestamp?)?.toDate();

                    String expiresText = 'Ismeretlen lejárat';
                    if (expiresAt != null) {
                      final now = DateTime.now();
                      final diff = expiresAt.difference(now);

                      if (diff.inMinutes <= 0) {
                        expiresText = 'Hamarosan lejár';
                      } else if (diff.inHours < 1) {
                        expiresText =
                            'Lejár ${diff.inMinutes} percen belül';
                      } else if (diff.inHours < 24) {
                        expiresText =
                            'Lejár ${diff.inHours} órán belül';
                      } else {
                        expiresText =
                            'Lejár: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
                      }
                    }

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                        '$category\n$expiresText • Elérhető: $quantity db',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$discounted Ft',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (original > discounted)
                            Text(
                              '$original Ft',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        final doc = filteredDocs[index];
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: doc.id,
                              data: doc.data(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _allCategories = [
  'Összes kategória',
  'Péksütemény',
  'Tejtermék',
  'Zöldség / gyümölcs',
  'Készétel',
  'Egyéb',
];
