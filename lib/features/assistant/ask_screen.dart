import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/ai/ai_providers.dart';
import 'ask_controller.dart';

/// Ask your duka (route `/home/ask`) — spec UX surface: a focused Q&A
/// thread with suggestion chips on the empty state. The thread is
/// session-only; leaving the screen disposes the autoDispose controller.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _suggestions = [
    'What did I sell today?',
    'Nimetumia pesa ngapi kwa transport wiki hii?',
    "What's running low?",
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    ref.read(askControllerProvider.notifier).send(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A9.1: a deep link into this route must never construct a network
    // client when AI isn't configured. Gate on availability BEFORE
    // touching askControllerProvider (or anything downstream of it) so
    // the gateway provider is never read.
    final available = ref.watch(aiAvailableProvider);
    if (!available) {
      return const _AiUnavailableScreen();
    }

    final state = ref.watch(askControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask your duka')),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyThread(onSuggestion: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: state.messages[index]);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: state.sending ? null : _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your duka…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.sending ? null : () => _send(_input.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A9.1: safe placeholder for deep links / navigation to `/home/ask` when
/// AI isn't configured. Renders no chat surface at all — no `TextField`,
/// no send affordance — so there is nothing that could trigger a network
/// call, and `aiGatewayProvider` / `askControllerProvider` are never read.
class _AiUnavailableScreen extends StatelessWidget {
  const _AiUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask your duka')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppTokens.inkMuted),
            const SizedBox(height: 12),
            Text(
              "Asking isn't available on this build.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 40, color: AppTokens.inkMuted),
          const SizedBox(height: 12),
          Text(
            'Ask about your sales, expenses, stock, or what to restock — in '
            'English au Kiswahili.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final suggestion in _AskScreenState._suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestion(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AskMessage message;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color textColor;
    if (message.isError) {
      background = AppTokens.redContainer;
      textColor = AppTokens.red;
    } else if (message.fromUser) {
      background = AppTokens.emeraldContainer;
      textColor = AppTokens.ink;
    } else {
      background = AppTokens.surfaceMuted;
      textColor = AppTokens.ink;
    }

    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.body.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking…',
              style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
