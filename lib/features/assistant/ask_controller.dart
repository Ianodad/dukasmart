import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_gateway.dart';
import '../../core/ai/ai_providers.dart';

/// One rendered bubble in the Ask thread.
class AskMessage {
  const AskMessage({
    required this.fromUser,
    required this.text,
    this.isError = false,
  });

  final bool fromUser;
  final String text;
  final bool isError;
}

class AskState {
  const AskState({this.messages = const [], this.sending = false});

  final List<AskMessage> messages;
  final bool sending;

  AskState copyWith({List<AskMessage>? messages, bool? sending}) => AskState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );
}

/// Session-only Q&A thread (spec: in-memory, cleared on leaving the
/// screen — hence autoDispose). Error bubbles are rendered but excluded
/// from the thread sent to the model.
///
/// A8.1/A8.2 (Codex amendments): fails closed when AI isn't available
/// (no gateway read, no request), guards every post-`await` state write
/// against use-after-dispose, always resets `sending` via `finally`, and
/// maps ANY gateway exception — not just [AiUnavailableError] — to a
/// friendly error bubble so the thread can never crash on an unexpected
/// throw.
class AskController extends AutoDisposeNotifier<AskState> {
  bool _disposed = false;

  @override
  AskState build() {
    ref.onDispose(() => _disposed = true);
    return const AskState();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    // A8.2: fail closed — no gateway read, no network path, when AI is
    // unavailable (unconfigured key, or explicitly gated off).
    if (!ref.read(aiAvailableProvider)) return;

    state = state.copyWith(
      messages: [...state.messages, AskMessage(fromUser: true, text: trimmed)],
      sending: true,
    );

    final thread = [
      for (final m in state.messages)
        if (!m.isError)
          AiMessage(m.fromUser ? AiRole.user : AiRole.assistant, m.text),
    ];

    try {
      final reply = await ref
          .read(aiGatewayProvider)
          .ask(thread, ref.read(dukaToolDispatcherProvider));
      // A8.1: the controller may have been disposed while the request
      // was in flight — writing to `state` after dispose throws.
      if (_disposed) return;
      state = state.copyWith(
        messages: [...state.messages, AskMessage(fromUser: false, text: reply)],
      );
    } on AiUnavailableError catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        messages: [
          ...state.messages,
          AskMessage(fromUser: false, text: e.userMessage, isError: true),
        ],
      );
    } catch (_) {
      // A8.1: any other exception (unexpected throw from the gateway)
      // still renders a friendly bubble instead of crashing the thread.
      if (_disposed) return;
      state = state.copyWith(
        messages: [
          ...state.messages,
          AskMessage(
            fromUser: false,
            text: const AiUnavailableError(AiFailureKind.error).userMessage,
            isError: true,
          ),
        ],
      );
    } finally {
      if (!_disposed) {
        state = state.copyWith(sending: false);
      }
    }
  }
}

final askControllerProvider =
    AutoDisposeNotifierProvider<AskController, AskState>(AskController.new);
