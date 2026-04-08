import 'package:flutter/material.dart';

enum MerchantTopDestination { home, reservations, dashboard, profile }

extension MerchantTopDestinationPresentation on MerchantTopDestination {
  String get label {
    switch (this) {
      case MerchantTopDestination.home:
        return 'Fooldal';
      case MerchantTopDestination.reservations:
        return 'Foglalasok';
      case MerchantTopDestination.dashboard:
        return 'Dashboard';
      case MerchantTopDestination.profile:
        return 'Profil';
    }
  }

  IconData get icon {
    switch (this) {
      case MerchantTopDestination.home:
        return Icons.home_outlined;
      case MerchantTopDestination.reservations:
        return Icons.list_alt_outlined;
      case MerchantTopDestination.dashboard:
        return Icons.analytics_outlined;
      case MerchantTopDestination.profile:
        return Icons.person_outline;
    }
  }
}

List<Widget> buildMerchantAppBarActions(
  BuildContext context, {
  MerchantTopDestination? current,
  required ValueChanged<MerchantTopDestination> onSelected,
}) {
  final isCompact = MediaQuery.sizeOf(context).width < 900;

  if (isCompact) {
    return [
      PopupMenuButton<MerchantTopDestination>(
        tooltip: 'Kereskedoi menü',
        icon: const Icon(Icons.more_vert),
        onSelected: onSelected,
        itemBuilder: (context) =>
            MerchantTopDestination.values.map((destination) {
              final isCurrent = destination == current;
              return PopupMenuItem<MerchantTopDestination>(
                value: destination,
                enabled: !isCurrent,
                child: Row(
                  children: [
                    Icon(destination.icon, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              );
            }).toList(),
      ),
    ];
  }

  return [
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Wrap(
        spacing: 8,
        children: MerchantTopDestination.values.map((destination) {
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
