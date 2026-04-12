import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/error/app_error_message.dart';
import '../models/review.dart';
import '../utils/date_time_formatters.dart';

class MerchantReviewsSection extends StatelessWidget {
  final String merchantId;
  final String title;
  final String emptyMessage;
  final int limit;
  final String? currentUserId;
  final bool showProductName;

  const MerchantReviewsSection({
    super.key,
    required this.merchantId,
    required this.title,
    required this.emptyMessage,
    this.limit = 6,
    this.currentUserId,
    this.showProductName = false,
  });

  @override
  Widget build(BuildContext context) {
    if (merchantId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('merchantId', isEqualTo: merchantId.trim())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        final reviews = snapshot.data?.docs.map(Review.fromDoc).toList() ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                Text(appErrorMessage(snapshot.error!))
              else if (reviews.isEmpty)
                Text(emptyMessage)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final isOwnReview =
                        currentUserId != null &&
                        review.buyerId == currentUserId;
                    final reviewerLabel = isOwnReview
                        ? 'Te'
                        : review.buyerDisplayName.trim().isNotEmpty
                        ? review.buyerDisplayName.trim()
                        : 'Vasarlo';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              reviewerLabel,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (isOwnReview)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Sajat velemenyed',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ),
                            if (review.createdAt != null)
                              Text(
                                formatDateTime(review.createdAt!),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline,
                                size: 18,
                                color: Colors.amber.shade700,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text('${review.rating}/5'),
                          ],
                        ),
                        if (showProductName &&
                            review.productName.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              review.productName.trim(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(review.comment),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
