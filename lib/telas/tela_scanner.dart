import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TelaScanner extends StatefulWidget {
  const TelaScanner({super.key});

  @override
  State<TelaScanner> createState() => _TelaScannerState();
}

class _TelaScannerState extends State<TelaScanner> {
  bool _isScanCompleted = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanCompleted) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrCodeValue = barcodes.first.rawValue;
      if (qrCodeValue != null) {
        setState(() {
          _isScanCompleted = true;
        });
        Navigator.pop(context, qrCodeValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aponte para o QR Code')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade400, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
