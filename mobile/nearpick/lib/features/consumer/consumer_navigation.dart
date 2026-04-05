import 'package:flutter/material.dart';

enum ConsumerTopDestination { home, reservations, favorites, account }

extension ConsumerTopDestinationPresentation on ConsumerTopDestination {
  String get label {
    switch (this) {
      case ConsumerTopDestination.home:
        return 'Kezdolap';
      case ConsumerTopDestination.reservations:
        return 'Foglalasaim';
      case ConsumerTopDestination.favorites:
        return 'Kedvencek';
      case ConsumerTopDestination.account:
        return 'Fiokom';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsumerTopDestination.home:
        return Icons.home_outlined;
      case ConsumerTopDestination.reservations:
        return Icons.event_available_outlined;
      case ConsumerTopDestination.favorites:
        return Icons.favorite_outline;
      case ConsumerTopDestination.account:
        return Icons.person_outline;
    }
  }
}

List<Widget> buildConsumerAppBarActions(
  BuildContext context, {
  required ConsumerTopDestination current,
  required ValueChanged<ConsumerTopDestination> onSelected,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width < 900) {
    return [
      PopupMenuButton<ConsumerTopDestination>(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onSelected: (destination) {
          if (destination != current) {
            onSelected(destination);
          }
        },
        itemBuilder: (context) {
          return ConsumerTopDestination.values.map((destination) {
            final isCurrent = destination == current;
            return PopupMenuItem<ConsumerTopDestination>(
              value: destination,
              child: Row(
                children: [
                  Icon(destination.icon, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(destination.label)),
                  if (isCurrent) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.check, size: 18),
                  ],
                ],
              ),
            );
          }).toList();
        },
      ),
    ];
  }

  return [
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Wrap(
        spacing: 8,
        children: ConsumerTopDestination.values.map((destination) {
          final isCurrent = destination == current;
          return TextButton.icon(
            onPressed: isCurrent ? null : () => onSelected(destination),
            icon: Icon(destination.icon, size: 18),
            label: Text(destination.label),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
            ),
          );
        }).toList(),
      ),
    ),
  ];
}
