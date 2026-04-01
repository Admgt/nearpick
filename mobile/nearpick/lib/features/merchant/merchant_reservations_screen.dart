// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../reservation/reservation_support.dart';
import '../../core/reservation/pickup_token.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../ui/app_chrome.dart';
import 'merchant_reservation_detail_screen.dart';
import 'merchant_qr_scanner_screen.dart';

class MerchantReservationsScreen extends StatefulWidget {
  const MerchantReservationsScreen({super.key});

  @override
  State<MerchantReservationsScreen> createState() =>
      _MerchantReservationsScreenState();
}

class _MerchantReservationsScreenState
    extends State<MerchantReservationsScreen> {
  final Set<String> _loadingIds = {};

  Future<void> _openReservationDetail({
    required String reservationId,
    String? pickupInput,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MerchantReservationDetailScreen(
          reservationId: reservationId,
          initialPickupInput: pickupInput,
        ),
      ),
    );
  }

  Future<void> _handlePickupInput({
    required String pickupInput,
    required String merchantId,
  }) async {
    try {
      final parsed = parsePickupToken(pickupInput);
      final reservationId =
          parsed.reservationId ??
          await ReservationService().findReservationIdByPickupCode(
            merchantId: merchantId,
            pickupCode: parsed.pickupCode,
          );
      if (!mounted) return;
      if (reservationId == null || reservationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nem talalhato foglalas ehhez a kodhoz.'),
          ),
        );
        return;
      }
      await _openReservationDetail(
        reservationId: reservationId,
        pickupInput: pickupInput,
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    }
  }

  Future<String?> _promptPickupInput(Reservation reservation) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('QR vagy atveteli kod'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add meg a vasarlo altal bemutatott QR tokent vagy az atveteli kodot.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'QR token vagy kod',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final scanned = await Navigator.of(dialogContext)
                        .push<String>(
                          MaterialPageRoute(
                            builder: (_) => const MerchantQrScannerScreen(),
                          ),
                        );
                    if (scanned == null || scanned.isEmpty) return;
                    controller.text = scanned;
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  label: const Text('Kamera megnyitasa'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Varhato kod: ${reservation.pickupCode}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Megse'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Ellenorzes'),
            ),
          ],
        ),
      ),
    );
  }

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
        .where(
          'status',
          whereIn: ['reserved', 'completed', 'expired', 'cancelled'],
        )
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foglalasok'),
        actions: [
          IconButton(
            onPressed: () async {
              final scanned = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => const MerchantQrScannerScreen(),
                ),
              );
              if (!mounted || scanned == null || scanned.isEmpty) return;
              await _handlePickupInput(
                pickupInput: scanned,
                merchantId: user.uid,
              );
            },
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'QR scanner',
          ),
        ],
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
                final expiresAt = reservation.expiresAt;
                final isPastExpiry =
                    expiresAt != null &&
                    !expiresAt.isAfter(DateTime.now()) &&
                    reservation.isReserved;
                final isReserved =
                    reservation.status == 'reserved' && !isPastExpiry;
                final refundText = reservation.isCancelled
                    ? 'Refund: ${refundStatusLabel(reservation.refundStatus)}'
                    : null;
                String expiresText = 'Ismeretlen lejarat';
                if (expiresAt != null) {
                  expiresText =
                      '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')} '
                      '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';
                }

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
                      Text('Lejar: $expiresText'),
                      Text(
                        'Status: ${_merchantReservationStatusLabel(reservation, isPastExpiry: isPastExpiry)}',
                      ),
                      if (reservation.isCancelled)
                        Text(
                          'Ok: ${cancellationReasonLabel(reservation.cancelReasonCode)}',
                        ),
                      if (refundText != null) Text(refundText),
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
                                    final pickupInput =
                                        await _promptPickupInput(reservation);
                                    if (!mounted ||
                                        pickupInput == null ||
                                        pickupInput.isEmpty) {
                                      return;
                                    }
                                    await _handlePickupInput(
                                      pickupInput: pickupInput,
                                      merchantId: user.uid,
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
                          child: const Text('QR atvetel'),
                        )
                      : Text(
                          _merchantReservationStatusLabel(
                            reservation,
                            isPastExpiry: isPastExpiry,
                          ),
                        ),
                  onTap: () =>
                      _openReservationDetail(reservationId: reservation.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _merchantReservationStatusLabel(
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
