import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_list_tile.dart';
import 'new_product_screen.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_reservations_screen.dart';

class MerchantHomeScreen extends StatelessWidget {
  const MerchantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NearPick - Kereskedő'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MerchantReservationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Foglalasok',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MerchantDashboardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Dashboard',
          ),
          IconButton(
            onPressed: () => AuthService().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
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

          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];

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
                  ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
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
                  final reservedCount = reservationSnap.data?.docs.length ?? 0;
                  return ProductListTile(
                    product: product,
                    reservedCount: reservedCount,
                    onArchive: archiveProduct,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NewProductScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
