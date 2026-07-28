import 'dart:convert';
import 'dart:typed_data';

import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_image.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/anthropic_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
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

Map<String, Object?> _toolUse(
  String toolName,
  Map<String, Object?> input, {
  String? id,
}) =>
    {
      'stop_reason': 'tool_use',
      'content': [
        {
          'type': 'tool_use',
          'id': id ?? 'tool_1',
          'name': toolName,
          'input': input,
        },
      ],
    };

AiImage _fakeImage() =>
    AiImage.jpeg(bytes: Uint8List.fromList([1, 2, 3]), width: 10, height: 10);

/// A minimal fixture spec — the gateway's contract is under test here, not
/// extraction_schemas.dart's business rules (those have their own suite).
ExtractionSpec<Map<String, Object?>> _testSpec({
  String toolName = 'test_tool',
  Map<String, Object?> Function(Map<String, Object?>)? parse,
}) =>
    ExtractionSpec<Map<String, Object?>>(
      toolName: toolName,
      description: 'test extraction tool',
      inputSchema: const {'type': 'object'},
      parse: parse ?? (input) => input,
    );

void main() {
  AnthropicGateway gateway(
    http.Client client, {
    Duration? timeout,
    Duration? extractionTimeout,
    String? model,
    String? extractionModel,
  }) =>
      AnthropicGateway(
        client: client,
        apiKey: 'test-key',
        timeout: timeout ?? const Duration(seconds: 15),
        extractionTimeout: extractionTimeout ?? const Duration(seconds: 60),
        model: model ?? 'claude-opus-5',
        extractionModel: extractionModel ?? 'claude-haiku-4-5-20251001',
      );

  test(
      'tool_use success: wire body carries extractionModel, forced tool_choice, base64, max_tokens 4096',
      () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-haiku-4-5-20251001');
      expect(body['max_tokens'], 4096);
      expect(body['tool_choice'], {'type': 'tool', 'name': 'test_tool'});
      expect((body['tools'] as List), hasLength(1));
      final messages = body['messages'] as List;
      expect(messages, hasLength(1));
      final content = (messages.single as Map)['content'] as List;
      final imageBlock = content.first as Map;
      expect(imageBlock['type'], 'image');
      expect(imageBlock['source']['media_type'], 'image/jpeg');
      expect(imageBlock['source']['data'], base64Encode([1, 2, 3]));
      final textBlock = content.last as Map;
      expect(textBlock['type'], 'text');
      expect(textBlock['text'], 'read this');
      return _apiJson(_toolUse('test_tool', {'foo': 'bar'}));
    });

    final result = await gateway(client).extractStructured(
      instruction: 'read this',
      images: [_fakeImage()],
      spec: _testSpec(),
    );
    expect(result, {'foo': 'bar'});
  });

  test('refusal -> AiUnavailableError', () async {
    final client = MockClient((request) async => _apiJson({
          'stop_reason': 'refusal',
          'content': [],
        }));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  for (final stopReason in ['end_turn', 'max_tokens', 'stop_sequence']) {
    test('$stopReason stop_reason -> AiUnavailableError', () async {
      final client = MockClient((request) async => _apiJson({
            'stop_reason': stopReason,
            'content': [
              {'type': 'text', 'text': 'not a tool call'},
            ],
          }));
      expect(
        () => gateway(client).extractStructured(
            instruction: 'x', images: [], spec: _testSpec()),
        throwsA(isA<AiUnavailableError>()),
      );
    });
  }

  test('unknown stop_reason -> AiUnavailableError', () async {
    final client = MockClient((request) async => _apiJson({
          'stop_reason': 'something_new',
          'content': [],
        }));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('zero tool_use blocks -> AiUnavailableError', () async {
    final client = MockClient((request) async => _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'text', 'text': 'no tool block here'},
          ],
        }));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('two tool_use blocks both named spec.toolName -> AiUnavailableError',
      () async {
    final client = MockClient((request) async => _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {
              'type': 'tool_use',
              'id': '1',
              'name': 'test_tool',
              'input': {'a': 1},
            },
            {
              'type': 'tool_use',
              'id': '2',
              'name': 'test_tool',
              'input': {'a': 2},
            },
          ],
        }));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('one tool_use block with the wrong name -> AiUnavailableError',
      () async {
    final client = MockClient(
        (request) async => _apiJson(_toolUse('other_tool', {'a': 1})));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('non-map input -> AiUnavailableError', () async {
    final client = MockClient((request) async => _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {
              'type': 'tool_use',
              'id': '1',
              'name': 'test_tool',
              'input': 'not a map',
            },
          ],
        }));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('spec.parse throwing -> AiUnavailableError, never the raw exception',
      () async {
    final client = MockClient(
        (request) async => _apiJson(_toolUse('test_tool', {'a': 1})));
    final throwingSpec = _testSpec(parse: (input) => throw StateError('boom'));
    expect(
      () => gateway(client).extractStructured(
          instruction: 'x', images: [], spec: throwingSpec),
      throwsA(isA<AiUnavailableError>()),
    );
  });

  test('HTTP 429 -> AiUnavailableError(busy)', () async {
    final client =
        MockClient((request) async => http.Response('rate limited', 429));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.busy)),
    );
  });

  test('malformed JSON body -> AiUnavailableError', () async {
    final client = MockClient((request) async => http.Response(
          'not json{{{',
          200,
          headers: {'content-type': 'application/json'},
        ));
    expect(
      () => gateway(client)
          .extractStructured(instruction: 'x', images: [], spec: _testSpec()),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.error)),
    );
  });

  test(
      'independent timeouts: a short ask timeout expires while a longer extractionTimeout still succeeds for the same delay',
      () async {
    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return _apiJson(_toolUse('test_tool', {'a': 1}));
    });
    final gw = gateway(
      client,
      timeout: const Duration(milliseconds: 10),
      extractionTimeout: const Duration(milliseconds: 500),
    );

    final result = await gw.extractStructured(
      instruction: 'x',
      images: [],
      spec: _testSpec(),
    );
    expect(result, {'a': 1});

    // Same gateway instance, same delayed client: ask() uses `timeout`
    // (10ms), which the 80ms delay blows through, while extractStructured
    // above used `extractionTimeout` (500ms) and succeeded — proving the
    // two timeouts are genuinely independent for the same delay.
    final db = AppDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final dispatcher = DukaToolDispatcher(AiQueryService(db));
    expect(
      () => gw.ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.offline)),
    );
  });

  test(
      "ask()'s wire body carries model while extractStructured's carries extractionModel — proving the two never collide",
      () async {
    final db = AppDatabase.forExecutor(NativeDatabase.memory());
    final dispatcher = DukaToolDispatcher(AiQueryService(db));
    addTearDown(db.close);

    String? askModel;
    String? extractModel;
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final tools = body['tools'] as List;
      final isExtractCall =
          tools.isNotEmpty && (tools.first as Map)['name'] == 'test_tool';
      if (isExtractCall) {
        extractModel = body['model'] as String;
        return _apiJson(_toolUse('test_tool', {'ok': true}));
      }
      askModel = body['model'] as String;
      return _apiJson({
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': 'hi'},
        ],
      });
    });

    final gw = gateway(
      client,
      model: 'claude-opus-5',
      extractionModel: 'claude-haiku-4-5-20251001',
    );

    await gw.ask([const AiMessage(AiRole.user, 'hi')], dispatcher);
    await gw.extractStructured(
        instruction: 'x', images: [], spec: _testSpec());

    expect(askModel, 'claude-opus-5');
    expect(extractModel, 'claude-haiku-4-5-20251001');
  });
}
