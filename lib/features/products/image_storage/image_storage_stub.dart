/// Web stub (design D7: images are skipped on web — `imagePath` stays
/// null and the UI hides the option). Kept a no-op so the screen never
/// needs to branch on platform beyond hiding the button.
Future<String?> pickAndStoreProductImage() async => null;
