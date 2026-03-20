// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/reservation.dart';
import '../../ui/app_chrome.dart';

class ReservationDetailScreen extends StatelessWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    final reservationStream = FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Foglalas reszletei')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: reservationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('A foglalas nem talalhato.'));
          }

          final reservation = Reservation.fromDoc(snapshot.data!);
          final product = reservation.productSnapshot;
          final name = product['name'] as String? ?? 'Ismeretlen termek';
          final imageUrl = product['imageUrl'] as String?;
          final discounted = product['discountedPrice'] as int? ?? 0;
          final original = product['originalPrice'] as int? ?? 0;
          final category = product['category'] as String? ?? '';
          final expiresAt = reservation.expiresAt;
          String expiresText = 'Ismeretlen lejarat';
          if (expiresAt != null) {
            expiresText =
                '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')} '
                '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';
          }

          return NearPickBackground(
            maxWidth: 720,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (category.isNotEmpty) Text('Kategoria: $category'),
                    const SizedBox(height: 8),
                    Text('Lejar: $expiresText'),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foglalasi kod',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            reservation.pickupCode,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${reservation.status}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
