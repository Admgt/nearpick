// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/error/app_error_message.dart';
import '../reservation/reservation_support.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../ui/app_chrome.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _cancelling = false;

  Future<_CancelReservationFormResult?> _showCancelReservationDialog() {
    String selectedReason = cancellationReasonOptions.first.code;
    bool refundRequested = false;
    final noteController = TextEditingController();

    return showDialog<_CancelReservationFormResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Foglalas lemondasa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(labelText: 'Lemondasi ok'),
                  items: cancellationReasonOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.code,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedReason = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Megjegyzes a kereskedonek',
                    hintText: 'Opcionális reszletek',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: refundRequested,
                  title: const Text('Refund/kompenzacio igenylese'),
                  subtitle: const Text('A kereskedo manualisan tudja kezelni.'),
                  onChanged: (value) => setDialogState(() {
                    refundRequested = value ?? false;
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Megse'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                _CancelReservationFormResult(
                  reasonCode: selectedReason,
                  reasonNote: noteController.text.trim(),
                  refundRequested: refundRequested,
                ),
              ),
              child: const Text('Lemondas rogzitese'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    final formResult = await _showCancelReservationDialog();
    if (!mounted || formResult == null) {
      return;
    }

    setState(() => _cancelling = true);
    try {
      await ReservationService().cancelReservation(
        reservationId: reservationId,
        reasonCode: formResult.reasonCode,
        reasonNote: formResult.reasonNote,
        refundRequested: formResult.refundRequested,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foglalas lemondva.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationStream = FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.reservationId)
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
          final isPastExpiry =
              expiresAt != null &&
              !expiresAt.isAfter(DateTime.now()) &&
              reservation.isReserved;
          final canCancel = reservation.isReserved && !isPastExpiry;
          final cancelReasonText = cancellationReasonLabel(
            reservation.cancelReasonCode,
          );
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
                          if (reservation.pickupToken.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'QR kod az atvetelhez',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: QrImageView(
                                data: reservation.pickupToken,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(reservation.pickupToken),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${_reservationStatusLabel(reservation, isPastExpiry: isPastExpiry)}',
                          ),
                          if (reservation.isReserved && expiresAt != null)
                            Text('Atvetel vege: $expiresText'),
                          if (reservation.isCancelled) ...[
                            const SizedBox(height: 8),
                            Text('Lemondasi ok: $cancelReasonText'),
                            if (reservation.cancelReasonNote.isNotEmpty)
                              Text(
                                'Megjegyzes: ${reservation.cancelReasonNote}',
                              ),
                            Text(
                              'Refund statusz: ${refundStatusLabel(reservation.refundStatus)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canCancel) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _cancelling
                              ? null
                              : () => _cancelReservation(reservation.id),
                          icon: _cancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close_outlined),
                          label: const Text('Foglalas lemondasa'),
                        ),
                      ),
                    ],
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

class _CancelReservationFormResult {
  final String reasonCode;
  final String reasonNote;
  final bool refundRequested;

  const _CancelReservationFormResult({
    required this.reasonCode,
    required this.reasonNote,
    required this.refundRequested,
  });
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
