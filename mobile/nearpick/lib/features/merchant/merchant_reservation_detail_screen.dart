// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../reservation/reservation_support.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_home_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reservations_screen.dart';
import 'merchant_qr_scanner_screen.dart';

class MerchantReservationDetailScreen extends StatefulWidget {
  final String reservationId;
  final String? initialPickupInput;

  const MerchantReservationDetailScreen({
    super.key,
    required this.reservationId,
    this.initialPickupInput,
  });

  @override
  State<MerchantReservationDetailScreen> createState() =>
      _MerchantReservationDetailScreenState();
}

class _MerchantReservationDetailScreenState
    extends State<MerchantReservationDetailScreen> {
  final TextEditingController _pickupInputController = TextEditingController();
  bool _submitting = false;
  String? _refundUpdatingStatus;

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
        );
      case MerchantTopDestination.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _pickupInputController.text = widget.initialPickupInput?.trim() ?? '';
  }

  @override
  void dispose() {
    _pickupInputController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const MerchantQrScannerScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;
    setState(() => _pickupInputController.text = scanned);
  }

  Future<void> _completeReservation(Reservation reservation) async {
    final pickupInput = _pickupInputController.text.trim();
    if (pickupInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adj meg QR tokent vagy atveteli kodot.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ReservationService().completeReservation(
        reservationId: reservation.id,
        pickupInput: pickupInput,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atvetel sikeresen rogzitve.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _updateRefundStatus({
    required Reservation reservation,
    required String refundStatus,
  }) async {
    setState(() => _refundUpdatingStatus = refundStatus);
    try {
      await ReservationService().updateRefundStatus(
        reservationId: reservation.id,
        refundStatus: refundStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refund statusz frissitve: ${refundStatusLabel(refundStatus)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _refundUpdatingStatus = null);
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
      appBar: AppBar(
        title: const Text('Foglalas reszletei'),
        actions: buildMerchantAppBarActions(
          context,
          onSelected: _openTopDestination,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: reservationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(appErrorMessage(snapshot.error!)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('A foglalas nem talalhato.'));
          }

          final reservation = Reservation.fromDoc(snapshot.data!);
          final product = reservation.productSnapshot;
          final name = product['name'] as String? ?? 'Ismeretlen termek';
          final category = product['category'] as String? ?? '';
          final discounted = product['discountedPrice'] as int? ?? 0;
          final original = product['originalPrice'] as int? ?? 0;
          final totalDiscounted = discounted * reservation.qty;
          final totalOriginal = original * reservation.qty;
          final imageUrl = product['imageUrl'] as String?;
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
          final canComplete = reservation.isReserved && !isPastExpiry;
          final canManageRefund = reservation.isCancelled;

          String expiresText = 'Ismeretlen lejarat';
          if (expiresAt != null) {
            expiresText = formatDateTime(expiresAt);
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
                    if (reservedAt != null) ...[
                      const SizedBox(height: 8),
                      Text('Foglalva: ${formatDateTime(reservedAt)}'),
                    ],
                    const SizedBox(height: 8),
                    Text('Mennyiseg: ${reservation.qty} db'),
                    const SizedBox(height: 8),
                    Text('Atveteli idosav: $pickupWindowText'),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_merchantReservationStatusLabel(reservation, isPastExpiry: isPastExpiry)}',
                    ),
                    if (reservation.isCancelled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lemondasi ok: ${cancellationReasonLabel(reservation.cancelReasonCode)}',
                      ),
                      if (reservation.cancelReasonNote.isNotEmpty)
                        Text('Megjegyzes: ${reservation.cancelReasonNote}'),
                      Text(
                        'Refund statusz: ${refundStatusLabel(reservation.refundStatus)}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$totalDiscounted Ft',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (totalOriginal > totalDiscounted)
                          Text(
                            '$totalOriginal Ft',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Egyseg ar: $discounted Ft / db'),
                    if (canComplete) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Atveteli kod: ${reservation.pickupCode}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pickupInputController,
                        decoration: const InputDecoration(
                          labelText: 'QR token vagy atveteli kod',
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openScanner,
                              icon: const Icon(Icons.qr_code_scanner_outlined),
                              label: const Text('QR ujrabeolvasas'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !_submitting
                                  ? () => _completeReservation(reservation)
                                  : null,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.task_alt_outlined),
                              label: const Text('Atvetel rogzitese'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (canManageRefund) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Refund kezeles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: merchantRefundStatusOptions
                            .map(
                              (option) => OutlinedButton(
                                onPressed:
                                    _refundUpdatingStatus != null ||
                                        option.code == reservation.refundStatus
                                    ? null
                                    : () => _updateRefundStatus(
                                        reservation: reservation,
                                        refundStatus: option.code,
                                      ),
                                child: _refundUpdatingStatus == option.code
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(option.label),
                              ),
                            )
                            .toList(),
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
