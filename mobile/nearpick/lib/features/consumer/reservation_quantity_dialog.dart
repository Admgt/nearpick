import 'package:flutter/material.dart';

Future<int?> showReservationQuantityDialog({
  required BuildContext context,
  required String productName,
  required int quantityAvailable,
  required int unitPrice,
}) {
  var selectedQuantity = 1;
  final safeQuantityAvailable = quantityAvailable < 1 ? 1 : quantityAvailable;

  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final totalPrice = unitPrice * selectedQuantity;
        return AlertDialog(
          title: const Text('Foglalasi mennyiseg'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName.trim().isEmpty
                    ? 'Valaszd ki, hany darabot szeretnel lefoglalni.'
                    : '$productName\nValaszd ki, hany darabot szeretnel lefoglalni.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedQuantity,
                decoration: const InputDecoration(labelText: 'Darabszam'),
                items:
                    List.generate(
                      safeQuantityAvailable,
                      (index) => index + 1,
                    ).map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value db'),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedQuantity = value);
                },
              ),
              const SizedBox(height: 12),
              Text('Elerheto: $safeQuantityAvailable db'),
              Text('Ar: $unitPrice Ft / db'),
              Text(
                'Osszesen: $totalPrice Ft',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Megse'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(selectedQuantity),
              child: const Text('Foglalas'),
            ),
          ],
        );
      },
    ),
  );
}
