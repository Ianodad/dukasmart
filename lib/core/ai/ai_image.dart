import 'dart:typed_data';

/// A prepared, always-JPEG image ready to send to the AI gateway. The
/// capture pipeline (`ImageCaptureService`) is the only intended producer —
/// this constructor enforces the size cap but does not sniff or re-encode.
class AiImage {
  AiImage.jpeg({
    required this.bytes,
    required this.width,
    required this.height,
  }) {
    if (bytes.length > maxRawBytes) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'exceeds maxRawBytes ($maxRawBytes)',
      );
    }
  }

  final Uint8List bytes;
  final int width;
  final int height;

  String get mediaType => 'image/jpeg';

  /// 4.5MB base64 ceiling → raw = 4_500_000 * 3 / 4.
  static const int maxRawBytes = 3_375_000;
}
