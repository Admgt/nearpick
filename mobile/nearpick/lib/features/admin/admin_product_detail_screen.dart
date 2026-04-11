import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../models/app_user_profile.dart';
import '../../models/product.dart';
import '../../models/reservation.dart';
import '../../services/admin_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'admin_support.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Product product;
  final AppUserProfile? merchant;
  final List<Reservation> reservations;
  final AdminService adminService;

  const AdminProductDetailScreen({
    super.key,
    required this.product,
    required this.merchant,
    required this.reservations,
    required this.adminService,
  });

  @override
  State<AdminProductDetailScreen> createState() =>
      _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  bool _actionLoading = false;

  Future<void> _hideProduct() async {
    setState(() => _actionLoading = true);
    try {
      await widget.adminService.hideProduct(productId: widget.product.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A termek elrejtve.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _restoreProduct() async {
    setState(() => _actionLoading = true);
    try {
      await widget.adminService.restoreProduct(productId: widget.product.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A termek ujra lathato.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    setState(() => _actionLoading = true);
    try {
      await widget.adminService.deleteProduct(productId: widget.product.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A termek archivalt torlest kapott.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final merchant = widget.merchant;
    final isHidden = product.effectiveStatus == 'hidden';

    return Scaffold(
      appBar: AppBar(title: Text('Termek: ${product.name}')),
      body: NearPickBackground(
        maxWidth: 980,
        child: ListView(
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      InfoBadge(
                        icon: Icons.category_outlined,
                        label: 'Kategoria',
                        value: product.category,
                      ),
                      InfoBadge(
                        icon: Icons.visibility_outlined,
                        label: 'Statusz',
                        value: productStatusLabel(product),
                        tint: productStatusColor(context, product),
                      ),
                      InfoBadge(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Foglalasok',
                        value: '${widget.reservations.length} db',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kereskedo: ${merchant?.primaryLabel ?? product.merchantName}',
                  ),
                  const SizedBox(height: 8),
                  Text('Listaar: ${product.originalPrice} Ft'),
                  const SizedBox(height: 8),
                  Text('Kedvezmenyes ar: ${product.discountedPrice} Ft'),
                  const SizedBox(height: 8),
                  Text(
                    'Elerheto mennyiseg: ${product.quantityAvailable} / ${product.quantity}',
                  ),
                  if (product.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Letrehozva: ${formatDateTime(product.createdAt!)}'),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: _actionLoading
                            ? null
                            : isHidden
                            ? _restoreProduct
                            : _hideProduct,
                        child: Text(isHidden ? 'Visszaallitas' : 'Elrejtes'),
                      ),
                      OutlinedButton(
                        onPressed: _actionLoading ? null : _deleteProduct,
                        child: const Text('Torles'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kapcsolodo foglalasok',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (widget.reservations.isEmpty)
                    const Text('Ehhez a termekhez nincs foglalas.')
                  else
                    ...widget.reservations.take(12).map((reservation) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(reservationStatusLabel(reservation)),
                        subtitle: Text(
                          reservation.createdAt == null
                              ? 'Nincs datum'
                              : formatDateTime(reservation.createdAt!),
                        ),
                        trailing: Text('${reservation.qty} db'),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
