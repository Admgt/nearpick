// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../services/merchant_report_service.dart';
import '../../services/product_service.dart';
import 'dashboard_metrics.dart';
import 'dynamic_pricing.dart';
import 'merchant_home_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reservations_screen.dart';
import '../../ui/app_chrome.dart';
import '../../widgets/merchant_reviews_section.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final Set<String> _repricingIds = {};
  bool _exportingCsv = false;

  void _openTopDestination(MerchantTopDestination destination) {
    switch (destination) {
      case MerchantTopDestination.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantHomeScreen()),
        );
      case MerchantTopDestination.reservations:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantReservationsScreen()),
        );
      case MerchantTopDestination.dashboard:
        return;
      case MerchantTopDestination.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
        );
    }
  }

  Future<void> _applyRecommendedPrice({
    required BuildContext context,
    required String productId,
  }) async {
    setState(() => _repricingIds.add(productId));
    try {
      final newPrice = await ProductService().applyRecommendedPrice(
        productId: productId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uj ar alkalmazva: $newPrice Ft')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _repricingIds.remove(productId));
      }
    }
  }

  Future<void> _exportReservationsCsv({
    required BuildContext context,
    required String merchantId,
  }) async {
    setState(() => _exportingCsv = true);
    try {
      final result = await MerchantReportService().exportReservationsCsv(
        merchantId: merchantId,
      );
      if (!context.mounted) return;
      final message = switch (result) {
        MerchantReportExportResult.downloaded =>
          'A CSV riport letoltese elindult.',
        MerchantReportExportResult.copiedToClipboard =>
          'A CSV riport a vagolapra kerult.',
        MerchantReportExportResult.empty =>
          'Nincs exportalhato foglalasi adat.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _exportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: buildMerchantAppBarActions(
            context,
            current: MerchantTopDestination.dashboard,
            onSelected: _openTopDestination,
          ),
        ),
        body: const Center(child: Text('Nincs bejelentkezett felhasznalo.')),
      );
    }

    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final interactionsStream = FirebaseFirestore.instance
        .collection('userInteractions')
        .where('ownerId', isEqualTo: user.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .snapshots();
    final merchantStatsStream = FirebaseFirestore.instance
        .collection('merchantStats')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ...buildMerchantAppBarActions(
            context,
            current: MerchantTopDestination.dashboard,
            onSelected: _openTopDestination,
          ),
          TextButton.icon(
            onPressed: _exportingCsv
                ? null
                : () => _exportReservationsCsv(
                    context: context,
                    merchantId: user.uid,
                  ),
            icon: _exportingCsv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: const Text('CSV export'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productsStream,
        builder: (context, productsSnap) {
          if (productsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (productsSnap.hasError) {
            return Center(
              child: Text(
                'Hiba a termekek betoltese soran: ${productsSnap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final productDocs = productsSnap.data?.docs ?? [];
          final products = productDocs
              .map(
                (doc) => MapEntry(doc.id, {
                  ...doc.data(),
                  'expiresAt': (doc.data()['expiresAt'] as Timestamp?)
                      ?.toDate(),
                }),
              )
              .toList();
          final productById = <String, Map<String, dynamic>>{
            for (final entry in products) entry.key: entry.value,
          };

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: interactionsStream,
            builder: (context, interactionsSnap) {
              if (interactionsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (interactionsSnap.hasError) {
                return Center(
                  child: Text(
                    'Hiba az interakciok betoltese soran: ${interactionsSnap.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final interactionDocs = interactionsSnap.data?.docs ?? [];
              final interactions = interactionDocs.map((doc) {
                final data = doc.data();
                return {
                  ...data,
                  'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
                };
              }).toList();
              final metrics = buildMerchantDashboardMetrics(
                products: products,
                interactions: interactions,
                now: now,
              );

              return NearPickBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uzleti attekintes',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: merchantStatsStream,
                        builder: (context, statsSnap) {
                          final stats =
                              statsSnap.data?.data() ??
                              const <String, dynamic>{};
                          final averageRating =
                              (stats['averageRating'] as num?)?.toDouble() ?? 0;
                          final reviewCount = stats['reviewCount'] as int? ?? 0;

                          return SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vasarloi visszajelzesek',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    InfoBadge(
                                      icon: Icons.star_rounded,
                                      label: 'Atlag rating',
                                      value: reviewCount == 0
                                          ? '-'
                                          : averageRating.toStringAsFixed(1),
                                      tint: Colors.amber.shade700,
                                    ),
                                    InfoBadge(
                                      icon: Icons.reviews_outlined,
                                      label: 'Review darab',
                                      value: reviewCount.toString(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      MerchantReviewsSection(
                        merchantId: user.uid,
                        title: 'Legutobbi vasarloi velemenyek',
                        emptyMessage:
                            'Meg nincs egyetlen publikus vasarloi velemenyed sem.',
                        limit: 10,
                        showProductName: true,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _KpiCard(
                            label: 'Mai megtekintesek',
                            value: metrics.viewsToday.toString(),
                          ),
                          _KpiCard(
                            label: '7 nap megtekintesek',
                            value: metrics.views7d.toString(),
                          ),
                          _KpiCard(
                            label: 'Mai erdeklodesek',
                            value: metrics.interestsToday.toString(),
                          ),
                          _KpiCard(
                            label: 'CTR 7 nap',
                            value: '${metrics.ctr7d.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Top termekek (7 nap)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (metrics.topProducts.isEmpty)
                        const Text('Nincs elegendo adat az utolso 7 napbol.')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: metrics.topProducts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = metrics.topProducts[index];
                            final productId = entry.key;
                            final stats = entry.value;
                            final product = productById[productId] ?? {};
                            final name =
                                product['name'] as String? ??
                                'Ismeretlen termek';
                            final discounted =
                                product['discountedPrice'] as int? ?? 0;
                            final ctr = stats.views == 0
                                ? 0.0
                                : (stats.interests / stats.views) * 100.0;

                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                'Views: ${stats.views} • Interests: ${stats.interests} • CTR: ${ctr.toStringAsFixed(1)}%',
                              ),
                              trailing: Text('$discounted Ft'),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Arazasi insightok',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8,
                        children: [
                          _KpiCard(
                            label: 'Pricing coverage',
                            value: '${metrics.pricingCoverageCount}',
                          ),
                          _KpiCard(
                            label: 'Atlagos kereslet',
                            value:
                                '${(metrics.averageDemandScore * 100).toStringAsFixed(0)}%',
                          ),
                          _KpiCard(
                            label: 'Magas keresletu',
                            value: metrics.highDemandOffers.toString(),
                          ),
                          _KpiCard(
                            label: 'Atlagos ajanlott akcio',
                            value:
                                '${metrics.averageRecommendedDiscountPercent.toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatusChip(
                              label: 'Tul alacsony ar',
                              value: metrics.priceTooLowCount,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatusChip(
                              label: 'Tul magas ar',
                              value: metrics.priceTooHighCount,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Arazasi lehetosegek',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (metrics.pricingCandidates.isEmpty)
                        const Text(
                          'A jelenlegi aktiv ajanlatok a becsult arsavban vannak.',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: metrics.pricingCandidates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = metrics.pricingCandidates[index];
                            final product = productById[entry.key] ?? {};
                            final insight = entry.value;
                            final name =
                                product['name'] as String? ??
                                'Ismeretlen termek';
                            final hasReservations =
                                product['hasReservations'] == true;
                            final action = insight.shouldLowerPrice
                                ? 'Csokkentsd'
                                : 'Emeld';
                            final deviationLabel =
                                '${insight.deviationPercent > 0 ? '+' : ''}${insight.deviationPercent}%';
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                hasReservations
                                    ? 'A termekre mar erkezett foglalas, ezert az ar nem modosithato. Elteres: $deviationLabel.'
                                    : '$action az arat ${insight.recommendedPrice} Ft kozelebe. '
                                          'Aktualis: ${insight.actualPrice} Ft, sav: '
                                          '${insight.minimumSuggestedPrice}-${insight.maximumSuggestedPrice} Ft. '
                                          'Kereslet: ${demandLevelLabel(insight.demandLevel)}. '
                                          'Elteres: $deviationLabel.',
                              ),
                              trailing: ElevatedButton(
                                onPressed:
                                    hasReservations ||
                                        _repricingIds.contains(entry.key)
                                    ? null
                                    : () => _applyRecommendedPrice(
                                        context: context,
                                        productId: entry.key,
                                      ),
                                child: _repricingIds.contains(entry.key)
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Alkalmaz'),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Allapot osszegzes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatusChip(
                              label: 'Active',
                              value: metrics.activeOffers,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatusChip(
                              label: 'Expired',
                              value: metrics.expiredOffers,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatusChip(
                              label: 'Sold out',
                              value: metrics.soldOutOffers,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A megtekintes a termek reszleteinek megnyitasat jelenti, '
                        'az erdeklodes a kedvencekbe jelolest.',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
