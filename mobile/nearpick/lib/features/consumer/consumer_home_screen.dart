import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'product_detail_screen.dart';
import '../../recommendation/recommendation_engine.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  List<String> _favoriteCategories = [];

  String _selectedCategory = _allCategories.first;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _listenForForegroundMessages();
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    super.dispose();
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

  void _listenForForegroundMessages() {
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      if (!mounted) return;

      final title = message.notification?.title ?? 'New offer';
      final body = message.notification?.body ?? 'A new product is available.';
      final productId = message.data['productId'] as String?;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 6),
          action: productId == null || productId.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Open',
                  onPressed: () async {
                    final doc = await FirebaseFirestore.instance
                        .collection('products')
                        .doc(productId)
                        .get();

                    if (!doc.exists || !mounted) return;
                    final data = doc.data() as Map<String, dynamic>;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          productId: productId,
                          data: data,
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
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

                final user = FirebaseAuth.instance.currentUser;
                final prefsStream = user == null
                    ? Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
                    : FirebaseFirestore.instance
                        .collection('userImplicitPrefs')
                        .doc(user.uid)
                        .snapshots();

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: prefsStream,
                  builder: (context, prefsSnap) {
                    final implicitCategoryViews = <String, int>{};
                    final rawViews = prefsSnap.data?.data()?['categoryViews'];
                    if (rawViews is Map) {
                      rawViews.forEach((key, value) {
                        if (key is String) {
                          final intValue = value is int
                              ? value
                              : (value is num ? value.toInt() : null);
                          if (intValue != null) {
                            implicitCategoryViews[key] = intValue;
                          }
                        }
                      });
                    }

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

                    final favSet = _favoriteCategories.toSet();
                    final scored = filteredDocs
                        .map(
                          (doc) => scoreProductDoc(
                            productId: doc.id,
                            product: doc.data(),
                            favoriteCategories: favSet,
                            implicitCategoryViews: implicitCategoryViews,
                          ),
                        )
                        .toList();

                    scored.sort((a, b) {
                      if (a.score != b.score) return b.score.compareTo(a.score);

                      final aExp = (a.product['expiresAt'] as Timestamp?)?.toDate();
                      final bExp = (b.product['expiresAt'] as Timestamp?)?.toDate();
                      if (aExp == null || bExp == null) return 0;
                      return aExp.compareTo(bExp);
                    });

                    if (scored.isEmpty) {
                      return const Center(
                        child: Text('Jelenleg nincs elérhető ajánlat ebben a kategóriában.'),
                      );
                    }

                        return ListView.separated(
                      itemCount: scored.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = scored[index];
                        final docId = result.productId;
                        final data = result.product;

                        final name = data['name'] as String? ?? 'Névtelen termék';
                        final category = data['category'] as String? ?? 'Ismeretlen kategória';
                        final discounted = data['discountedPrice'] as int? ?? 0;
                        final original = data['originalPrice'] as int? ?? 0;
                        final quantity = data['quantity'] as int? ?? 0;
                        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                        final isInterested = interestedProductIds.contains(docId);

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


                        void showReasons() {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final scorePercent =
                                  (result.score * 100).clamp(0, 100).toStringAsFixed(0);
                              final reasons = result.reasons;
                              final maxHeight =
                                  MediaQuery.of(context).size.height * 0.6;
                              return AlertDialog(
                                title: const Text('Miert ajanlott?'),
                                content: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: maxHeight),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pontszam: $scorePercent%'),
                                        const SizedBox(height: 8),
                                        if (reasons.isEmpty)
                                          const Text('Nincs elerheto indok.')
                                        else
                                          ...reasons.map(
                                            (r) => ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(r.label),
                                              subtitle: (r.detail == null ||
                                                      r.detail!.isEmpty)
                                                  ? null
                                                  : Text(r.detail!),
                                              trailing: Text(
                                                '${(r.contribution * 100).toStringAsFixed(0)}%',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Bezar'),
                                  ),
                                ],
                              );
                            },
                          );
                        }

                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (isInterested) const Icon(Icons.favorite, size: 18),
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 18),
                                tooltip: 'Miert ajanlott?',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: showReasons,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$category\n$expiresText - Elerheto: $quantity db'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: result.reasons
                                    .take(2)
                                    .map(
                                      (r) => Chip(
                                        label: Text(
                                          r.label,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  productId: docId,
                                  data: data,
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
