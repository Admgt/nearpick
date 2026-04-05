// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/error/app_error_message.dart';
import 'product_detail_screen.dart';
import '../../recommendation/recommendation_engine.dart';
import 'offer_map_view.dart';
import 'offer_filter.dart';
import '../../services/product_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import '../../services/user_interaction_service.dart';
import '../../widgets/storage_image.dart';
import '../../services/negative_feedback_service.dart';
import '../../services/reservation_service.dart';
import 'my_reservations_screen.dart';
import 'reservation_detail_screen.dart';
import 'favorites_screen.dart';
import 'account_screen.dart';
import 'consumer_navigation.dart';
import 'location_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

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
  double _preferredRadiusKm = LocationPreferences.defaultPreferredRadiusKm;
  String _locationStatusLabel = 'nincs beallitva';
  final Set<String> _dismissedProductIds = {};

  String _selectedCategory = _allCategories.first;
  _BrowseMode _browseMode = _BrowseMode.list;
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
    final locationPreferences = LocationPreferences.fromUserData(doc.data());

    setState(() {
      _favoriteCategories = List<String>.from(
        doc.data()?['favoriteCategories'] ?? [],
      );
      _userLocation = locationPreferences.homeLocation;
      _preferredRadiusKm = locationPreferences.preferredRadiusKm;
      _locationStatusLabel = locationPreferences.locationStatusLabel;
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
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
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
      final message = appErrorMessage(e);
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

  void _openProductDetail({
    required String productId,
    required Map<String, dynamic> data,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId, data: data),
      ),
    );
  }

  void _openTopDestination(ConsumerTopDestination destination) {
    switch (destination) {
      case ConsumerTopDestination.home:
        return;
      case ConsumerTopDestination.reservations:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyReservationsScreen()));
      case ConsumerTopDestination.favorites:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
      case ConsumerTopDestination.account:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
    }
  }

  void _showReasonsDialog(RecommendationResult result) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final scorePercent = (result.score * 100)
            .clamp(0, 100)
            .toStringAsFixed(0);
        final reasons = result.reasons;
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
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
                      (reason) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(reason.label),
                        subtitle:
                            reason.detail == null || reason.detail!.isEmpty
                            ? null
                            : Text(reason.detail!),
                        trailing: Text(
                          '${(reason.contribution * 100).toStringAsFixed(0)}%',
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

  Widget _buildBrowseSummary(List<RecommendationResult> scored) {
    final withLocationCount = scored
        .where((offer) => offer.distanceKm != null)
        .length;
    final withinRadiusCount = scored
        .where((offer) => offer.isWithinPreferredRadius)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            InfoBadge(
              icon: Icons.inventory_2_outlined,
              label: 'Ajanlat',
              value: '${scored.length} db',
            ),
            InfoBadge(
              icon: Icons.route_outlined,
              label: 'Sugar',
              value: LocationPreferences.radiusLabel(_preferredRadiusKm),
            ),
            InfoBadge(
              icon: Icons.place_outlined,
              label: 'Pozicio',
              value: _locationStatusLabel,
            ),
            InfoBadge(
              icon: Icons.near_me_outlined,
              label: 'Sugarban',
              value: '$withinRadiusCount / $withLocationCount',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferList(
    List<RecommendationResult> scored,
    Set<String> interestedProductIds,
  ) {
    return ListView.separated(
      itemCount: scored.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = scored[index];
        final docId = result.productId;
        final data = result.product;
        final imagePath = data['imagePath'] as String?;
        final hasImage = data['hasImage'] == true;
        final name = data['name'] as String? ?? 'Nevtelen termek';
        final merchantName = (data['merchantName'] as String?)?.trim() ?? '';
        final category = data['category'] as String? ?? 'Ismeretlen kategoria';
        final discounted = data['discountedPrice'] as int? ?? 0;
        final original = data['originalPrice'] as int? ?? 0;
        final quantityAvailable =
            data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        final pickupStartAt = _asDate(data['pickupStartAt']);
        final pickupEndAt = _asDate(data['pickupEndAt']);
        final pickupWindowText = pickupStartAt != null && pickupEndAt != null
            ? formatPickupWindow(
                pickupStartAt: pickupStartAt,
                pickupEndAt: pickupEndAt,
              )
            : null;
        final isInterested = interestedProductIds.contains(docId);

        String expiresText = 'Ismeretlen lejarat';
        if (expiresAt != null) {
          final now = DateTime.now();
          final diff = expiresAt.difference(now);
          if (diff.inMinutes <= 0) {
            expiresText = 'Hamarosan lejar';
          } else if (diff.inHours < 1) {
            expiresText = 'Lejar ${diff.inMinutes} percen belul';
          } else if (diff.inHours < 24) {
            expiresText = 'Lejar ${diff.inHours} oran belul';
          } else {
            expiresText =
                'Lejar: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
          }
        }

        final chips = <Widget>[
          if (result.distanceKm != null)
            Chip(
              label: Text(
                result.isWithinPreferredRadius
                    ? '${distanceLabelKm(result.distanceKm!)} | sugarban'
                    : distanceLabelKm(result.distanceKm!),
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ...result.reasons
              .take(2)
              .map(
                (reason) => Chip(
                  label: Text(
                    reason.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
        ];

        return ListTile(
          leading: _buildThumbnail(imagePath: imagePath, hasImage: hasImage),
          title: Row(
            children: [
              Expanded(child: Text(name)),
              if (isInterested) const Icon(Icons.favorite, size: 18),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'Miert ajanlott?',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showReasonsDialog(result),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickupWindowText == null
                    ? merchantName.isEmpty
                          ? '$category\n$expiresText - Elerheto: $quantityAvailable db'
                          : '$merchantName\n$category - $expiresText - Elerheto: $quantityAvailable db'
                    : merchantName.isEmpty
                    ? '$category\n$expiresText - Elerheto: $quantityAvailable db\nAtvetel: $pickupWindowText'
                    : '$merchantName\n$category - $expiresText - Elerheto: $quantityAvailable db\nAtvetel: $pickupWindowText',
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
              ],
            ],
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
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
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Lefoglalom'),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.thumb_down_outlined, size: 18),
                tooltip: 'Nem erdekel',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                onPressed: () => _dismissCategoryForProduct(
                  productId: docId,
                  category: category,
                  ownerId: data['ownerId'] as String?,
                ),
              ),
            ],
          ),
          onTap: () => _openProductDetail(productId: docId, data: data),
        );
      },
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
          ...buildConsumerAppBarActions(
            context,
            current: ConsumerTopDestination.home,
            onSelected: _openTopDestination,
          ),
        ],
      ),
      body: NearPickBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Kategória:'),
                  SizedBox(
                    width: 280,
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _allCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
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
                  SegmentedButton<_BrowseMode>(
                    segments: const [
                      ButtonSegment<_BrowseMode>(
                        value: _BrowseMode.list,
                        icon: Icon(Icons.view_list_outlined),
                        label: Text('Lista'),
                      ),
                      ButtonSegment<_BrowseMode>(
                        value: _BrowseMode.map,
                        icon: Icon(Icons.map_outlined),
                        label: Text('Terkep'),
                      ),
                    ],
                    selected: {_browseMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _browseMode = selection.first;
                      });
                    },
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
                  if (interestsSnap.connectionState ==
                      ConnectionState.waiting) {
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
                                return shouldIncludeOffer(
                                  productId: doc.id,
                                  product: doc.data(),
                                  dismissedProductIds: _dismissedProductIds,
                                  selectedCategory: _selectedCategory,
                                  allCategoryLabel: _allCategories.first,
                                );
                              }).toList();

                              final favSet = _favoriteCategories.toSet();
                              final scored = filteredDocs
                                  .map(
                                    (doc) => scoreProductDoc(
                                      productId: doc.id,
                                      product: doc.data(),
                                      favoriteCategories: favSet,
                                      userLocation: _userLocation,
                                      preferredRadiusKm: _preferredRadiusKm,
                                      implicitCategoryViews:
                                          implicitCategoryViews,
                                      implicitLastViewedAt:
                                          implicitLastViewedAt,
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

                              return Column(
                                children: [
                                  _buildBrowseSummary(scored),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: _browseMode == _BrowseMode.map
                                        ? OfferMapView(
                                            offers: scored,
                                            userLocation: _userLocation,
                                            preferredRadiusKm:
                                                _preferredRadiusKm,
                                            onOpenProduct: (result) =>
                                                _openProductDetail(
                                                  productId: result.productId,
                                                  data: result.product,
                                                ),
                                            onReserveProduct: _reserveProduct,
                                          )
                                        : _buildOfferList(
                                            scored,
                                            interestedProductIds,
                                          ),
                                  ),
                                ],
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
      ),
    );
  }
}

enum _BrowseMode { list, map }

const List<String> _allCategories = [
  'Összes kategória',
  'Péksütemény',
  'Tejtermék',
  'Zöldség / gyümölcs',
  'Készétel',
  'Egyéb',
];
