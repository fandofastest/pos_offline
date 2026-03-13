import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/pos_app_bar.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _returned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PosAppBar(
        title: 'Scan Barcode',
        subtitle: 'Point the camera at a barcode',
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_returned) return;
          final codes = capture.barcodes;
          if (codes.isEmpty) return;

          final raw = codes.first.rawValue;
          if (raw == null || raw.trim().isEmpty) return;

          _returned = true;
          Navigator.of(context).pop(raw.trim());
        },
      ),
    );
  }
}
