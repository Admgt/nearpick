import 'package:flutter/material.dart';

import '../../models/app_user_profile.dart';
import '../../models/product.dart';
import '../../models/reservation.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'admin_support.dart';

class AdminReservationDetailScreen extends StatelessWidget {
  final Reservation reservation;
  final Product? product;
  final AppUserProfile? buyer;
  final AppUserProfile? merchant;

  const AdminReservationDetailScreen({
    super.key,
    required this.reservation,
    required this.product,
    required this.buyer,
    required this.merchant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foglalas: ${reservation.id}')),
      body: NearPickBackground(
        maxWidth: 920,
        child: SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservationProductLabel(
                  reservation: reservation,
                  productsById: {if (product != null) product!.id: product!},
                ),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  InfoBadge(
                    icon: Icons.sell_outlined,
                    label: 'Statusz',
                    value: reservationStatusLabel(reservation),
                    tint: reservationStatusColor(context, reservation),
                  ),
                  InfoBadge(
                    icon: Icons.production_quantity_limits_outlined,
                    label: 'Mennyiseg',
                    value: '${reservation.qty} db',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Vasarlo: ${buyer?.primaryLabel ?? reservation.buyerId}'),
              const SizedBox(height: 8),
              Text(
                'Kereskedo: ${merchant?.primaryLabel ?? reservation.merchantId}',
              ),
              const SizedBox(height: 8),
              Text('Atveteli kod: ${reservation.pickupCode}'),
              const SizedBox(height: 8),
              Text(
                'Letrehozva: ${reservation.createdAt == null ? 'Nincs adat' : formatDateTime(reservation.createdAt!)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Lejarat: ${reservation.expiresAt == null ? 'Nincs adat' : formatDateTime(reservation.expiresAt!)}',
              ),
              if (reservation.completedAt != null) ...[
                const SizedBox(height: 8),
                Text('Completed: ${formatDateTime(reservation.completedAt!)}'),
              ],
              if (reservation.cancelledAt != null) ...[
                const SizedBox(height: 8),
                Text('Lemondva: ${formatDateTime(reservation.cancelledAt!)}'),
              ],
              if (reservation.cancelReasonCode != null) ...[
                const SizedBox(height: 8),
                Text('Lemondasi ok: ${reservation.cancelReasonCode}'),
              ],
              const SizedBox(height: 8),
              Text('Refund statusz: ${reservation.refundStatus}'),
              const SizedBox(height: 8),
              Text(
                'Atveteli ablak: ${formatPickupWindow(pickupStartAt: reservation.pickupStartAt, pickupEndAt: reservation.pickupEndAt)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
