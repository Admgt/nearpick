import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../ui/app_chrome.dart';

class AccountStatusScreen extends StatelessWidget {
  final String accountStatus;

  const AccountStatusScreen({super.key, required this.accountStatus});

  String get _title {
    switch (accountStatus) {
      case 'blocked':
        return 'A fiok tiltva van';
      case 'suspended':
        return 'A fiok fel van fuggesztve';
      default:
        return 'A fiok nem erheto el';
    }
  }

  String get _message {
    switch (accountStatus) {
      case 'blocked':
        return 'Ez a fiok adminisztratori tiltast kapott, ezert a NearPick jelenleg nem hasznalhato vele.';
      case 'suspended':
        return 'Ez a fiok ideiglenesen fel van fuggesztve. Lepj kapcsolatba az adminisztratorral a reszletekert.';
      default:
        return 'A fiok allapota miatt a rendszerhez jelenleg nincs hozzaferes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearPick - Hozzaferes korlatozva')),
      body: NearPickBackground(
        maxWidth: 640,
        child: Center(
          child: SurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  accountStatus == 'blocked'
                      ? Icons.block_outlined
                      : Icons.pause_circle_outline,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => AuthService().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Kijelentkezes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
