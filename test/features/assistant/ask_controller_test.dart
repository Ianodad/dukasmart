import 'dart:async';

import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/features/assistant/ask_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeAiGateway gateway;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    gateway = FakeAiGateway(reply: 'You sold KES 135 today.');
    container = ProviderContainer(overrides: [
      // A8.2 requires send() to fail closed when AI is unavailable, and
      // AiConfig.isConfigured is false in the test environment (no
      // --dart-define), so the happy-path tests must explicitly gate
      // availability on.
      aiAvailableProvider.overrideWithValue(true),
      aiGatewayProvider.overrideWithValue(gateway),
      dukaToolDispatcherProvider
          .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
    ]);
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive for the test body.
    final sub = container.listen(askControllerProvider, (_, _) {});
    addTearDown(sub.close);
  });

  tearDown(() async {
    await db.close();
  });

  test('send appends user message then assistant reply', () async {
    await container.read(askControllerProvider.notifier).send('what did I sell?');

    final state = container.read(askControllerProvider);
    expect(state.sending, isFalse);
    expect(state.messages, hasLength(2));
    expect(state.messages[0].fromUser, isTrue);
    expect(state.messages[0].text, 'what did I sell?');
    expect(state.messages[1].fromUser, isFalse);
    expect(state.messages[1].text, 'You sold KES 135 today.');
  });

  test('blank input is ignored', () async {
    await container.read(askControllerProvider.notifier).send('   ');
    expect(container.read(askControllerProvider).messages, isEmpty);
    expect(gateway.askCalls, isEmpty);
  });

  test('gateway failure appends an error bubble with the friendly message',
      () async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await container.read(askControllerProvider.notifier).send('hello?');

    final state = container.read(askControllerProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages[1].isError, isTrue);
    expect(state.messages[1].text, "You're offline — asking needs internet.");
    expect(state.sending, isFalse);
  });

  test('error bubbles are excluded from the thread sent to the model',
      () async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await container.read(askControllerProvider.notifier).send('first');
    gateway.error = null;
    await container.read(askControllerProvider.notifier).send('second');

    // Second call's thread: both user messages, no error bubble.
    final thread = gateway.askCalls.last;
    expect(thread, hasLength(2));
    expect(thread.every((m) => m.role == AiRole.user), isTrue);
    expect(thread.map((m) => m.text).toList(), ['first', 'second']);
  });

  // A8.1: catch ALL exceptions from the gateway, not just AiUnavailableError.
  test('an unexpected exception from the gateway maps to the generic error bubble',
      () async {
    final localContainer = ProviderContainer(overrides: [
      aiAvailableProvider.overrideWithValue(true),
      aiGatewayProvider.overrideWithValue(_ThrowingAiGateway()),
      dukaToolDispatcherProvider
          .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
    ]);
    addTearDown(localContainer.dispose);
    final sub = localContainer.listen(askControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await localContainer.read(askControllerProvider.notifier).send('hi');

    final state = localContainer.read(askControllerProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages[1].isError, isTrue);
    expect(state.messages[1].text, 'Something went wrong — please try again.');
    expect(state.sending, isFalse);
  });

  // A8.2: fail closed — send() must not read the gateway or make a request
  // when AI is unavailable.
  test('send is a no-op when AI is unavailable', () async {
    final localContainer = ProviderContainer(overrides: [
      aiAvailableProvider.overrideWithValue(false),
      // Deliberately no aiGatewayProvider / dukaToolDispatcherProvider
      // override: if send() ever reads the (unconfigured) real gateway
      // provider, it throws StateError and fails this test.
    ]);
    addTearDown(localContainer.dispose);
    final sub = localContainer.listen(askControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await localContainer.read(askControllerProvider.notifier).send('hello?');

    expect(localContainer.read(askControllerProvider).messages, isEmpty);
  });

  // A8.1: disposing the container mid-flight must not throw and must not
  // mutate state after dispose.
  test('disposing the container mid-flight does not throw', () async {
    final completer = Completer<String>();
    final localContainer = ProviderContainer(overrides: [
      aiAvailableProvider.overrideWithValue(true),
      aiGatewayProvider.overrideWithValue(_CompleterAiGateway(completer)),
      dukaToolDispatcherProvider
          .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
    ]);
    final sub = localContainer.listen(askControllerProvider, (_, _) {});

    final sendFuture =
        localContainer.read(askControllerProvider.notifier).send('hello?');

    // Dispose while the gateway call is still pending.
    sub.close();
    localContainer.dispose();

    // Resolve the in-flight call after disposal — must be a safe no-op.
    completer.complete('late reply');

    await expectLater(sendFuture, completes);
  });
}

/// Always throws a non-[AiUnavailableError] exception — exercises the
/// AskController's generic error-boundary fallback (A8.1).
class _ThrowingAiGateway implements AiGateway {
  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    throw StateError('boom');
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) {
    throw UnimplementedError();
  }
}

/// An [AiGateway] whose `ask` call stays pending until [completer]
/// resolves — used to dispose the controller mid-flight (A8.1).
class _CompleterAiGateway implements AiGateway {
  _CompleterAiGateway(this._completer);

  final Completer<String> _completer;

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) {
    return _completer.future;
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) {
    throw UnimplementedError();
  }
}
