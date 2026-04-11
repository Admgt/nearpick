import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nearpick/features/admin/admin_product_detail_screen.dart';
import 'package:nearpick/models/app_user_profile.dart';
import 'package:nearpick/models/product.dart';
import 'package:nearpick/models/reservation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can hide and archive a product from the detail screen', (
    tester,
  ) async {
    final actions = <String>[];

    await tester.pumpWidget(
      _AdminProductModerationApp(
        product: _product(),
        merchant: _merchant(),
        reservations: [_reservation()],
        onHideProduct: (productId) async => actions.add('hide:$productId'),
        onDeleteProduct: (productId) async => actions.add('delete:$productId'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Termek: Bagel box'), findsOneWidget);
    expect(find.text('Kereskedo: Demo Merchant'), findsOneWidget);
    expect(find.text('Foglalasok'), findsWidgets);
    expect(find.text('1 db'), findsWidgets);

    final hideButton = find.text('Elrejtes');
    await tester.ensureVisible(hideButton);
    await tester.tap(hideButton);
    await tester.pumpAndSettle();

    expect(actions, contains('hide:product-1'));
    expect(find.text('A termek elrejtve.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final deleteButton = find.text('Torles');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(actions, contains('delete:product-1'));
    expect(find.text('A termek archivalt torlest kapott.'), findsOneWidget);
  });

  testWidgets('admin can restore a hidden product from the detail screen', (
    tester,
  ) async {
    final actions = <String>[];

    await tester.pumpWidget(
      _AdminProductModerationApp(
        product: _product(status: 'hidden'),
        merchant: _merchant(),
        reservations: const [],
        onRestoreProduct: (productId) async =>
            actions.add('restore:$productId'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statusz'), findsOneWidget);
    expect(find.text('Elrejtve'), findsOneWidget);

    final restoreButton = find.text('Visszaallitas');
    await tester.ensureVisible(restoreButton);
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();

    expect(actions, contains('restore:product-1'));
    expect(find.text('A termek ujra lathato.'), findsOneWidget);
  });
}

class _AdminProductModerationApp extends StatelessWidget {
  final Product product;
  final AppUserProfile? merchant;
  final List<Reservation> reservations;
  final AdminProductAction? onHideProduct;
  final AdminProductAction? onRestoreProduct;
  final AdminProductAction? onDeleteProduct;

  const _AdminProductModerationApp({
    required this.product,
    required this.merchant,
    required this.reservations,
    this.onHideProduct,
    this.onRestoreProduct,
    this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearPick Admin Product Integration Flow Harness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: AdminProductDetailScreen(
        product: product,
        merchant: merchant,
        reservations: reservations,
        onHideProduct: onHideProduct,
        onRestoreProduct: onRestoreProduct,
        onDeleteProduct: onDeleteProduct,
      ),
    );
  }
}

Product _product({String status = 'active'}) {
  return Product(
    id: 'product-1',
    ownerId: 'merchant-1',
    merchantName: 'Demo Bakery',
    name: 'Bagel box',
    category: 'Peksutemeny',
    originalPrice: 1000,
    discountedPrice: 490,
    quantity: 4,
    quantityAvailable: 2,
    expiresAt: DateTime(2026, 4, 11, 18),
    pickupStartAt: DateTime(2026, 4, 11, 16),
    pickupEndAt: DateTime(2026, 4, 11, 18),
    createdAt: DateTime(2026, 4, 11, 9),
    location: null,
    interestCount: 3,
    status: status,
    isDeleted: false,
    archivedAt: null,
    deletedAt: null,
    imageUrl: null,
    imagePath: null,
    thumbnailPath: null,
    hasImage: false,
    hasReservations: true,
    pricingRecommendation: null,
  );
}

AppUserProfile _merchant() {
  return AppUserProfile(
    id: 'merchant-1',
    email: 'merchant@example.com',
    displayName: 'Demo Merchant',
    role: 'merchant',
    accountStatus: 'active',
    companyName: 'Demo Bakery',
    companyLocation: null,
    createdAt: DateTime(2026, 4, 1),
  );
}

Reservation _reservation() {
  return Reservation(
    id: 'reservation-1',
    productId: 'product-1',
    merchantId: 'merchant-1',
    buyerId: 'buyer-1',
    qty: 2,
    status: 'reserved',
    createdAt: DateTime(2026, 4, 11, 10),
    expiresAt: DateTime(2026, 4, 11, 18),
    completedAt: null,
    cancelledAt: null,
    expiredAt: null,
    pickupCode: 'ABC123',
    pickupToken: 'pickup-token-reservation-1',
    cancelReasonCode: null,
    cancelReasonNote: '',
    cancelledBy: null,
    refundStatus: 'not_requested',
    refundRequestedAt: null,
    refundReviewedAt: null,
    refundCompletedAt: null,
    refundReviewedBy: null,
    reviewSubmittedAt: null,
    productSnapshot: {
      'name': 'Bagel box',
      'category': 'Peksutemeny',
      'discountedPrice': 490,
      'originalPrice': 1000,
      'merchantName': 'Demo Bakery',
    },
  );
}
