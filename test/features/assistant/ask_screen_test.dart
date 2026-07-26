import 'dart:async';

import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/anthropic_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/features/assistant/ask_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeAiGateway gateway;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    gateway = FakeAiGateway(reply: 'You sold KES 135 today.');
  });

  tearDown(() async {
    await db.close();
  });

  // A9.1 gates the screen on `aiAvailableProvider`; the test environment
  // has no --dart-define key, so the happy-path tests below must
  // explicitly gate availability on to exercise the chat surface.
  Widget app() => ProviderScope(
        overrides: [
          aiAvailableProvider.overrideWithValue(true),
          aiGatewayProvider.overrideWithValue(gateway),
          dukaToolDispatcherProvider
              .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
        ],
        child: const MaterialApp(home: AskScreen()),
      );

  testWidgets('empty state shows the three suggestion chips', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('What did I sell today?'), findsOneWidget);
    expect(find.text('Nimetumia pesa ngapi kwa transport wiki hii?'), findsOneWidget);
    expect(find.text("What's running low?"), findsOneWidget);
  });

  testWidgets('tapping a chip sends it and renders both bubbles', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('What did I sell today?'));
    await tester.pumpAndSettle();

    expect(find.text('What did I sell today?'), findsOneWidget); // now a bubble
    expect(find.text('You sold KES 135 today.'), findsOneWidget);
    // Chips are gone once the thread has messages.
    expect(find.text("What's running low?"), findsNothing);
  });

  testWidgets('typing and sending via the send button works', (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), 'how is stock?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('how is stock?'), findsOneWidget);
    expect(find.text('You sold KES 135 today.'), findsOneWidget);
    // Input cleared after send.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('offline failure renders the friendly error bubble', (tester) async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text("You're offline — asking needs internet."), findsOneWidget);
  });

  // A9.1: a deep link to /home/ask when AI isn't configured must render a
  // safe placeholder without ever reading the gateway provider — so no
  // network client gets constructed and no request goes out.
  testWidgets(
      'AI unavailable renders a safe placeholder and makes zero HTTP requests',
      (tester) async {
    final requests = <http.BaseRequest>[];
    final recordingClient = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 200);
    });

    final app = ProviderScope(
      overrides: [
        aiAvailableProvider.overrideWithValue(false),
        aiGatewayProvider.overrideWithValue(
          AnthropicGateway(client: recordingClient, apiKey: 'test-key'),
        ),
        dukaToolDispatcherProvider
            .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
      ],
      child: const MaterialApp(home: AskScreen()),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // No chat surface at all — nothing that could trigger a send.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
    expect(requests, isEmpty);
  });

  // A9.2: while a reply is pending, the loading state is observable — a
  // progress indicator shows and the send affordance is disabled.
  testWidgets('shows a loading indicator and disables send while pending',
      (tester) async {
    final completer = Completer<String>();
    final pendingApp = ProviderScope(
      overrides: [
        aiAvailableProvider.overrideWithValue(true),
        aiGatewayProvider.overrideWithValue(_CompleterAiGateway(completer)),
        dukaToolDispatcherProvider
            .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
      ],
      child: const MaterialApp(home: AskScreen()),
    );

    await tester.pumpWidget(pendingApp);

    await tester.enterText(find.byType(TextField), 'how is stock?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(); // start the send, don't settle — reply is pending

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final sendButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(sendButton.onPressed, isNull);

    completer.complete('done thinking');
    await tester.pumpAndSettle();
  });
}

/// An [AiGateway] whose `ask` call stays pending until [completer]
/// resolves — used to observe the in-flight loading state (A9.2).
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
