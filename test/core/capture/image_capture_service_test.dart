import 'dart:typed_data';

import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_image.dart';
import 'package:dukasmart/core/ai/extraction_schemas.dart';
import 'package:dukasmart/core/capture/image_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  Uint8List fixtureBytes() {
    final image = img.Image(width: 2400, height: 1600);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    return Uint8List.fromList(img.encodePng(image));
  }

  test('real pipeline: decode -> resize to 1568 long edge -> re-encode JPEG',
      () async {
    final png = fixtureBytes();
    final service = ImageCaptureService(
      pick: (source) async => XFile.fromData(png, name: 'fixture.png'),
    );

    final result = await service.capture(ImageSource.gallery);
    expect(result, isA<CaptureSuccess>());
    final success = result as CaptureSuccess;

    // JPEG magic bytes (FF D8), proving encodePng input was re-encoded JPEG.
    expect(success.image.bytes[0], 0xFF);
    expect(success.image.bytes[1], 0xD8);
    expect(success.image.width, 1568);
    expect(success.image.height, lessThan(1568));
    expect(success.image.bytes.length, lessThanOrEqualTo(AiImage.maxRawBytes));
  });

  test('cancel path: null from picker -> CaptureCancelled', () async {
    final service = ImageCaptureService(pick: (source) async => null);
    final result = await service.capture(ImageSource.camera);
    expect(result, isA<CaptureCancelled>());
  });

  test('pick throwing (e.g. permission denied) -> CaptureFailed(undecodable)',
      () async {
    final service = ImageCaptureService(
      pick: (source) async => throw Exception('permission denied'),
    );
    final result = await service.capture(ImageSource.camera);
    expect(result, isA<CaptureFailed>());
    expect((result as CaptureFailed).reason, CaptureFailure.undecodable);
  });

  test('readAsBytes throwing -> CaptureFailed(undecodable)', () async {
    final service = ImageCaptureService(
      pick: (source) async => XFile('/nonexistent/path/does-not-exist.jpg'),
    );
    final result = await service.capture(ImageSource.gallery);
    expect(result, isA<CaptureFailed>());
    expect((result as CaptureFailed).reason, CaptureFailure.undecodable);
  });

  test('injected prepare returning oversized bytes -> CaptureFailed(tooLarge)',
      () async {
    final service = ImageCaptureService(
      pick: (source) async => XFile.fromData(Uint8List(10), name: 'x.jpg'),
      prepare: (bytes) => PreparedImage(
        bytes: Uint8List(AiImage.maxRawBytes + 1),
        width: 100,
        height: 100,
      ),
    );
    final result = await service.capture(ImageSource.gallery);
    expect(result, isA<CaptureFailed>());
    expect((result as CaptureFailed).reason, CaptureFailure.tooLarge);
  });

  test('injected prepare throwing -> CaptureFailed(undecodable)', () async {
    final service = ImageCaptureService(
      pick: (source) async => XFile.fromData(Uint8List(10), name: 'x.jpg'),
      prepare: (bytes) => throw const FormatException('bad bytes'),
    );
    final result = await service.capture(ImageSource.gallery);
    expect(result, isA<CaptureFailed>());
    expect((result as CaptureFailed).reason, CaptureFailure.undecodable);
  });

  group('prepareImage (top-level function)', () {
    test('decodes, resizes long edge to maxLongEdge, encodes JPEG', () {
      final prepared = prepareImage(fixtureBytes());
      expect(prepared.width, 1568);
      expect(prepared.height, lessThan(1568));
      expect(prepared.bytes[0], 0xFF);
      expect(prepared.bytes[1], 0xD8);
    });

    test('undecodable bytes throw', () {
      expect(
        () => prepareImage(Uint8List.fromList([1, 2, 3, 4])),
        throwsFormatException,
      );
    });
  });

  test(
      'golden seam: real capture pipeline -> FakeAiGateway -> typed ReceiptExtraction, no network',
      () async {
    final png = fixtureBytes();
    final captureService = ImageCaptureService(
      pick: (source) async => XFile.fromData(png, name: 'fixture.png'),
    );
    final captured = await captureService.capture(ImageSource.camera);
    expect(captured, isA<CaptureSuccess>());
    final image = (captured as CaptureSuccess).image;

    final gateway = FakeAiGateway()
      ..extractInput = {
        'items': [
          {'name': 'Sugar 2kg', 'quantity': 3, 'unit_price_cents': 25000},
        ],
        'supplier_name': 'Highland Wholesalers',
      };

    final result = await gateway.extractStructured(
      instruction: 'Extract every line item from this receipt.',
      images: [image],
      spec: ReceiptExtraction.spec,
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.name, 'Sugar 2kg');
    expect(result.supplierName, 'Highland Wholesalers');
    expect(gateway.extractCalls.single.toolName, 'record_receipt');
    expect(gateway.extractCalls.single.imageCount, 1);
  });

  test(
      'malformed extractInput (items as String, not List) -> AiUnavailableError, never a raw TypeError',
      () async {
    final gateway = FakeAiGateway()
      ..extractInput = {
        'items': 'not a list',
        'supplier_name': 'Highland Wholesalers',
      };

    expect(
      () => gateway.extractStructured(
        instruction: 'Extract every line item from this receipt.',
        images: const [],
        spec: ReceiptExtraction.spec,
      ),
      throwsA(isA<AiUnavailableError>()),
    );
  });
}
