import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;

import 'ai_config.dart';
import 'ai_gateway.dart';
import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// Anthropic Messages API implementation of [AiGateway] over raw HTTPS
/// (no official Dart SDK). See the spec's error-handling section, and the
/// Task 6 Codex review amendments (A6.1-A6.5), for the failure-mode
/// mapping and loop-cap contract implemented here.
class AnthropicGateway implements AiGateway {
  AnthropicGateway({
    required http.Client client,
    required this.apiKey,
    this.model = AiConfig.model,
    this.endpoint = AiConfig.endpoint,
    this.timeout = _defaultTimeout,
  }) : _client = client;

  final http.Client _client;
  final String apiKey;
  final String model;
  final String endpoint;

  /// A6.4: injectable per-request timeout, defaulting to the spec value
  /// (15s) rather than the plan's original hardcoded 30s.
  final Duration timeout;

  static const Duration _defaultTimeout = Duration(seconds: 15);

  /// Max tool-use rounds actually EXECUTED per question (A6.2). One
  /// initial request plus up to this many executed tool rounds, plus one
  /// final follow-up request that is inspected but never executed again =
  /// at most `maxToolRounds + 1` API posts.
  static const int maxToolRounds = 5;

  static const String _fallbackMessage =
      "I couldn't finish answering that — try asking a simpler question.";

  static const String _askSystemPrompt = '''
You are the DukaSmart assistant for a single Kenyan kiosk (duka) owner.
Answer questions about their shop using ONLY the provided tools — never
invent, estimate, or recompute numbers yourself.

Rules:
- Money: quote the pre-formatted "*_display" strings from tool results
  exactly (e.g. "KES 12,450"). Never do arithmetic on money values.
- Reply in the language the user wrote in (English or Swahili).
- Keep answers short and plain: 1-4 sentences for a phone screen. No
  markdown headings. A short list is fine when naming several products.
- If a tool returns {"error": ...}, fix your input and call it again.
- If the data does not exist (e.g. a day was never closed), say so
  plainly instead of guessing.''';

  static const String _insightSystemPrompt = '''
You are the DukaSmart assistant writing one short insight for a Kenyan
kiosk owner's daily report. You are given a JSON snapshot computed
locally by the app. Write ONE plain-language paragraph of 2-4 sentences,
no markdown. Quote money using the "*_display" strings exactly; never
recompute figures. Cover at most: how today compares with recent days,
one notable expense pattern, and the most urgent stock run-out if any.
Never mention numbers that are not in the snapshot.''';

