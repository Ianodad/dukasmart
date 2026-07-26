import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers.dart';
import 'ai_config.dart';
import 'ai_gateway.dart';
import 'ai_query_service.dart';
import 'anthropic_gateway.dart';
import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// Riverpod wiring for the AI layer. Features read these providers —
/// never the Anthropic implementation directly (spec: gateway seam).

/// True when a build-time API key exists (spec: without it, AI surfaces
/// don't render and no AI network path is reachable). Widget tests
/// override this to exercise the AI surfaces.
final aiAvailableProvider = Provider<bool>((ref) => AiConfig.isConfigured);

final aiQueryServiceProvider = Provider<AiQueryService>(
    (ref) => AiQueryService(ref.watch(databaseProvider)));

final dukaToolDispatcherProvider = Provider<DukaToolDispatcher>(
    (ref) => DukaToolDispatcher(ref.watch(aiQueryServiceProvider)));

final snapshotBuilderProvider = Provider<SnapshotBuilder>(
    (ref) => SnapshotBuilder(ref.watch(aiQueryServiceProvider)));

/// A7.1: fails closed. Reading this provider without a configured API key
/// is a programmer error (a caller that skipped the `aiAvailableProvider`
/// gate), not a silent client with an empty key that would reach the
/// network anyway — so it throws instead of constructing a gateway.
final aiGatewayProvider = Provider<AiGateway>((ref) {
  if (!AiConfig.isConfigured) {
    throw StateError(
        'aiGatewayProvider read without a configured ANTHROPIC_API_KEY — '
        'callers must check aiAvailableProvider first.');
  }
  final client = http.Client();
  ref.onDispose(client.close);
  return AnthropicGateway(client: client, apiKey: AiConfig.apiKey);
});

/// The daily report's AI insight for a given close date. Null means "no
/// card": AI not configured, or the call failed — the report screen never
/// shows an error state for this (spec: "on any failure the card simply
/// does not appear").
///
/// A7.2: a SUCCESSFUL insight is cached for the app session via
/// `ref.keepAlive()` — reopening the report for the same close date must
/// not re-bill the AI call. A failure is deliberately NOT kept alive: once
/// the last listener (the report screen) goes away, `autoDispose` tears
/// this instance down so the next visit retries instead of being stuck
/// with a cached null forever.
final aiInsightProvider =
    FutureProvider.autoDispose.family<String?, DateTime>((ref, date) async {
  if (!ref.watch(aiAvailableProvider)) return null;
  try {
    final snapshot = await ref.watch(snapshotBuilderProvider).build(date);
    final insight = await ref.watch(aiGatewayProvider).generateInsight(snapshot);
    ref.keepAlive();
    return insight;
  } on AiUnavailableError {
    return null;
  }
});
