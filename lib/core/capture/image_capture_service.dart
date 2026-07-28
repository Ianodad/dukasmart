import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../ai/ai_image.dart';

sealed class CaptureResult {
  const CaptureResult();
}

class CaptureSuccess extends CaptureResult {
  const CaptureSuccess(this.image);
  final AiImage image;
}

class CaptureCancelled extends CaptureResult {
  const CaptureCancelled();
}

class CaptureFailed extends CaptureResult {
  const CaptureFailed(this.reason);
  final CaptureFailure reason;
}

enum CaptureFailure { tooLarge, undecodable }

/// Top-level and injectable so tests can force each outcome directly,
/// instead of faking package:image internals.
class PreparedImage {
  const PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Decodes, downscales (long edge to [maxLongEdge]), and re-encodes as
/// JPEG. Never trusts the picker's own resize params — those are
/// best-effort only on some platforms. Throws (never returns null) when
/// the bytes are undecodable, so both the "decode failed" and "any other
/// prepare failure" paths funnel through one catch in [ImageCaptureService].
PreparedImage prepareImage(
  Uint8List raw, {
  int maxLongEdge = 1568,
  int quality = 80,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(raw);
  } catch (_) {
    // Some format sniffers (e.g. the PSD probe) throw on truncated/garbage
    // bytes rather than returning null — normalize both to one outcome.
    decoded = null;
  }
  if (decoded == null) {
    throw const FormatException('undecodable image bytes');
  }

  var image = decoded;
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge > maxLongEdge) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? maxLongEdge : null,
      height: image.width >= image.height ? null : maxLongEdge,
      interpolation: img.Interpolation.linear,
    );
  }

  final jpegBytes = img.encodeJpg(image, quality: quality);
  return PreparedImage(
    bytes: Uint8List.fromList(jpegBytes),
    width: image.width,
    height: image.height,
  );
}

class ImageCaptureService {
  ImageCaptureService({
    Future<XFile?> Function(ImageSource)? pick,
    PreparedImage Function(Uint8List)? prepare,
  })  : _pick = pick,
        _prepare = prepare;

  final Future<XFile?> Function(ImageSource)? _pick;
  final PreparedImage Function(Uint8List)? _prepare;

  Future<CaptureResult> capture(ImageSource source) async {
    final pick = _pick ?? _defaultPick;
    XFile? xfile;
    try {
      xfile = await pick(source);
    } catch (_) {
      // image_picker throws PlatformException for denied permissions, an
      // unavailable camera, concurrent picker use, and other plugin
      // failures. There is no dedicated CaptureFailure case for these —
      // the two-value CaptureFailure {tooLarge, undecodable} enum is the
      // surface missions 02/03 were already written and reviewed against,
      // so picker-level failures fold into undecodable deliberately rather
      // than widening that surface. A dedicated `unavailable` case is a
      // v2.1 item.
      return const CaptureFailed(CaptureFailure.undecodable);
    }
    if (xfile == null) return const CaptureCancelled();

    Uint8List bytes;
    try {
      bytes = await xfile.readAsBytes();
    } catch (_) {
      return const CaptureFailed(CaptureFailure.undecodable);
    }

    PreparedImage prepared;
    try {
      prepared =
          _prepare != null ? _prepare(bytes) : await compute(prepareImage, bytes);
    } catch (_) {
      return const CaptureFailed(CaptureFailure.undecodable);
    }

    if (prepared.bytes.length > AiImage.maxRawBytes) {
      return const CaptureFailed(CaptureFailure.tooLarge);
    }

    return CaptureSuccess(AiImage.jpeg(
      bytes: prepared.bytes,
      width: prepared.width,
      height: prepared.height,
    ));
  }

  static Future<XFile?> _defaultPick(ImageSource source) =>
      ImagePicker().pickImage(
        source: source,
        maxWidth: 1568,
        maxHeight: 1568,
        imageQuality: 80,
      );
}

final imageCaptureServiceProvider =
    Provider<ImageCaptureService>((ref) => ImageCaptureService());