  /// The model needs today's date to translate "today"/"this week" into
  /// tool date ranges.
  String _askSystem() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return "$_askSystemPrompt\nToday's local date is $today.";
  }

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    final messages = <Map<String, Object?>>[
      for (final m in thread)
        {
          'role': m.role == AiRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
    ];

    // <= so the loop body runs maxToolRounds + 1 times at most: the first
    // `maxToolRounds` iterations may execute a tool round, the very last
    // iteration is a final follow-up that is only ever read, never acted
    // on (A6.2).
    for (var round = 0; round <= maxToolRounds; round++) {
      final response = await _post({
        'model': model,
        'max_tokens': 2048,
        'system': _askSystem(),
        'tools': DukaToolDispatcher.toolDefinitions,
        'messages': messages,
      });

      // A6.1: refusal is checked BEFORE touching `content` — required on
      // claude-opus-5, and a refusal response's content shape is not
      // guaranteed.
      final stopReason = response['stop_reason'];
      if (stopReason == 'refusal') {
        return "I can't help with that question.";
      }

      final content = _contentBlocks(response);

      switch (stopReason) {
        case 'end_turn':
          final text = _joinText(content);
          if (text.isNotEmpty) return text;
          throw const AiUnavailableError(AiFailureKind.error);

        case 'tool_use':
          if (round == maxToolRounds) {
            // A6.2: this is the final follow-up after the 5th executed
            // tool round — the model wants to keep going, but we stop
            // here rather than executing an unbounded 6th round.
            return _fallbackMessage;
          }
          // Echo the FULL assistant content back, then all tool results
          // in ONE user message — splitting them breaks the API
          // contract, and the API requires every tool_use to be answered
          // in the immediately following user turn (parallel tool calls
          // included).
          messages.add({'role': 'assistant', 'content': content});
          messages.add({
            'role': 'user',
            'content': await _executeToolCalls(content, tools),
          });
          continue;

        default:
          // A6.1: `max_tokens`, `stop_sequence`, missing/non-string, and
          // any other unknown stop_reason all become a generic failure —
          // never returned as text.
          throw const AiUnavailableError(AiFailureKind.error);
      }
    }

    return _fallbackMessage;
  }

  /// Executes every `tool_use` block in [content] and returns the
  /// `tool_result` list for the follow-up user message. A tool that
  /// throws during dispatch (A6.3) becomes an `is_error: true` result
  /// instead of propagating — the loop must keep going so the model can
  /// recover.
  Future<List<Map<String, Object?>>> _executeToolCalls(
    List<Map<String, dynamic>> content,
    DukaToolDispatcher tools,
  ) async {
    final results = <Map<String, Object?>>[];
    for (final block in content) {
      if (block['type'] != 'tool_use') continue;
      final toolUseId = block['id'];
      String output;
      var isError = false;
      try {
        final name = block['name'] as String;
        final input = Map<String, Object?>.from(block['input'] as Map? ?? const {});
        output = await tools.execute(name, input);
      } catch (e) {
        isError = true;
        output = jsonEncode({'error': 'Tool execution failed: $e'});
      }
      results.add({
        'type': 'tool_result',
        'tool_use_id': toolUseId,
        'content': output,
        if (isError) 'is_error': true,
      });
    }
    return results;
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) async {
    final response = await _post({
      'model': model,
      'max_tokens': 1024,
      'system': _insightSystemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': 'Shop snapshot JSON:\n${snapshot.toJsonString()}',
        },
      ],
    });

    // A6.1: no tools are offered here, so `end_turn` is the only stop
    // reason that carries usable text — refusal, max_tokens,
    // stop_sequence, tool_use, and unknown values all fail generically.
    if (response['stop_reason'] != 'end_turn') {
      throw const AiUnavailableError(AiFailureKind.error);
    }

    final text = _joinText(_contentBlocks(response));
    if (text.isEmpty) {
      throw const AiUnavailableError(AiFailureKind.error);
    }
    return text;
  }

  static String _joinText(List<Map<String, dynamic>> content) => content
      .where((b) => b['type'] == 'text')
      .map((b) => (b['text'] as String?) ?? '')
      .join()
      .trim();

  /// Defensively extracts the `content` list (A6.3): a missing, non-list,
  /// or oddly-shaped `content` field never throws here — it just yields
  /// no usable blocks, which the caller's stop_reason handling turns into
  /// a friendly failure instead of a raw TypeError.
  static List<Map<String, dynamic>> _contentBlocks(Map<String, dynamic> response) {
    final raw = response['content'];
    if (raw is! List) return const [];
    return [
      for (final block in raw)
        if (block is Map<String, dynamic>) block,
    ];
  }

  Future<Map<String, dynamic>> _post(Map<String, Object?> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': AiConfig.anthropicVersion,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiUnavailableError(AiFailureKind.offline);
    } on http.ClientException {
      // package:http wraps socket failures in ClientException on every
      // platform, including web — never catch dart:io SocketException
      // here, that import would break the Chrome dev target.
      throw const AiUnavailableError(AiFailureKind.offline);
    }

    if (response.statusCode != 200) {
      // A6.4: debug builds only, log status + request-id on 4xx — never
      // the key, never the body.
      if (kDebugMode && response.statusCode >= 400 && response.statusCode < 500) {
        debugPrint('AnthropicGateway: HTTP ${response.statusCode} '
            '(request-id: ${response.headers['request-id']})');
      }
      // A6.4: 429 AND every 5xx map to the "busy" message; every other
      // non-200 status is a generic failure.
      if (response.statusCode == 429 || response.statusCode >= 500) {
        throw const AiUnavailableError(AiFailureKind.busy);
      }
      throw const AiUnavailableError(AiFailureKind.error);
    }

    try {
      // Decode bytes as UTF-8 explicitly: without a charset in the
      // response content-type, `response.body` falls back to Latin-1 and
      // garbles Swahili replies.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const AiUnavailableError(AiFailureKind.error);
      }
      return decoded;
    } on AiUnavailableError {
      rethrow;
    } catch (_) {
      // A6.3: invalid UTF-8/JSON or any other decode failure never
      // surfaces as a raw FormatException.
      throw const AiUnavailableError(AiFailureKind.error);
    }
  }
}
