import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The ONLY scanner wrapper any track may use (design D7). A manual
/// barcode [TextField] plus a scan [IconButton] that opens a full-screen
/// [MobileScanner]. Scanner failures degrade to manual entry through
/// [MobileScanner.errorBuilder] — never a bare try/catch.
class BarcodeField extends StatelessWidget {
  const BarcodeField({
    super.key,
    required this.controller,
    this.label = 'Barcode (optional)',
    this.onScanned,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onScanned;

  Future<void> _scan(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      controller.text = result;
      onScanned?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan barcode',
          onPressed: () => _scan(context),
        ),
      ),
    );
  }
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value != null && value.isNotEmpty) {
      _handled = true;
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) => _ScannerError(error: error),
      ),
    );
  }
}

/// Shown when the scanner cannot start (camera unavailable, permission
/// denied, etc.) — degrades to manual entry rather than crashing.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Enter barcode manually'),
            ),
          ],
        ),
      ),
    );
  }
}
