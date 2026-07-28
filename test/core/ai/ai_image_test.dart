import 'dart:typed_data';

import 'package:dukasmart/core/ai/ai_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('at the cap constructs; one byte over throws ArgumentError', () {
    final atCap = Uint8List(AiImage.maxRawBytes);
    expect(
      () => AiImage.jpeg(bytes: atCap, width: 100, height: 100),
      returnsNormally,
    );

    final overCap = Uint8List(AiImage.maxRawBytes + 1);
    expect(
      () => AiImage.jpeg(bytes: overCap, width: 100, height: 100),
      throwsArgumentError,
    );
  });

  test('mediaType is always image/jpeg', () {
    final image = AiImage.jpeg(
      bytes: Uint8List(10),
      width: 10,
      height: 10,
    );
    expect(image.mediaType, 'image/jpeg');
  });
}
