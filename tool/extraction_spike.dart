// Standalone harness for the M10 exit-gate spike (mission
// .wargames/wargames/01-ai-vision-extraction.md). NOT a test — Ian runs
// this manually with real sample photos and a real API key, and fills in
// .wargames/GATE-01-extraction-spike.md from the results.
//
// Run (Chrome — a file/photo picker needs a browser + a user gesture):
//   flutter run -d chrome tool/extraction_spike.dart \
//     --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
//     --dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001
//
// Two buttons, one per extraction schema — NOT a command-line arg: `flutter
// run` entrypoint args are desktop-only, and the web file picker requires a
// user gesture that a headless main() can't supply.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:dukasmart/core/ai/ai_config.dart';
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/anthropic_gateway.dart';
import 'package:dukasmart/core/ai/extraction_schemas.dart';
import 'package:dukasmart/core/capture/image_capture_service.dart';

void main() {
  runApp(const MaterialApp(home: _ExtractionSpikeScreen()));
}

class _ExtractionSpikeScreen extends StatefulWidget {
  const _ExtractionSpikeScreen();

  @override
  State<_ExtractionSpikeScreen> createState() =>
      _ExtractionSpikeScreenState();
}

class _ExtractionSpikeScreenState extends State<_ExtractionSpikeScreen> {
  String _result = 'Tap a button to pick a photo.';
  bool _busy = false;

  Future<void> _run<T>({
    required String label,
    required String instruction,
    required ExtractionSpec<T> spec,
    required String Function(T) describe,
  }) async {
    if (AiConfig.apiKey.isEmpty) {
      setState(() {
        _result = 'API key: MISSING — the spike sent no request.\n\n'
            'Re-run with:\n'
            'flutter run -d chrome tool/extraction_spike.dart '
            '--dart-define=ANTHROPIC_API_KEY=sk-ant-... '
            '--dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001';
      });
      return;
    }

    setState(() {
      _busy = true;
      _result = 'Picking a $label photo...';
    });

    // The picker call happens synchronously inside ImageCaptureService's
    // first (and only preceding) await — nothing else awaits before it, so
    // the browser still sees this as originating from the button tap.
    final captureService = ImageCaptureService();
    final captured = await captureService.capture(ImageSource.gallery);

    switch (captured) {
      case CaptureCancelled():
        setState(() {
          _busy = false;
          _result = 'Cancelled.';
        });
        return;
      case CaptureFailed(reason: final reason):
        final message = 'Capture failed: $reason';
        debugPrint('[extraction_spike] $message');
        setState(() {
          _busy = false;
          _result = message;
        });
        return;
      case CaptureSuccess(image: final image):
        setState(() => _result = 'Sending to ${AiConfig.extractionModel}...');
        try {
          // extractionModel is ALWAYS AiConfig.extractionModel — never a
          // hardcoded model string, never AiConfig.model (that field drives
          // ask()/generateInsight() only).
          final gateway = AnthropicGateway(
            client: http.Client(),
            apiKey: AiConfig.apiKey,
            extractionModel: AiConfig.extractionModel,
          );
          final parsed = await gateway.extractStructured(
            instruction: instruction,
            images: [image],
            spec: spec,
          );
          final message =
              'Model: ${AiConfig.extractionModel}\n\n${describe(parsed)}';
          debugPrint('[extraction_spike] $message');
          setState(() {
            _busy = false;
            _result = message;
          });
        } on AiUnavailableError catch (e) {
          final message = 'Extraction failed: ${e.userMessage}';
          debugPrint('[extraction_spike] $message');
          setState(() {
            _busy = false;
            _result = message;
          });
        }
    }
  }

  Future<void> _runReceipt() => _run<ReceiptExtraction>(
        label: 'receipt',
        instruction: 'Extract every line item, the receipt total, supplier '
            'name, and date from this receipt photo.',
        spec: ReceiptExtraction.spec,
        describe: (r) => 'items: ${r.items.length}\n'
            'skippedRows: ${r.skippedRows}\n'
            'truncated: ${r.truncated}\n'
            'receiptTotalCents: ${r.receiptTotalCents}\n'
            'supplierName: ${r.supplierName}\n'
            'date: ${r.date}\n\n'
            '${r.items.map((i) => '- ${i.name} x${i.quantity} '
                'unit=${i.unit} unitPriceCents=${i.unitPriceCents} '
                'lineTotalCents=${i.lineTotalCents}').join('\n')}',
      );

  Future<void> _runNotebook() => _run<NotebookPage>(
        label: 'notebook page',
        instruction: 'Extract every product, its unit, and its prices from '
            'this handwritten notebook catalog page.',
        spec: NotebookPage.spec,
        describe: (p) => 'products: ${p.products.length}\n'
            'skippedRows: ${p.skippedRows}\n'
            'truncated: ${p.truncated}\n\n'
            '${p.products.map((pr) => '- ${pr.name} unit=${pr.unit} '
                'sellingPriceCents=${pr.sellingPriceCents} '
                'buyingPriceCents=${pr.buyingPriceCents}').join('\n')}',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DukaSmart extraction spike')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiConfig.apiKey.isEmpty
                ? const Text(
                    'API key: MISSING — pass '
                    '--dart-define=ANTHROPIC_API_KEY=sk-ant-...',
                    style: TextStyle(color: Colors.red),
                  )
                : Text('API key: present (${AiConfig.apiKey.length} chars)'),
            Text('Extraction model: ${AiConfig.extractionModel}'),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _runReceipt,
                child: const Text('Read receipt'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _runNotebook,
                child: const Text('Read notebook page'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
