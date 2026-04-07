// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../reservation/reservation_support.dart';
import '../../models/reservation.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'account_screen.dart';
import 'consumer_navigation.dart';
import 'favorites_screen.dart';
import 'reservation_detail_screen.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  void _openTopDestination(
    BuildContext context,
    ConsumerTopDestination destination,
  ) {
    switch (destination) {
      case ConsumerTopDestination.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case ConsumerTopDestination.reservations:
        return;
      case ConsumerTopDestination.favorites:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
      case ConsumerTopDestination.account:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Foglalasaim'),
          actions: buildConsumerAppBarActions(
            context,
            current: ConsumerTopDestination.reservations,
            onSelected: (destination) =>
                _openTopDestination(context, destination),
          ),
        ),
        body: const Center(child: Text('Nincs bejelentkezett felhasznalo.')),
      );
    }

    final reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foglalasaim'),
        actions: buildConsumerAppBarActions(
          context,
          current: ConsumerTopDestination.reservations,
          onSelected: (destination) =>
              _openTopDestination(context, destination),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nincs meg foglalasod.'));
          }

          return NearPickBackground(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reservation = Reservation.fromDoc(docs[index]);
                final snapshotData = reservation.productSnapshot;
                final imageUrl = snapshotData['imageUrl'] as String?;
                final name =
                    snapshotData['name'] as String? ?? 'Ismeretlen termek';
                final merchantName = reservation.merchantName.trim();
                final discounted = snapshotData['discountedPrice'] as int? ?? 0;
                final original = snapshotData['originalPrice'] as int? ?? 0;
                final totalDiscounted = discounted * reservation.qty;
                final totalOriginal = original * reservation.qty;
                final expiresAt = reservation.expiresAt;
                final reservedAt = reservation.createdAt;
                final pickupWindowText = formatPickupWindow(
                  pickupStartAt: reservation.pickupStartAt,
                  pickupEndAt: reservation.pickupEndAt,
                );
                final isPastExpiry =
                    expiresAt != null &&
                    !expiresAt.isAfter(DateTime.now()) &&
                    reservation.isReserved;
                String expiresText = 'Ismeretlen lejarat';
                if (expiresAt != null) {
                  expiresText = formatDateTime(expiresAt);
                }

                return ListTile(
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              child: const Icon(Icons.photo_outlined),
                            ),
                          ),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (merchantName.isNotEmpty)
                        Text('Kereskedo: $merchantName'),
                      Text('Kod: ${reservation.pickupCode}'),
                      Text('Mennyiseg: ${reservation.qty} db'),
                      if (reservedAt != null)
                        Text('Foglalva: ${formatDateTime(reservedAt)}'),
                      Text('Atvetel: $pickupWindowText'),
                      Text('Lejar: $expiresText'),
                      Text(
                        'Status: ${_reservationStatusLabel(reservation, isPastExpiry: isPastExpiry)}',
                      ),
                      if (reservation.isCancelled)
                        Text(
                          'Refund: ${refundStatusLabel(reservation.refundStatus)}',
                        ),
                    ],
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalDiscounted Ft',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (reservation.qty > 1 ||
                            totalOriginal > totalDiscounted)
                          Text.rich(
                            TextSpan(
                              children: [
                                if (reservation.qty > 1)
                                  TextSpan(text: '$discounted Ft / db'),
                                if (reservation.qty > 1 &&
                                    totalOriginal > totalDiscounted)
                                  const TextSpan(text: ' | '),
                                if (totalOriginal > totalDiscounted)
                                  TextSpan(
                                    text: '$totalOriginal Ft',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 11, height: 1.1),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReservationDetailScreen(
                          reservationId: reservation.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _reservationStatusLabel(
  Reservation reservation, {
  bool isPastExpiry = false,
}) {
  if (isPastExpiry) {
    return 'Lejart';
  }
  switch (reservation.status) {
    case 'completed':
      return 'Atadva';
    case 'cancelled':
      return 'Lemondva';
    case 'expired':
      return 'Lejart';
    default:
      return 'Foglalva';
  }
}
