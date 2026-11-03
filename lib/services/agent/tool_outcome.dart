import 'proposals.dart';

/// What running one of the AI's tool calls produced.
sealed class ToolOutcome {
  const ToolOutcome();
}

/// A lookup result, sent back to the model so it can carry on.
class ReadResult extends ToolOutcome {
  const ReadResult(this.data);
  final Map<String, dynamic> data;
}

/// The call was invalid. The message goes back to the model so it can fix it
/// (never shown to the user).
class ToolError extends ToolOutcome {
  const ToolError(this.message);
  final String message;
}

/// A change to confirm. Ends the loop and becomes a card.
class ProposalResult extends ToolOutcome {
  const ProposalResult(this.proposal);
  final Proposal proposal;
}
