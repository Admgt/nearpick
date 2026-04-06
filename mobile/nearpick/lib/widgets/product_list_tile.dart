// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../features/merchant/dynamic_pricing.dart';
import '../models/product.dart';
import '../ui/app_chrome.dart';
import '../utils/date_time_formatters.dart';
import 'storage_image.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final int reservedCount;

  const ProductListTile({
    super.key,
    required this.product,
    this.onEdit,
    this.onArchive,
    this.reservedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiresAt = product.expiresAt;
    final pricingRecommendation = product.pricingRecommendation;
    final recommendedPrice = pricingRecommendation?['recommendedPrice'] as int?;
    final demandLevel = pricingRecommendation?['demandLevel'] as String?;
    final expectedReservations24h =
        pricingRecommendation?['expectedReservations24h'] as int?;
    final pickupWindowText = formatPickupWindow(
      pickupStartAt: product.pickupStartAt,
      pickupEndAt: product.pickupEndAt,
    );
    String expiresText = 'Ismeretlen lejarat';
    if (expiresAt != null) {
      expiresText = 'Lejar: ${formatDate(expiresAt)}';
    }

    final imagePath = product.imagePath;
    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          product.hasImage && imagePath != null && imagePath.isNotEmpty
              ? StorageImage(
                  imagePath: imagePath,
                  width: 78,
                  height: 78,
                  borderRadius: 18,
                  maxSizeBytes: 256 * 1024,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 78,
                    height: 78,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.photo_outlined),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (reservedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Foglalas $reservedCount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: product.category),
                    _MetaChip(
                      label: expiresText,
                      icon: Icons.schedule_outlined,
                    ),
                    _MetaChip(
                      label: 'Mennyiseg ${product.quantityAvailable} db',
                      icon: Icons.inventory_2_outlined,
                    ),
                    if (product.pickupStartAt != null &&
                        product.pickupEndAt != null)
                      _MetaChip(
                        label: 'Atvetel $pickupWindowText',
                        icon: Icons.schedule_send_outlined,
                      ),
                    _MetaChip(
                      label: 'Status ${product.status}',
                      icon: Icons.flag_outlined,
                    ),
                    if (product.hasReservations)
                      _MetaChip(
                        label: 'Szerkesztes zarolva',
                        icon: Icons.lock_outline,
                      ),
                    if (demandLevel != null)
                      _MetaChip(
                        label: 'Kereslet ${demandLevelLabel(demandLevel)}',
                        icon: Icons.trending_up_outlined,
                      ),
                    if (recommendedPrice != null)
                      _MetaChip(
                        label: 'Javasolt ar $recommendedPrice Ft',
                        icon: Icons.sell_outlined,
                      ),
                    if (expectedReservations24h != null)
                      _MetaChip(
                        label:
                            'Varhato foglalas $expectedReservations24h / 24h',
                        icon: Icons.query_stats_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.discountedPrice} Ft',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (product.originalPrice > product.discountedPrice)
                          Text(
                            '${product.originalPrice} Ft',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Szerkesztes',
                        onPressed: onEdit,
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Torles',
                      onPressed: onArchive,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _MetaChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
