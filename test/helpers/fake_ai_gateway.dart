import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_image.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';

/// Canned-response [AiGateway] for tests. Set [error] (mutable) to make
/// the next call throw; [askCalls] records every thread sent.
class FakeAiGateway implements AiGateway {
  FakeAiGateway({
    this.reply = 'Fake reply.',
    this.insight = 'Fake insight.',
    this.error,
  });

  final String reply;
  final String insight;
  AiUnavailableError? error;
  final List<List<AiMessage>> askCalls = [];

  /// The raw tool_use input [extractStructured] parses via `spec.parse`.
  Map<String, Object?> extractInput = const {};

  /// Set to make the next [extractStructured] call throw, mirroring
  /// [error] but scoped to extraction (typed [AiUnavailableError], not
  /// `Object?`, so tests exercise the real A6.3 boundary contract).
  AiUnavailableError? extractError;

  final List<({String toolName, int imageCount})> extractCalls = [];

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    askCalls.add(List.of(thread));
    final e = error;
    if (e != null) throw e;
    return reply;
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) async {
    final e = error;
    if (e != null) throw e;
    return insight;
  }

  @override
  Future<T> extractStructured<T>({
    required String instruction,
    required List<AiImage> images,
    required ExtractionSpec<T> spec,
  }) async {
    extractCalls.add((toolName: spec.toolName, imageCount: images.length));
    final e = extractError;
    if (e != null) throw e;
    try {
      return spec.parse(extractInput);
    } catch (_) {
      throw const AiUnavailableError(AiFailureKind.error);
    }
  }
}
