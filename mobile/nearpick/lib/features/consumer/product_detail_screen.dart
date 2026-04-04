import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../services/product_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import '../../widgets/storage_image.dart';
import '../../services/user_interaction_service.dart';
import '../../services/negative_feedback_service.dart';
import '../../services/reservation_service.dart';
import '../../widgets/merchant_reviews_section.dart';
import 'reservation_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.data,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loading = false;
  bool _dismissLoading = false;
  String? _message;
  bool _viewLogged = false;
  bool _reserveLoading = false;

  Future<void> _dismissCategoryForProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final category = (widget.data['category'] as String?)?.trim() ?? '';
    if (category.isEmpty) return;

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

    setState(() => _dismissLoading = true);
    try {
      await NegativeFeedbackService().dismissCategoryForProduct(
        userId: user.uid,
        productId: widget.productId,
        category: category,
        ownerId: (widget.data['ownerId'] as String?)?.trim(),
      );
      if (!mounted) return;
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
    } finally {
      if (mounted) setState(() => _dismissLoading = false);
    }
  }

  Future<void> _reserveProduct() async {
    setState(() => _reserveLoading = true);
    try {
      final reservationId = await ReservationService().reserveProduct(
        productId: widget.productId,
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
    } finally {
      if (mounted) setState(() => _reserveLoading = false);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _interestDocStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    final docId = '${user.uid}_${widget.productId}';
    return FirebaseFirestore.instance
        .collection('interests')
        .doc(docId)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _logViewIfNeeded();
  }

  Future<void> _logViewIfNeeded() async {
    if (_viewLogged) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final category = (widget.data['category'] as String?)?.trim() ?? '';
    final ownerId = (widget.data['ownerId'] as String?)?.trim() ?? '';
    if (category.isEmpty || ownerId.isEmpty) return;

    _viewLogged = true;
    try {
      await UserInteractionService().logProductView(
        uid: user.uid,
        productId: widget.productId,
        ownerId: ownerId,
        category: category,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    final imagePath = data['imagePath'] as String?;
    final hasImage = data['hasImage'] == true;

    final name = data['name'] as String? ?? 'Névtelen termék';
    final category = data['category'] as String? ?? 'Ismeretlen kategória';
    final discounted = data['discountedPrice'] as int? ?? 0;
    final original = data['originalPrice'] as int? ?? 0;
    final quantityAvailable =
        data['quantityAvailable'] as int? ?? data['quantity'] as int? ?? 0;
    final expiresAt = asDate(data['expiresAt']);
    final pickupStartAt = asDate(data['pickupStartAt']);
    final pickupEndAt = asDate(data['pickupEndAt']);
    final ownerId = (data['ownerId'] as String?)?.trim() ?? '';
    final pickupWindowText = formatPickupWindow(
      pickupStartAt: pickupStartAt,
      pickupEndAt: pickupEndAt,
    );

    String expiresText = 'Ismeretlen lejárat';
    if (expiresAt != null) {
      expiresText =
          '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}  ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Termék részletei')),
      body: NearPickBackground(
        maxWidth: 720,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage && imagePath != null && imagePath.isNotEmpty)
                  StorageImage(
                    imagePath: imagePath,
                    width: double.infinity,
                    height: 200,
                    borderRadius: 12,
                    maxSizeBytes: 2 * 1024 * 1024,
                  ),
                if (hasImage && imagePath != null && imagePath.isNotEmpty)
                  const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Kategória: $category'),
                const SizedBox(height: 8),
                Text('Lejárat: $expiresText'),
                const SizedBox(height: 8),
                Text('Elérhető: $quantityAvailable db'),
                Text('Atvetel: $pickupWindowText'),
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '$discounted Ft',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (original > discounted)
                      Text(
                        '$original Ft',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                if (ownerId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('merchantStats')
                        .doc(ownerId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final stats =
                          snapshot.data?.data() ?? const <String, dynamic>{};
                      final averageRating =
                          (stats['averageRating'] as num?)?.toDouble() ?? 0;
                      final reviewCount = stats['reviewCount'] as int? ?? 0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kereskedo ertekelese',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reviewCount == 0
                                        ? 'Meg nincs vasarloi ertekeles.'
                                        : '${averageRating.toStringAsFixed(1)} / 5.0  -  $reviewCount velemeny',
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.star_rounded,
                              color: reviewCount == 0
                                  ? Colors.grey
                                  : Colors.amber.shade700,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  MerchantReviewsSection(
                    merchantId: ownerId,
                    title: 'Vasarloi velemenyek a kereskedorol',
                    emptyMessage:
                        'Ehhez a kereskedohoz meg nincs megjelenitheto velemeny.',
                    currentUserId: FirebaseAuth.instance.currentUser?.uid,
                  ),
                ],

                const SizedBox(height: 24),

                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.startsWith('OK')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reserveLoading || quantityAvailable <= 0
                        ? null
                        : _reserveProduct,
                    icon: _reserveLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.event_available_outlined),
                    label: const Text('Lefoglalom'),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _interestDocStream(),
                  builder: (context, snap) {
                    final isFavorite = snap.data?.exists ?? false;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() {
                                  _loading = true;
                                  _message = null;
                                });

                                try {
                                  if (isFavorite) {
                                    await ProductService()
                                        .unmarkInterestForCurrentUser(
                                          productId: widget.productId,
                                        );
                                    setState(
                                      () => _message =
                                          'OK: Eltávolítva a kedvencekből.',
                                    );
                                  } else {
                                    await ProductService().markInterest(
                                      productId: widget.productId,
                                    );
                                    final category =
                                        (widget.data['category'] as String?)
                                            ?.trim() ??
                                        '';
                                    final ownerId =
                                        (widget.data['ownerId'] as String?)
                                            ?.trim() ??
                                        '';
                                    if (category.isNotEmpty &&
                                        ownerId.isNotEmpty) {
                                      await UserInteractionService()
                                          .logProductInterest(
                                            uid:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid ??
                                                '',
                                            productId: widget.productId,
                                            ownerId: ownerId,
                                            category: category,
                                          );
                                    }
                                    setState(
                                      () => _message =
                                          'OK: Hozzáadva a kedvencekhez.',
                                    );
                                  }
                                } catch (e) {
                                  setState(() => _message = appErrorMessage(e));
                                } finally {
                                  if (mounted) {
                                    setState(() => _loading = false);
                                  }
                                }
                              },
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                        label: Text(
                          isFavorite ? 'Eltávolítás a kedvencekből' : 'Kedvenc',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _dismissLoading
                        ? null
                        : _dismissCategoryForProduct,
                    icon: _dismissLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.thumb_down_outlined),
                    label: const Text('Nem erdekel'),
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
