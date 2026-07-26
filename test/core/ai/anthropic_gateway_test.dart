import 'dart:convert';

import 'package:dukasmart/core/ai/ai_config.dart';
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/anthropic_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _apiJson(Map<String, Object?> body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object?> _endTurn(String text) => {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': text},
      ],
    };

void main() {
  late AppDatabase db;
  late DukaToolDispatcher dispatcher;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    dispatcher = DukaToolDispatcher(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  AnthropicGateway gateway(http.Client client, {Duration? timeout}) =>
      AnthropicGateway(
        client: client,
        apiKey: 'test-key',
        timeout: timeout ?? const Duration(seconds: 15),
      );

  test('plain answer: sends POST, headers, model, system, tools, max_tokens',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), AiConfig.endpoint);
      expect(request.headers['content-type'], 'application/json');
      expect(request.headers['x-api-key'], 'test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-opus-5');
      expect(body['max_tokens'], 2048);
      expect(body['system'], contains('DukaSmart'));
      expect((body['tools'] as List), hasLength(6));
      expect((body['messages'] as List), hasLength(1));
      return _apiJson(_endTurn('Habari! Uliuza KES 135 leo.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'nimeuza pesa ngapi leo?')], dispatcher);
    expect(reply, 'Habari! Uliuza KES 135 leo.');
  });

  test('tool round trip: executes tool, echoes tool_use_id, returns final text',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = body['messages'] as List;
      if (calls == 1) {
        return _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'text', 'text': 'Let me check.'},
            {
              'type': 'tool_use',
              'id': 'toolu_1',
              'name': 'get_stock_levels',
              'input': {'low_only': false},
            },
          ],
        });
      }
      // Round 2 must carry: original user msg + full assistant content +
      // a user message whose content is the tool_result list.
      expect(messages, hasLength(3));
      expect((messages[1] as Map)['role'], 'assistant');
      final results = ((messages[2] as Map)['content'] as List).cast<Map>();
      expect(results.single['type'], 'tool_result');
      expect(results.single['tool_use_id'], 'toolu_1');
      final toolJson =
          jsonDecode(results.single['content'] as String) as Map<String, dynamic>;
      expect(toolJson['product_count'], 5); // seeded products
      return _apiJson(_endTurn('You stock 5 products.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'how many products?')], dispatcher);
    expect(reply, 'You stock 5 products.');
    expect(calls, 2);
  });

  test('two parallel tool_use blocks -> both tool_results in ONE user turn',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (calls == 1) {
        return _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {
              'type': 'tool_use',
              'id': 'toolu_a',
              'name': 'get_stock_levels',
              'input': <String, Object?>{},
            },
            {
              'type': 'tool_use',
              'id': 'toolu_b',
              'name': 'get_stock_levels',
              'input': {'low_only': true},
            },
          ],
        });
      }
      final messages = body['messages'] as List;
      expect(messages, hasLength(3));
      final resultsMsg = messages[2] as Map;
      expect(resultsMsg['role'], 'user');
      final results = (resultsMsg['content'] as List).cast<Map>();
      expect(results, hasLength(2));
      expect(results.map((r) => r['tool_use_id']), ['toolu_a', 'toolu_b']);
      for (final r in results) {
        expect(r['type'], 'tool_result');
      }
      return _apiJson(_endTurn('Checked both.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'check stock two ways')], dispatcher);
    expect(reply, 'Checked both.');
    expect(calls, 2);
  });

  test('refusal stop_reason -> polite decline without reading content', () async {
    final client = MockClient((request) async =>
        _apiJson({'stop_reason': 'refusal', 'content': <Object?>[]}));
    final reply =
        await gateway(client).ask([const AiMessage(AiRole.user, 'hack it')], dispatcher);
    expect(reply, "I can't help with that question.");
  });

  test('endless tool_use is capped: 6 posts then graceful fallback', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return _apiJson({
        'stop_reason': 'tool_use',
        'content': [
          {
            'type': 'tool_use',
            'id': 'toolu_$calls',
            'name': 'get_stock_levels',
            'input': <String, Object?>{},
          },
        ],
      });
    });

    final reply =
        await gateway(client).ask([const AiMessage(AiRole.user, 'loop')], dispatcher);
    expect(reply, contains('simpler question'));
    expect(calls, 6); // initial round + 5 capped tool rounds
  });

  test('tool that throws during dispatch -> is_error tool_result, loop continues',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {
              'type': 'tool_use',
              'id': 'toolu_1',
              // A malformed model response: `name` should be a string —
              // this triggers a raw TypeError deep in dispatch, which the
              // gateway must catch and turn into an is_error tool_result
              // instead of propagating.
              'name': 123,
              'input': <String, Object?>{},
            },
          ],
        });
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = body['messages'] as List;
      final results = ((messages[2] as Map)['content'] as List).cast<Map>();
      expect(results.single['is_error'], isTrue);
      return _apiJson(_endTurn('Recovered.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'weird tool')], dispatcher);
    expect(reply, 'Recovered.');
    expect(calls, 2);
  });

  test('max_tokens stop_reason -> AiUnavailableError', () async {
    final client = MockClient((request) async =>
        _apiJson({'stop_reason': 'max_tokens', 'content': <Object?>[]}));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('unknown stop_reason -> AiUnavailableError', () async {
    final client = MockClient((request) async =>
        _apiJson({'stop_reason': 'something_new', 'content': <Object?>[]}));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('non-ASCII UTF-8 body decodes correctly (no charset in content-type)',
      () async {
    final payload = utf8.encode(jsonEncode(_endTurn('Umeuza bidhaa 3 leo — asante!')));
    final client = MockClient((request) async =>
        http.Response.bytes(payload, 200, headers: {'content-type': 'application/json'}));
    final reply =
        await gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher);
    expect(reply, 'Umeuza bidhaa 3 leo — asante!');
  });

  test('malformed JSON body -> AiUnavailableError', () async {
    final client = MockClient((request) async =>
        http.Response('not json at all', 200, headers: {'content-type': 'application/json'}));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.error)),
    );
  });

  test('non-map JSON body -> AiUnavailableError', () async {
    final client = MockClient((request) async =>
        http.Response(jsonEncode([1, 2, 3]), 200,
            headers: {'content-type': 'application/json'}));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.error)),
    );
  });

  test('request timeout -> AiUnavailableError(offline)', () async {
    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _apiJson(_endTurn('too late'));
    });
    expect(
      () => gateway(client, timeout: const Duration(milliseconds: 10))
          .ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.offline)),
    );
  });

  test('HTTP 429 -> AiUnavailableError(busy)', () async {
    final client = MockClient((request) async => http.Response('rate limited', 429));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.busy)),
    );
  });

  test('network failure -> AiUnavailableError(offline)', () async {
    final client =
        MockClient((request) async => throw http.ClientException('no network'));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.offline)),
    );
  });

  test('HTTP 500 -> AiUnavailableError(busy)', () async {
    // A6.4: 429 AND every 5xx map to the "busy" message.
    final client = MockClient((request) async => http.Response('boom', 500));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.busy)),
    );
  });

  test('HTTP 503 -> AiUnavailableError(busy)', () async {
    final client = MockClient((request) async => http.Response('unavailable', 503));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.busy)),
    );
  });

  test('HTTP 404 -> AiUnavailableError(error)', () async {
    final client = MockClient((request) async => http.Response('not found', 404));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.error)),
    );
  });

  group('generateInsight', () {
    test('sends snapshot JSON with no tools, max_tokens 1024, returns paragraph',
        () async {
      final snapshot = await SnapshotBuilder(AiQueryService(db)).build(DateTime.now());
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('tools'), isFalse);
        expect(body['max_tokens'], 1024);
        final userText =
            ((body['messages'] as List).single as Map)['content'] as String;
        expect(userText, contains('"cash_flow"'));
        return _apiJson(_endTurn('A quiet day with steady cash flow.'));
      });

      final insight = await gateway(client).generateInsight(snapshot);
      expect(insight, 'A quiet day with steady cash flow.');
    });

    test('empty content -> AiUnavailableError(error)', () async {
      final snapshot = await SnapshotBuilder(AiQueryService(db)).build(DateTime.now());
      final client = MockClient((request) async =>
          _apiJson({'stop_reason': 'end_turn', 'content': <Object?>[]}));
      expect(
        () => gateway(client).generateInsight(snapshot),
        throwsA(isA<AiUnavailableError>()),
      );
    });

    test('refusal -> AiUnavailableError(error)', () async {
      final snapshot = await SnapshotBuilder(AiQueryService(db)).build(DateTime.now());
      final client = MockClient((request) async =>
          _apiJson({'stop_reason': 'refusal', 'content': <Object?>[]}));
      expect(
        () => gateway(client).generateInsight(snapshot),
        throwsA(isA<AiUnavailableError>()),
      );
    });
  });
}
