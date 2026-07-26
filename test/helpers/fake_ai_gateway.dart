import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';

/// Canned-response [AiGateway] for tests. Set [error] (mutable) to make
/// the next call throw; [askCalls] records every thread sent.
class FakeAiGateway implements AiGateway {
  FakeAiGateway({
    this.reply = 'Fake reply.',
    this.insight = 'Fake insight.',
    this.error,
  });

  final String reply;
  final String insight;
  AiUnavailableError? error;
  final List<List<AiMessage>> askCalls = [];

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    askCalls.add(List.of(thread));
    final e = error;
    if (e != null) throw e;
    return reply;
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) async {
    final e = error;
    if (e != null) throw e;
    return insight;
  }
}
