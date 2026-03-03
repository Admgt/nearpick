// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'storage_image.dart';

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onArchive;
  final int reservedCount;

  const ProductListTile({
    super.key,
    required this.product,
    this.onArchive,
    this.reservedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = product.expiresAt;
    String expiresText = 'Ismeretlen lejarat';
    if (expiresAt != null) {
      expiresText =
          'Lejar: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
    }

    final imagePath = product.imagePath;

    return ListTile(
      leading: product.hasImage && imagePath != null && imagePath.isNotEmpty
          ? StorageImage(
              imagePath: imagePath,
              width: 56,
              height: 56,
              borderRadius: 8,
              maxSizeBytes: 256 * 1024,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Icon(Icons.photo_outlined),
              ),
            ),
      title: Row(
        children: [
          Expanded(child: Text(product.name)),
          if (reservedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Foglalas: $reservedCount'),
            ),
        ],
      ),
      subtitle: Text(
        '${product.category}\n$expiresText - Mennyiseg: ${product.quantityAvailable} db - Status: ${product.status}',
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.discountedPrice} Ft',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (product.originalPrice > product.discountedPrice)
                Text(
                  '${product.originalPrice} Ft',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Torles',
            onPressed: onArchive,
          ),
        ],
      ),
    );
  }
}
