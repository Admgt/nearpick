// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../ui/app_chrome.dart';

class MerchantReservationsScreen extends StatefulWidget {
  const MerchantReservationsScreen({super.key});

  @override
  State<MerchantReservationsScreen> createState() =>
      _MerchantReservationsScreenState();
}

class _MerchantReservationsScreenState
    extends State<MerchantReservationsScreen> {
  final Set<String> _loadingIds = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Foglalasok')),
        body: const Center(child: Text('Nincs bejelentkezett felhasznalo.')),
      );
    }

    final reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('merchantId', isEqualTo: user.uid)
        .where('status', whereIn: ['reserved', 'completed'])
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Foglalasok')),
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
            return const Center(child: Text('Nincs foglalasod.'));
          }

          return NearPickBackground(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reservation = Reservation.fromDoc(docs[index]);
                final product = reservation.productSnapshot;
                final name = product['name'] as String? ?? 'Ismeretlen termek';
                final imageUrl = product['imageUrl'] as String?;
                final isReserved = reservation.status == 'reserved';

                return ListTile(
                  leading: imageUrl != null && imageUrl.isNotEmpty
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
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.photo_outlined),
                          ),
                        ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kod: ${reservation.pickupCode}'),
                      Text('Status: ${reservation.status}'),
                    ],
                  ),
                  trailing: isReserved
                      ? ElevatedButton(
                          onPressed: _loadingIds.contains(reservation.id)
                              ? null
                              : () async {
                                  setState(
                                    () => _loadingIds.add(reservation.id),
                                  );
                                  try {
                                    await ReservationService()
                                        .completeReservation(
                                          reservationId: reservation.id,
                                        );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(appErrorMessage(e)),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () =>
                                            _loadingIds.remove(reservation.id),
                                      );
                                    }
                                  }
                                },
                          child: const Text('Atadva'),
                        )
                      : const Text('Atadva'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
