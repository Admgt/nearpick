import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/app_error_message.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../ui/app_chrome.dart';
import '../../widgets/product_list_tile.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reservations_screen.dart';
import 'new_product_screen.dart';

class MerchantHomeScreen extends StatelessWidget {
  const MerchantHomeScreen({super.key});

  void _openTopDestination(
    BuildContext context,
    MerchantTopDestination destination,
  ) {
    switch (destination) {
      case MerchantTopDestination.home:
        return;
      case MerchantTopDestination.reservations:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MerchantReservationsScreen()),
        );
      case MerchantTopDestination.dashboard:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
        );
      case MerchantTopDestination.profile:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NearPick - Kereskedő'),
        actions: buildMerchantAppBarActions(
          context,
          current: MerchantTopDestination.home,
          onSelected: (destination) =>
              _openTopDestination(context, destination),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productService.myProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hiba a termékek betöltésekor: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final products = docs
              .map((doc) => Product.fromDoc(doc))
              .where((p) => !p.isDeleted)
              .toList();

          if (products.isEmpty) {
            return const Center(
              child: Text('Még nincs egyetlen feltöltött terméked sem.'),
            );
          }

          return NearPickBackground(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                final canEdit = !product.hasReservations;

                Future<void> archiveProduct() async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Biztosan torlod ezt a termeket?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Megse'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Igen'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                  try {
                    await productService.archiveProduct(productId: product.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Termek archivalt.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
                  }
                }

                final user = FirebaseAuth.instance.currentUser;
                final reservationStream = user == null
                    ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
                    : FirebaseFirestore.instance
                          .collection('reservations')
                          .where('merchantId', isEqualTo: user.uid)
                          .where('productId', isEqualTo: product.id)
                          .where('status', isEqualTo: 'reserved')
                          .snapshots();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: reservationStream,
                  builder: (context, reservationSnap) {
                    final reservedCount =
                        reservationSnap.data?.docs.length ?? 0;
                    return ProductListTile(
                      product: product,
                      reservedCount: reservedCount,
                      onEdit: canEdit
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NewProductScreen(initialProduct: product),
                                ),
                              );
                            }
                          : null,
                      onArchive: archiveProduct,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NewProductScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Uj termek'),
      ),
    );
  }
}
