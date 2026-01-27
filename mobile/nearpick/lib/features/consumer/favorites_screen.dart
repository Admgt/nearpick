import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/product_service.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _myInterestsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    // NOTE: Ha szeretnél orderBy(createdAt)-ot, lehet index kell.
    // Kezdésnek elég orderBy nélkül.
    return FirebaseFirestore.instance
        .collection('interests')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getProduct(String productId) {
    return FirebaseFirestore.instance.collection('products').doc(productId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kedvencek')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _myInterestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hiba a kedvencek betöltésekor: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final interestDocs = snapshot.data?.docs ?? [];

          if (interestDocs.isEmpty) {
            return const Center(
              child: Text('Még nincs kedvenc terméked.'),
            );
          }

          return ListView.separated(
            itemCount: interestDocs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = interestDocs[index].data();
              final productId = data['productId'] as String?;

              if (productId == null) {
                return const ListTile(
                  title: Text('Hibás kedvenc bejegyzés (productId hiányzik)'),
                );
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _getProduct(productId),
                builder: (context, productSnap) {
                  if (!productSnap.hasData) {
                    return const ListTile(
                      title: Text('Betöltés...'),
                    );
                  }

                  final productDoc = productSnap.data!;
                  if (!productDoc.exists) {
                    return ListTile(
                      title: const Text('A termék már nem elérhető'),
                      subtitle: Text('ID: $productId'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ProductService().unmarkInterestByRef(
                          interestRef: interestDocs[index].reference,
                          productId: productId,
                        );
                        },
                      ),
                    );
                  }

                  final p = productDoc.data()!;
                  final name = p['name'] as String? ?? 'Névtelen termék';
                  final category = p['category'] as String? ?? 'Ismeretlen kategória';
                  final discounted = p['discountedPrice'] as int? ?? 0;
                  final original = p['originalPrice'] as int? ?? 0;
                  final quantityAvailable =
                      p['quantityAvailable'] as int? ??
                      p['quantity'] as int? ??
                      0;
                  final expiresAt = (p['expiresAt'] as Timestamp?)?.toDate();

                  String expiresText = 'Ismeretlen lejárat';
                  if (expiresAt != null) {
                    expiresText =
                        'Lejár: ${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
                  }

                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

                    title: Text(name),
                    subtitle: Text(
                      '$category • $expiresText\n'
                      'Ár: $discounted Ft${(original > discounted) ? " (eredeti: $original Ft)" : ""} • Elérhető: $quantityAvailable db',
                    ),
                    isThreeLine: true,

                    trailing: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.favorite, size: 20),
                      tooltip: 'Eltávolítás a kedvencekből',
                      onPressed: () async {
                        await ProductService().unmarkInterestByRef(
                          interestRef: interestDocs[index].reference,
                          productId: productId,
                        );
                      },
                    ),

                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productId: productDoc.id,
                            data: p,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

