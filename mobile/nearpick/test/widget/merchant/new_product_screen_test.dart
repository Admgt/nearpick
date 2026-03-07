import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/features/merchant/new_product_form_logic.dart';
import 'package:nearpick/features/merchant/new_product_screen.dart';

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
  });
}
