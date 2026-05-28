import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final Future<void> Function(String) onScan;

  const QRScannerPage({super.key, required this.onScan});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) async {
        if (_isScanned) return;
        _isScanned = true;

        final barcode = capture.barcodes.first;
        final String code = barcode.rawValue ?? '';

        if (code.isNotEmpty) {
          await widget.onScan(code);
          if (!mounted) return;
        }
      },
    );
  }
}
