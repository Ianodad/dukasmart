import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// The provider-agnostic AI seam (spec: "the ONLY seam to the network").
/// Features depend on this interface via Riverpod — never on the
/// Anthropic implementation directly. Swapping to a backend proxy later
/// is one new implementation class.

enum AiRole { user, assistant }

/// One turn of an Ask thread, provider-neutral.
class AiMessage {
  const AiMessage(this.role, this.text);

  final AiRole role;
  final String text;
}

enum AiFailureKind { offline, busy, error }

/// Thrown by gateway implementations for every failure mode. Features
/// render [userMessage] — they never see raw exceptions or status codes.
class AiUnavailableError implements Exception {
  const AiUnavailableError(this.kind);

  final AiFailureKind kind;

  String get userMessage => switch (kind) {
        AiFailureKind.offline => "You're offline — asking needs internet.",
        AiFailureKind.busy => 'AI is busy — try again shortly.',
        AiFailureKind.error => 'Something went wrong — please try again.',
      };

  @override
  String toString() => 'AiUnavailableError($kind)';
}

abstract class AiGateway {
  /// Multi-turn Q&A with tool use. Returns the final assistant text.
  /// Throws [AiUnavailableError] on network/API failure.
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools);

  /// One-shot insight paragraph from a precomputed snapshot.
  /// Throws [AiUnavailableError] on network/API failure.
  Future<String> generateInsight(ShopSnapshot snapshot);
}
