// Picks a product image (gallery) and copies it into a durable app
// documents path, returning that path (design D7: never the picker's
// temp path; skipped entirely on web where this resolves to the stub
// implementation below, always returning `null`).
//
// Conditional export keeps `dart:io` out of the web compile target.
export 'image_storage_stub.dart'
    if (dart.library.io) 'image_storage_io.dart';
