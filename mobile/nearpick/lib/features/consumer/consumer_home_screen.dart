// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'product_detail_screen.dart';
import '../../recommendation/recommendation_engine.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/user_interaction_service.dart';
import '../../widgets/storage_image.dart';
import '../../services/negative_feedback_service.dart';
import '../../services/reservation_service.dart';
import 'my_reservations_screen.dart';
import 'reservation_detail_screen.dart';
import 'favorites_screen.dart';
import 'location_settings_screen.dart';
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
  final NegativeFeedbackService _negativeFeedbackService =
      NegativeFeedbackService();
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _compactionTriggered = false;

  List<String> _favoriteCategories = [];
  GeoPoint? _userLocation;
  final Set<String> _dismissedProductIds = {};

  String _selectedCategory = _allCategories.first;
  int _buildCounter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[ConsumerHome] initState user=${FirebaseAuth.instance.currentUser?.uid}',
    );
    _loadUserPreferences();
    _triggerImplicitPrefsCompaction();
    _listenForForegroundMessages();
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[ConsumerHome] _loadUserPreferences user=${user?.uid}');
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    debugPrint(
      '[ConsumerHome] users/${user.uid} exists=${doc.exists} hasData=${doc.data() != null}',
    );

    setState(() {
      _favoriteCategories = List<String>.from(
        doc.data()?['favoriteCategories'] ?? [],
      );
      _userLocation = doc.data()?['homeLocation'] as GeoPoint?;
    });
  }

  void _triggerImplicitPrefsCompaction() {
    if (_compactionTriggered) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _compactionTriggered = true;
    unawaited(
      UserInteractionService().compactImplicitPrefsIfNeeded(uid: user.uid),
    );
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

  Future<void> _dismissCategoryForProduct({
    required String productId,
    required String category,
    String? ownerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nem erdekel'),
        content: const Text(
          'Biztosan nem erdekel ez a kategoria? (Kesobb valtozhat)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Megse'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Igen'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _negativeFeedbackService.dismissCategoryForProduct(
        userId: user.uid,
        productId: productId,
        category: category,
        ownerId: ownerId,
      );
      if (!mounted) return;
      setState(() => _dismissedProductIds.add(productId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendben, kevesebb ilyen ajanlatot mutatunk.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Future<void> _reserveProduct(String productId) async {
    try {
      final reservationId = await ReservationService().reserveProduct(
        productId: productId,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationDetailScreen(reservationId: reservationId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('Elfogyott')
          ? 'Elfogyott'
          : 'Hiba: $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildThumbnail({required String? imagePath, required bool hasImage}) {
    if (hasImage && imagePath != null && imagePath.isNotEmpty) {
      return StorageImage(
        imagePath: imagePath,
        width: 56,
        height: 56,
        borderRadius: 8,
        maxSizeBytes: 256 * 1024,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 56,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Icon(Icons.photo_outlined),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCounter += 1;
    if (_buildCounter <= 3 || _buildCounter % 20 == 0) {
      debugPrint(
        '[ConsumerHome] build #$_buildCounter user=${FirebaseAuth.instance.currentUser?.uid}',
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('NearPick - Ajánlatok a közelben'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
              );
            },
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Foglalasaim',
          ),
          IconButton(
            icon: const Icon(Icons.place),
            tooltip: 'Hely beallitasa',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LocationSettingsScreen(),
                ),
              );
              if (mounted) {
                await _loadUserPreferences();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                if (interestsSnap.hasError) {
                  debugPrint(
                    '[ConsumerHome] interests error: ${interestsSnap.error}',
                  );
                }
                if (interestsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final interestDocs = interestsSnap.data?.docs ?? [];
                final interestedProductIds = <String>{
                  for (final d in interestDocs)
                    (d.data()['productId'] as String?) ?? '',
                }..remove('');

                final user = FirebaseAuth.instance.currentUser;
                debugPrint('[ConsumerHome] prefs streams user=${user?.uid}');
                final prefsStream = user == null
                    ? Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
                    : FirebaseFirestore.instance
                          .collection('userImplicitPrefs')
                          .doc(user.uid)
                          .snapshots();
                final negativePrefsStream = user == null
                    ? Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
                    : FirebaseFirestore.instance
                          .collection('userNegativePrefs')
                          .doc(user.uid)
                          .snapshots();

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: prefsStream,
                  builder: (context, prefsSnap) {
                    if (prefsSnap.hasError) {
                      debugPrint(
                        '[ConsumerHome] implicit prefs error: ${prefsSnap.error}',
                      );
                    }
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
                    final implicitLastViewedAt = <String, Timestamp>{};
                    final rawLastViewed = prefsSnap.data
                        ?.data()?['categoryLastViewedAt'];
                    if (rawLastViewed is Map) {
                      rawLastViewed.forEach((key, value) {
                        if (key is String && value is Timestamp) {
                          implicitLastViewedAt[key] = value;
                        }
                      });
                    }

                    return StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: negativePrefsStream,
                      builder: (context, negativeSnap) {
                        if (negativeSnap.hasError) {
                          debugPrint(
                            '[ConsumerHome] negative prefs error: ${negativeSnap.error}',
                          );
                        }
                        final negativeCategoryDismissals = <String, int>{};
                        final rawDismissals = negativeSnap.data
                            ?.data()?['categoryDismissals'];
                        if (rawDismissals is Map) {
                          rawDismissals.forEach((key, value) {
                            if (key is String) {
                              final intValue = value is int
                                  ? value
                                  : (value is num ? value.toInt() : null);
                              if (intValue != null) {
                                negativeCategoryDismissals[key] = intValue;
                              }
                            }
                          });
                        }
                        final negativeCategoryLastDismissedAt =
                            <String, Timestamp>{};
                        final rawLastDismissed = negativeSnap.data
                            ?.data()?['categoryLastDismissedAt'];
                        if (rawLastDismissed is Map) {
                          rawLastDismissed.forEach((key, value) {
                            if (key is String && value is Timestamp) {
                              negativeCategoryLastDismissedAt[key] = value;
                            }
                          });
                        }

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: _productService.listActiveProducts(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              debugPrint(
                                '[ConsumerHome] products error: ${snapshot.error}',
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Hiba a termekek betolteseakor: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            final filteredDocs = docs.where((doc) {
                              if (_dismissedProductIds.contains(doc.id)) {
                                return false;
                              }
                              final data = doc.data();
                              final isDeleted = data['isDeleted'] == true;
                              final status = data['status'] as String?;
                              if (isDeleted ||
                                  (status != null && status != 'active')) {
                                return false;
                              }
                              final quantityAvailable =
                                  data['quantityAvailable'] as int? ??
                                  data['quantity'] as int? ??
                                  0;
                              if (quantityAvailable <= 0) return false;

                              if (_selectedCategory == _allCategories.first) {
                                return true;
                              }

                              final category =
                                  data['category'] as String? ?? '';
                              return category == _selectedCategory;
                            }).toList();

                            final favSet = _favoriteCategories.toSet();
                            final scored = filteredDocs
                                .map(
                                  (doc) => scoreProductDoc(
                                    productId: doc.id,
                                    product: doc.data(),
                                    favoriteCategories: favSet,
                                    userLocation: _userLocation,
                                    implicitCategoryViews:
                                        implicitCategoryViews,
                                    implicitLastViewedAt: implicitLastViewedAt,
                                    negativeCategoryDismissals:
                                        negativeCategoryDismissals,
                                    negativeCategoryLastDismissedAt:
                                        negativeCategoryLastDismissedAt,
                                  ),
                                )
                                .toList();

                            scored.sort((a, b) {
                              if (a.score != b.score) {
                                return b.score.compareTo(a.score);
                              }

                              final aExp =
                                  (a.product['expiresAt'] as Timestamp?)
                                      ?.toDate();
                              final bExp =
                                  (b.product['expiresAt'] as Timestamp?)
                                      ?.toDate();
                              if (aExp == null || bExp == null) return 0;
                              return aExp.compareTo(bExp);
                            });

                            if (scored.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Jelenleg nincs elerheto ajanlat ebben a kategoriaban.',
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: scored.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final result = scored[index];
                                final docId = result.productId;
                                final data = result.product;
                                final imagePath = data['imagePath'] as String?;
                                final hasImage = data['hasImage'] == true;
                                final name =
                                    data['name'] as String? ??
                                    'Nevtelen termek';
                                final category =
                                    data['category'] as String? ??
                                    'Ismeretlen kategoria';
                                final discounted =
                                    data['discountedPrice'] as int? ?? 0;
                                final original =
                                    data['originalPrice'] as int? ?? 0;
                                final quantityAvailable =
                                    data['quantityAvailable'] as int? ??
                                    data['quantity'] as int? ??
                                    0;
                                final expiresAt =
                                    (data['expiresAt'] as Timestamp?)?.toDate();
                                final isInterested = interestedProductIds
                                    .contains(docId);

                                String expiresText = 'Ismeretlen lejarat';
                                if (expiresAt != null) {
                                  final now = DateTime.now();
                                  final diff = expiresAt.difference(now);
                                  if (diff.inMinutes <= 0) {
                                    expiresText = 'Hamarosan lejar';
                                  } else if (diff.inHours < 1) {
                                    expiresText =
                                        'Lejar ${diff.inMinutes} percen belul';
                                  } else if (diff.inHours < 24) {
                                    expiresText =
                                        'Lejar ${diff.inHours} oran belul';
                                  } else {
                                    expiresText =
                                        'Lejar: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
                                  }
                                }

                                void showReasons() {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final scorePercent = (result.score * 100)
                                          .clamp(0, 100)
                                          .toStringAsFixed(0);
                                      final reasons = result.reasons;
                                      final maxHeight =
                                          MediaQuery.of(context).size.height *
                                          0.6;
                                      return AlertDialog(
                                        title: const Text('Miert ajanlott?'),
                                        content: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: maxHeight,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pontszam: $scorePercent%',
                                                ),
                                                const SizedBox(height: 8),
                                                if (reasons.isEmpty)
                                                  const Text(
                                                    'Nincs elerheto indok.',
                                                  )
                                                else
                                                  ...reasons.map(
                                                    (r) => ListTile(
                                                      dense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      title: Text(r.label),
                                                      subtitle:
                                                          (r.detail == null ||
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
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('Bezar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }

                                return ListTile(
                                  leading: _buildThumbnail(
                                    imagePath: imagePath,
                                    hasImage: hasImage,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(name)),
                                      if (isInterested)
                                        const Icon(Icons.favorite, size: 18),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                        ),
                                        tooltip: 'Miert ajanlott?',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: showReasons,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$category\n$expiresText - Elerheto: $quantityAvailable db',
                                      ),
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
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        onPressed: quantityAvailable <= 0
                                            ? null
                                            : () => _reserveProduct(docId),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        child: const Text('Lefoglalom'),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.thumb_down_outlined,
                                          size: 18,
                                        ),
                                        tooltip: 'Nem erdekel',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            _dismissCategoryForProduct(
                                              productId: docId,
                                              category: category,
                                              ownerId:
                                                  data['ownerId'] as String?,
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
