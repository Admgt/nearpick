import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';


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
              stream: _productService.myInterestsStream(),
              builder: (context, interestsSnap) {
                if (interestsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final interestDocs = interestsSnap.data?.docs ?? [];
                final interestedProductIds = <String>{
                  for (final d in interestDocs)
                    (d.data()['productId'] as String?) ?? ''
                }..remove('');

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                      if (_selectedCategory == _allCategories.first) return true;

                      final category = data['category'] as String? ?? '';
                      return category == _selectedCategory;
                    }).toList();

                    filteredDocs.sort((a, b) {
                      final aScore = _scoreProduct(a, interestedProductIds);
                      final bScore = _scoreProduct(b, interestedProductIds);

                      if (aScore != bScore) return bScore.compareTo(aScore);

                      final aExp = (a.data()['expiresAt'] as Timestamp?)?.toDate();
                      final bExp = (b.data()['expiresAt'] as Timestamp?)?.toDate();
                      if (aExp == null || bExp == null) return 0;
                      return aExp.compareTo(bExp);
                    });

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text('Jelenleg nincs elérhető ajánlat ebben a kategóriában.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data();

                        final name = data['name'] as String? ?? 'Névtelen termék';
                        final category = data['category'] as String? ?? 'Ismeretlen kategória';
                        final discounted = data['discountedPrice'] as int? ?? 0;
                        final original = data['originalPrice'] as int? ?? 0;
                        final quantity = data['quantity'] as int? ?? 0;
                        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                        final isInterested = interestedProductIds.contains(doc.id);

                        String expiresText = 'Ismeretlen lejárat';
                        if (expiresAt != null) {
                          final now = DateTime.now();
                          final diff = expiresAt.difference(now);
                          if (diff.inMinutes <= 0) {
                            expiresText = 'Hamarosan lejár';
                          } else if (diff.inHours < 1) {
                            expiresText = 'Lejár ${diff.inMinutes} percen belül';
                          } else if (diff.inHours < 24) {
                            expiresText = 'Lejár ${diff.inHours} órán belül';
                          } else {
                            expiresText =
                                'Lejár: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
                          }
                        }

                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (isInterested) const Icon(Icons.favorite, size: 18),
                            ],
                          ),
                          subtitle: Text('$category\n$expiresText • Elérhető: $quantity db'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$discounted Ft',
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _scoreProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Set<String> interestedProductIds,
  ) {
    final data = doc.data();

    final category = data['category'] as String? ?? '';
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    final interestCount = data['interestCount'] as int? ?? 0;

    int score = 0;

    if (_favoriteCategories.contains(category)) {
      score += 100;
    }

    if (interestedProductIds.contains(doc.id)) {
      score += 80;
    }

    score += (interestCount > 20) ? 20 : interestCount;

    if (expiresAt != null) {
      final minutes = expiresAt.difference(DateTime.now()).inMinutes;

      if (minutes <= 0) {
        score += 0;
      } else if (minutes <= 60) {
        score += 60; 
      } else if (minutes <= 24 * 60) {
        score += 30; 
      } else {
        score += 5; 
      }
    }

    return score;
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
