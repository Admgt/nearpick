import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'new_product_screen.dart';
import 'merchant_dashboard_screen.dart';

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
                MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Dashboard',
          ),
          IconButton(
            onPressed: () => AuthService().logout(),
            icon: const Icon(Icons.logout),
          )
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

          if (docs.isEmpty) {
            return const Center(
              child: Text('Még nincs egyetlen feltöltött terméked sem.'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = data['name'] as String? ?? 'Névtelen termék';
              final category = data['category'] as String? ?? 'Ismeretlen kategória';
              final discounted = data['discountedPrice'] as int? ?? 0;
              final original = data['originalPrice'] as int? ?? 0;
              final quantity = data['quantity'] as int? ?? 0;
              final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

              String expiresText = 'Ismeretlen lejárat';
              if (expiresAt != null) {
                expiresText =
                    'Lejár: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
              }

              return ListTile(
                title: Text(name),
                subtitle: Text(
                  '$category\n$expiresText • Mennyiség: $quantity db',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$discounted Ft',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (original > discounted)
                      Text(
                        '$original Ft',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
