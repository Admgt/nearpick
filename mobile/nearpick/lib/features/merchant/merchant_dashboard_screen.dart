import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Nincs bejelentkezett felhasznalo.')),
      );
    }

    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final startToday = DateTime(now.year, now.month, now.day);

    final interactionsStream = FirebaseFirestore.instance
        .collection('userInteractions')
        .where('ownerId', isEqualTo: user.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
          final productById = <String, Map<String, dynamic>>{
            for (final doc in productDocs) doc.id: doc.data(),
          };

          int activeOffers = 0;
          int expiredOffers = 0;
          int soldOutOffers = 0;

          for (final doc in productDocs) {
            final data = doc.data();
            final quantityAvailable = data['quantityAvailable'] as int? ??
                data['quantity'] as int? ??
                0;
            final status = data['status'] as String? ?? 'active';
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

            if (status == 'sold_out' || quantityAvailable <= 0) {
              soldOutOffers++;
            }
            if (status == 'expired' ||
                (expiresAt != null && !expiresAt.isAfter(now))) {
              expiredOffers++;
            }
            if (status == 'active' &&
                quantityAvailable > 0 &&
                (expiresAt == null || expiresAt.isAfter(now))) {
              activeOffers++;
            }
          }

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
              int views7d = 0;
              int interests7d = 0;
              int viewsToday = 0;
              int interestsToday = 0;
              final perProduct = <String, _ProductInteractionStats>{};

              for (final doc in interactionDocs) {
                final data = doc.data();
                final type = data['type'] as String? ?? '';
                final productId = data['productId'] as String? ?? '';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                if (productId.isEmpty || createdAt == null) continue;

                final stats =
                    perProduct.putIfAbsent(productId, () => _ProductInteractionStats());

                if (type == 'view') {
                  views7d++;
                  stats.views++;
                  if (!createdAt.isBefore(startToday)) {
                    viewsToday++;
                  }
                } else if (type == 'interest') {
                  interests7d++;
                  stats.interests++;
                  if (!createdAt.isBefore(startToday)) {
                    interestsToday++;
                  }
                }
              }

              final ctr7d = views7d == 0 ? 0.0 : (interests7d / views7d) * 100.0;
              final topEntries = perProduct.entries.toList()
                ..sort((a, b) => b.value.views.compareTo(a.value.views));
              final topProducts = topEntries.take(5).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          value: viewsToday.toString(),
                        ),
                        _KpiCard(
                          label: '7 nap megtekintesek',
                          value: views7d.toString(),
                        ),
                        _KpiCard(
                          label: 'Mai erdeklodesek',
                          value: interestsToday.toString(),
                        ),
                        _KpiCard(
                          label: 'CTR 7 nap',
                          value: '${ctr7d.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Top termekek (7 nap)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (topProducts.isEmpty)
                      const Text('Nincs elegendo adat az utolso 7 napbol.')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = topProducts[index];
                          final productId = entry.key;
                          final stats = entry.value;
                          final product = productById[productId] ?? {};
                          final name =
                              product['name'] as String? ?? 'Ismeretlen termek';
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
                      'Allapot osszegzes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _StatusChip(label: 'Active', value: activeOffers)),
                        const SizedBox(width: 8),
                        Expanded(child: _StatusChip(label: 'Expired', value: expiredOffers)),
                        const SizedBox(width: 8),
                        Expanded(child: _StatusChip(label: 'Sold out', value: soldOutOffers)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A megtekintes a termek reszleteinek megnyitasat jelenti, '
                      'az erdeklodes a kedvencekbe jelolest.',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductInteractionStats {
  int views = 0;
  int interests = 0;
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
