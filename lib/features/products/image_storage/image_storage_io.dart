import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native (Android) implementation: opens the gallery picker, then copies
/// the picked file into `getApplicationDocumentsDirectory()` under a
/// unique name and returns that durable path. Returns `null` when the
/// user cancels the picker.
Future<String?> pickAndStoreProductImage() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final docsDir = await getApplicationDocumentsDirectory();
  final ext = p.extension(picked.path);
  final destPath = p.join(
    docsDir.path,
    'product_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  await File(picked.path).copy(destPath);
  return destPath;
}
