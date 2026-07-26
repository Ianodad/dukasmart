/// Build-time AI configuration (spec: demo/portfolio deployment).
///
/// The Anthropic API key is injected at build time:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///
/// When the define is absent, [isConfigured] is false, every AI surface
/// stays hidden, and no AI network code path is reachable — the app is
/// byte-for-byte today's offline app. The key is never committed.
class AiConfig {
  AiConfig._();

  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  /// Single const so switching models later is a one-line change.
  static const String model = 'claude-opus-5';

  static const String endpoint = 'https://api.anthropic.com/v1/messages';
  static const String anthropicVersion = '2023-06-01';

  static bool get isConfigured => apiKey.isNotEmpty;
}
