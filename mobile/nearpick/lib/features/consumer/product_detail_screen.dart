import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/user_interaction_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> data;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.data,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loading = false;
  String? _message;
  bool _viewLogged = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _interestDocStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    final docId = '${user.uid}_${widget.productId}';
    return FirebaseFirestore.instance
        .collection('interests')
        .doc(docId)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _logViewIfNeeded();
  }

  Future<void> _logViewIfNeeded() async {
    if (_viewLogged) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final category = (widget.data['category'] as String?)?.trim() ?? '';
    if (category.isEmpty) return;

    _viewLogged = true;
    try {
      await UserInteractionService().logProductView(
        uid: user.uid,
        productId: widget.productId,
        category: category,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final name = data['name'] as String? ?? 'Névtelen termék';
    final category = data['category'] as String? ?? 'Ismeretlen kategória';
    final discounted = data['discountedPrice'] as int? ?? 0;
    final original = data['originalPrice'] as int? ?? 0;
    final quantity = data['quantity'] as int? ?? 0;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

    String expiresText = 'Ismeretlen lejárat';
    if (expiresAt != null) {
      expiresText =
          '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}  ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Termék részletei')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Kategória: $category'),
            const SizedBox(height: 8),
            Text('Lejárat: $expiresText'),
            const SizedBox(height: 8),
            Text('Elérhető: $quantity db'),
            const SizedBox(height: 16),

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

            const Spacer(),

            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('OK') ? Colors.green : Colors.red,
                  ),
                ),
              ),

            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _interestDocStream(),
              builder: (context, snap) {
                final isFavorite = snap.data?.exists ?? false;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() {
                              _loading = true;
                              _message = null;
                            });

                            try {
                              if (isFavorite) {
                                await ProductService()
                                    .unmarkInterest(productId: widget.productId);
                                setState(() => _message = 'OK: Eltávolítva a kedvencekből.');
                              } else {
                                await ProductService()
                                    .markInterest(productId: widget.productId);
                                setState(() => _message = 'OK: Hozzáadva a kedvencekhez.');
                              }
                            } catch (e) {
                              setState(() => _message = 'Hiba: $e');
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                    label: Text(isFavorite ? 'Eltávolítás a kedvencekből' : 'Kedvenc'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
