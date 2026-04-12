// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../models/admin_message.dart';
import '../../services/admin_message_service.dart';
import '../../services/merchant_report_service.dart';
import '../../services/product_service.dart';
import '../../utils/date_time_formatters.dart';
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
  final AdminMessageService _adminMessageService = AdminMessageService();
  final Set<String> _markingAdminMessageIds = {};
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

  Future<void> _markAdminMessageRead({
    required String userId,
    required String messageId,
  }) async {
    setState(() => _markingAdminMessageIds.add(messageId));
    try {
      await _adminMessageService.markMessageRead(
        userId: userId,
        messageId: messageId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _markingAdminMessageIds.remove(messageId));
      }
    }
  }

  String _adminMessageTopicLabel(String topic) {
    switch (topic) {
      case 'rating':
        return 'Rating';
      case 'moderation':
        return 'Moderacio';
      default:
        return 'Altalanos';
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
    final adminMessagesStream = _adminMessageService.watchMessagesForUser(
      user.uid,
    );
    final compact = isCompactLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ...buildMerchantAppBarActions(
            context,
            current: MerchantTopDestination.dashboard,
            onSelected: _openTopDestination,
          ),
          compact
              ? IconButton(
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
                  tooltip: 'CSV export',
                )
              : TextButton.icon(
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
                appErrorMessage(productsSnap.error!),
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
                    appErrorMessage(interactionsSnap.error!),
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
                      StreamBuilder<List<AdminMessage>>(
                        stream: adminMessagesStream,
                        builder: (context, adminMessagesSnap) {
                          if (adminMessagesSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const SurfaceCard(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (adminMessagesSnap.hasError) {
                            return SurfaceCard(
                              child: Text(
                                appErrorMessage(adminMessagesSnap.error!),
                              ),
                            );
                          }

                          final messages =
                              adminMessagesSnap.data ?? const <AdminMessage>[];
                          final unreadCount = messages
                              .where((message) => !message.isRead)
                              .length;

                          return SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin uzenetek',
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
                                      icon: Icons.mail_outline,
                                      label: 'Osszes uzenet',
                                      value: messages.length.toString(),
                                    ),
                                    InfoBadge(
                                      icon: Icons.mark_email_unread_outlined,
                                      label: 'Olvasatlan',
                                      value: unreadCount.toString(),
                                      tint: unreadCount == 0
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (messages.isEmpty)
                                  const Text(
                                    'Jelenleg nincs admin uzenet a fiokodhoz.',
                                  )
                                else
                                  ...messages.take(5).map((message) {
                                    final readAction = message.isRead
                                        ? const Text('Olvasva')
                                        : TextButton(
                                            onPressed:
                                                _markingAdminMessageIds
                                                    .contains(message.id)
                                                ? null
                                                : () => _markAdminMessageRead(
                                                    userId: user.uid,
                                                    messageId: message.id,
                                                  ),
                                            child:
                                                _markingAdminMessageIds
                                                    .contains(message.id)
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Olvasottra jelol',
                                                  ),
                                          );
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        message.isRead
                                            ? Icons.mark_email_read_outlined
                                            : Icons.mark_email_unread_outlined,
                                      ),
                                      title: Text(message.subject),
                                      subtitle: compact
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${_adminMessageTopicLabel(message.topic)} | ${message.createdAt == null ? 'Nincs datum' : formatDateTime(message.createdAt!)}\n${message.body}',
                                                ),
                                                const SizedBox(height: 6),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: readAction,
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '${_adminMessageTopicLabel(message.topic)} | ${message.createdAt == null ? 'Nincs datum' : formatDateTime(message.createdAt!)}\n${message.body}',
                                            ),
                                      isThreeLine: true,
                                      trailing: compact ? null : readAction,
                                    );
                                  }),
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
                        crossAxisCount: compact ? 1 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: compact ? 2.6 : 1.6,
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
                        crossAxisCount: compact ? 1 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: compact ? 2.6 : 1.8,
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
                      compact
                          ? Column(
                              children: [
                                _StatusChip(
                                  label: 'Tul alacsony ar',
                                  value: metrics.priceTooLowCount,
                                ),
                                const SizedBox(height: 8),
                                _StatusChip(
                                  label: 'Tul magas ar',
                                  value: metrics.priceTooHighCount,
                                ),
                              ],
                            )
                          : Row(
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
                            final details = hasReservations
                                ? 'A termekre mar erkezett foglalas, ezert az ar nem modosithato. Elteres: $deviationLabel.'
                                : '$action az arat ${insight.recommendedPrice} Ft kozelebe. '
                                      'Aktualis: ${insight.actualPrice} Ft, sav: '
                                      '${insight.minimumSuggestedPrice}-${insight.maximumSuggestedPrice} Ft. '
                                      'Kereslet: ${demandLevelLabel(insight.demandLevel)}. '
                                      'Elteres: $deviationLabel.';
                            final applyButton = ElevatedButton(
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
                            );
                            return ListTile(
                              title: Text(name),
                              subtitle: compact
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(details),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: applyButton,
                                        ),
                                      ],
                                    )
                                  : Text(details),
                              trailing: compact ? null : applyButton,
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Allapot osszegzes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      compact
                          ? Column(
                              children: [
                                _StatusChip(
                                  label: 'Active',
                                  value: metrics.activeOffers,
                                ),
                                const SizedBox(height: 8),
                                _StatusChip(
                                  label: 'Expired',
                                  value: metrics.expiredOffers,
                                ),
                                const SizedBox(height: 8),
                                _StatusChip(
                                  label: 'Sold out',
                                  value: metrics.soldOutOffers,
                                ),
                              ],
                            )
                          : Row(
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
