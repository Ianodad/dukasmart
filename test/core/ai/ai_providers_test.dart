import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_gateway.dart';

/// Polls [condition] until it is true, or fails after [timeout]. Mirrors
/// test/core/providers_test.dart's helper of the same name — used to await
/// async provider emissions without hard-coding a fixed delay.
Future<void> _waitFor(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > timeout) {
      fail('Condition not satisfied within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// [FakeAiGateway] subclass that counts [generateInsight] calls — used by
/// the A7.2 caching tests to prove the gateway is (or isn't) hit again on a
/// second read.
class _CountingAiGateway extends FakeAiGateway {
  _CountingAiGateway({super.insight, super.error});

  int insightCalls = 0;

  @override
  Future<String> generateInsight(snapshot) async {
    insightCalls++;
    return super.generateInsight(snapshot);
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer({required bool aiAvailable, FakeAiGateway? gateway}) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) {
        // Container owns db lifetime via tearDown, not ref.onDispose.
        return db;
      }),
      aiAvailableProvider.overrideWithValue(aiAvailable),
      if (gateway != null) aiGatewayProvider.overrideWithValue(gateway),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('aiInsightProvider is null when AI is not configured', () async {
    final container = makeContainer(aiAvailable: false);
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, isNull);
  });

  test('aiInsightProvider returns gateway insight when available', () async {
    final container = makeContainer(
        aiAvailable: true, gateway: FakeAiGateway(insight: 'Sales are up.'));
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, 'Sales are up.');
  });

  test('aiInsightProvider swallows AiUnavailableError -> null (no error card)',
      () async {
    final container = makeContainer(
      aiAvailable: true,
      gateway: FakeAiGateway(
          error: const AiUnavailableError(AiFailureKind.offline)),
    );
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, isNull);
  });

  test(
      'aiGatewayProvider throws StateError when AI is not configured '
      '(A7.1 fail closed)', () {
    // No aiGatewayProvider override here — this exercises the REAL
    // provider, which reads AiConfig.isConfigured. Nothing in this test
    // suite passes --dart-define=ANTHROPIC_API_KEY, so it is false.
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) => db),
    ]);
    addTearDown(container.dispose);

    expect(() => container.read(aiGatewayProvider), throwsA(isA<StateError>()));
  });

  group('aiInsightProvider caching (A7.2)', () {
    test('caches a successful insight per close date for the app session',
        () async {
      final gateway = _CountingAiGateway(insight: 'Sales are up.');
      final container = makeContainer(aiAvailable: true, gateway: gateway);
      final date = DateTime(2026, 7, 26);

      String? firstValue;
      final firstSub = container.listen<AsyncValue<String?>>(
        aiInsightProvider(date),
        (previous, next) => next.whenData((v) => firstValue = v),
        fireImmediately: true,
      );
      await _waitFor(() => firstValue != null);
      expect(firstValue, 'Sales are up.');
      expect(gateway.insightCalls, 1);

      // Drop every listener. With plain `autoDispose` this tears the
      // cached family instance down (see providers_test.dart's
      // "autoDispose freshness" group) — but a successful insight calls
      // ref.keepAlive(), so the cached future must survive this.
      firstSub.close();
      await Future<void>.delayed(Duration.zero);

      String? secondValue;
      final secondSub = container.listen<AsyncValue<String?>>(
        aiInsightProvider(date),
        (previous, next) => next.whenData((v) => secondValue = v),
        fireImmediately: true,
      );
      await _waitFor(() => secondValue != null);
      expect(secondValue, 'Sales are up.');
      // Reopening the report must not re-bill the AI call.
      expect(gateway.insightCalls, 1);

      secondSub.close();
    });

    test('does not cache a failed call — reopening the report retries',
        () async {
      final gateway = _CountingAiGateway(
        error: const AiUnavailableError(AiFailureKind.offline),
      );
      final container = makeContainer(aiAvailable: true, gateway: gateway);
      final date = DateTime(2026, 7, 26);

      var firstDone = false;
      final firstSub = container.listen<AsyncValue<String?>>(
        aiInsightProvider(date),
        (previous, next) => next.when(
          data: (_) => firstDone = true,
          error: (_, stackTrace) => firstDone = true,
          loading: () {},
        ),
        fireImmediately: true,
      );
      await _waitFor(() => firstDone);
      expect(gateway.insightCalls, 1);

      firstSub.close();
      await Future<void>.delayed(Duration.zero);

      var secondDone = false;
      final secondSub = container.listen<AsyncValue<String?>>(
        aiInsightProvider(date),
        (previous, next) => next.when(
          data: (_) => secondDone = true,
          error: (_, stackTrace) => secondDone = true,
          loading: () {},
        ),
        fireImmediately: true,
      );
      await _waitFor(() => secondDone);
      // No keepAlive on failure — the provider was disposed and this is a
      // fresh call, not a cache hit.
      expect(gateway.insightCalls, 2);

      secondSub.close();
    });
  });
}
