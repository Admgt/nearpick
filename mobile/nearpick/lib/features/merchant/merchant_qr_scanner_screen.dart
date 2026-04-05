import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'merchant_dashboard_screen.dart';
import 'merchant_home_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reservations_screen.dart';

class MerchantQrScannerScreen extends StatefulWidget {
  const MerchantQrScannerScreen({super.key});

  @override
  State<MerchantQrScannerScreen> createState() =>
      _MerchantQrScannerScreenState();
}

class _MerchantQrScannerScreenState extends State<MerchantQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;
  bool _torchOn = false;

  void _openTopDestination(MerchantTopDestination destination) {
    switch (destination) {
      case MerchantTopDestination.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantHomeScreen()),
        );
      case MerchantTopDestination.reservations:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantReservationsScreen()),
        );
      case MerchantTopDestination.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
        );
      case MerchantTopDestination.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
        );
    }
  }

  bool get _isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) {
        continue;
      }
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR scanner'),
          actions: buildMerchantAppBarActions(
            context,
            onSelected: _openTopDestination,
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ez a platform nem tamogatja a kameraalapu QR beolvasast. '
              'Hasznald a kezi token vagy kod bevitelt.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR scanner'),
        actions: [
          ...buildMerchantAppBarActions(
            context,
            onSelected: _openTopDestination,
          ),
          IconButton(
            onPressed: () async {
              await _controller.switchCamera();
            },
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Kamera valtasa',
          ),
          IconButton(
            onPressed: () async {
              await _controller.toggleTorch();
              if (!mounted) return;
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Vaku',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Irazd a kamerat a vasarlo QR kodjara. Ha kell, a kodot kezzel is beirhatod az elozo kepernyon.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
