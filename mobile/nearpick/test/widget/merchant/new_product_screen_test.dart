import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/merchant/dynamic_pricing.dart';
import 'package:nearpick/features/merchant/new_product_form_logic.dart';
import 'package:nearpick/features/merchant/new_product_screen.dart';
import 'package:nearpick/models/product.dart';

void main() {
  testWidgets('NewProductScreen requires expiry selection before save', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NewProductScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Bagel');
    await tester.enterText(find.byType(TextFormField).at(1), '1000');
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    await tester.enterText(find.byType(TextFormField).at(3), '1');
    final saveButton = find.widgetWithText(ElevatedButton, 'Mentes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Kerlek valaszd ki a lejarati datumot.'), findsOneWidget);
  });

  testWidgets('NewProductScreen parses inputs and calls save callback', (
    tester,
  ) async {
    NewProductCommand? receivedCommand;

    await tester.pumpWidget(
      MaterialApp(
        home: NewProductScreen(
          initialExpiry: DateTime(2026, 3, 7),
          onSaveProduct: (command) async {
            receivedCommand = command;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Bagel');
    await tester.enterText(find.byType(TextFormField).at(1), '1000');
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.enterText(find.byType(TextFormField).at(4), '47.5');
    await tester.enterText(find.byType(TextFormField).at(5), '19.0');
    final saveButton = find.widgetWithText(ElevatedButton, 'Mentes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(receivedCommand, isNotNull);
    expect(receivedCommand?.name, 'Bagel');
    expect(receivedCommand?.originalPrice, 1000);
    expect(receivedCommand?.discountedPrice, 500);
    expect(receivedCommand?.quantity, 2);
    expect(receivedCommand?.location?.latitude, 47.5);
    expect(receivedCommand?.location?.longitude, 19.0);
    expect(receivedCommand?.pickupStartAt, DateTime(2026, 3, 7, 9));
    expect(receivedCommand?.pickupEndAt, DateTime(2026, 3, 7, 18));
  });

  testWidgets('NewProductScreen can generate and apply pricing suggestion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewProductScreen(
          initialExpiry: DateTime(2026, 3, 7),
          onGeneratePricingRecommendation:
              ({
                required String category,
                required int originalPrice,
                required int quantity,
                required DateTime expiresAt,
              }) async {
                return const DynamicPricingRecommendation(
                  recommendedPrice: 650,
                  minimumSuggestedPrice: 600,
                  maximumSuggestedPrice: 700,
                  discountPercent: 35,
                  demandScore: 0.62,
                  demandLevel: 'medium',
                  expectedReservations24h: 3,
                  marketSnapshot: MerchantMarketSnapshot(
                    views7d: 12,
                    interests7d: 4,
                    dismissals7d: 1,
                    activeCategoryOffers: 2,
                    averageDiscountRatio: 0.22,
                  ),
                  reasons: [
                    PricingReason(
                      label: 'Kategoria kereslet',
                      detail: 'Teszt jel',
                      weight: 0.8,
                    ),
                  ],
                );
              },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Bagel');
    await tester.enterText(find.byType(TextFormField).at(1), '1000');
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    await tester.enterText(find.byType(TextFormField).at(3), '2');

    final pricingButton = find.byKey(
      const ValueKey('new_product_pricing_button'),
    );
    await tester.ensureVisible(pricingButton);
    await tester.tap(pricingButton);
    await tester.pumpAndSettle();

    expect(find.text('Javasolt akcios ar: 650 Ft'), findsOneWidget);
    expect(find.textContaining('Becsult kereslet: kozepes'), findsOneWidget);

    final applyButton = find.byKey(
      const ValueKey('new_product_apply_pricing_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final discountedPriceField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('new_product_discounted_price_field')),
    );
    expect(discountedPriceField.controller?.text, '650');
  });

  testWidgets('NewProductScreen preloads product data in edit mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewProductScreen(
          initialProduct: Product(
            id: 'product-1',
            ownerId: 'merchant-1',
            merchantName: 'Pekseg',
            name: 'Bagel',
            category: 'Peksutemeny',
            originalPrice: 1000,
            discountedPrice: 500,
            quantity: 2,
            quantityAvailable: 2,
            expiresAt: DateTime(2026, 3, 7, 23, 59),
            pickupStartAt: DateTime(2026, 3, 7, 9),
            pickupEndAt: DateTime(2026, 3, 7, 18),
            createdAt: DateTime(2026, 3, 1),
            location: null,
            interestCount: 0,
            status: 'active',
            isDeleted: false,
            archivedAt: null,
            deletedAt: null,
            imageUrl: null,
            imagePath: null,
            thumbnailPath: null,
            hasImage: false,
            hasReservations: false,
            pricingRecommendation: null,
          ),
        ),
      ),
    );

    expect(find.text('Termek szerkesztese'), findsOneWidget);
    expect(find.text('Modositas mentese'), findsOneWidget);

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('new_product_name_field')),
    );
    final quantityField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('new_product_quantity_field')),
    );

    expect(nameField.controller?.text, 'Bagel');
    expect(quantityField.controller?.text, '2');
  });
}
