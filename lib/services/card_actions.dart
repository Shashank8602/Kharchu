import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../core/money.dart';
import '../data/db/app_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/lending_repository.dart';
import 'agent/proposals.dart';
import 'agent/tool_executor.dart';
import 'agent/tool_outcome.dart';
import 'budget_alerts.dart';

sealed class CommitResult {
  const CommitResult();
}

/// Written. [entityRef] is like 'expense:42'.
class Committed extends CommitResult {
  const Committed(this.entityRef, {this.expenseId});
  final String entityRef;
  final int? expenseId;
}

/// The card was already handled (for example a double tap).
class AlreadyHandled extends CommitResult {
  const AlreadyHandled();
}

/// The thing the card was about changed or vanished. The card is expired.
class Expired extends CommitResult {
  const Expired(this.message);
  final String message;
}

/// Could not be written; the card stays pending so the user can fix it.
class CommitFailed extends CommitResult {
  const CommitFailed(this.message);
  final String message;
}

/// Carries out what the user approved on a card. This is the only place the
/// chat writes to the database.
class CardActions {
  CardActions({
    required this.db,
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.lending,
    required this.chat,
    required this.executor,
    required this.alerts,
    required this.today,
  });

  final AppDatabase db;
  final ExpenseRepository expenses;
  final CategoryRepository categories;
  final BudgetRepository budgets;
  final LendingRepository lending;
  final ChatRepository chat;
  final ToolExecutor executor;
  final BudgetAlerts alerts;
  final String Function() today;

  Proposal _parse(ChatMessage m) =>
      Proposal.fromJson(jsonDecode(m.cardPayload!) as Map<String, dynamic>);

  /// Saves what the card describes. [edited] replaces the stored proposal
  /// (used by the Edit sheet, where Save is the confirmation).
  Future<CommitResult> confirm(String messageId, {Proposal? edited}) async {
    final msg = await chat.byId(messageId);
    if (msg == null || msg.role != 'card' || msg.cardPayload == null) {
      return const CommitFailed('That card is gone.');
    }
    if (msg.cardStatus != 'pending') return const AlreadyHandled();

    final Proposal proposal;
    try {
      proposal = edited ?? _parse(msg);
    } catch (_) {
      return const CommitFailed('That card could not be read.');
    }
    if (proposal is PickProposal) return const CommitFailed('Choose one first.');

    final isExpenseChange = proposal is AddExpenseProposal ||
        proposal is UpdateExpenseProposal ||
        proposal is DeleteExpenseProposal;
    final todayIso = today();
    final before = isExpenseChange ? await alerts.snapshot(todayIso) : null;

    final CommitResult result;
    try {
      result = await db.transaction(() async {
        // Re-check inside the transaction so two taps cannot both save.
        final fresh = await chat.byId(messageId);
        if (fresh == null || fresh.cardStatus != 'pending') return const AlreadyHandled();
        final r = await _apply(proposal);
        if (r is Committed) {
          await chat.updateCard(messageId,
              status: 'confirmed',
              entityRef: r.entityRef,
              payload: jsonEncode(proposal.toJson()));
        } else if (r is Expired) {
          await chat.updateCard(messageId, status: 'expired');
        }
        return r;
      });
    } on RepaymentExceedsOutstanding catch (e) {
      return CommitFailed(
          'Only ${formatINR(e.outstandingPaise)} is outstanding now, so that repayment is too much.');
    } on LendingException catch (e) {
      return CommitFailed(e.message);
    } on ArgumentError catch (e) {
      return CommitFailed('${e.message}');
    } catch (_) {
      return const CommitFailed("Couldn't save that. Try again.");
    }

    if (result is Committed && before != null) {
      final after = await alerts.snapshot(todayIso);
      for (final n in await alerts.evaluate(before, after, todayIso)) {
        await chat.add(
          day: todayIso,
          role: 'notice',
          body: n.text,
          cardType: 'budget_notice',
          cardPayload: jsonEncode({'level': n.level, 'percent': n.percent}),
        );
      }
    }
    return result;
  }

  Future<CommitResult> _apply(Proposal p) async {
    switch (p) {
      case AddExpenseProposal():
        var catId = p.categoryId;
        if (p.isNewCategory || catId == null) {
          catId = (await categories.create(p.categoryName)).id;
        } else {
          final c = await categories.byId(catId);
          if (c == null || c.isArchived) {
            // The category was archived since the card appeared; use its name.
            catId = (await categories.resolve(p.categoryName))?.id ??
                (await categories.create(p.categoryName)).id;
          }
        }
        final id = await expenses.add(
          amountPaise: p.amountPaise,
          categoryId: catId,
          item: p.item,
          location: p.location,
          paymentMethod: p.paymentMethod,
          spentOn: p.spentOn,
          rawText: p.rawText,
          source: p.source,
        );
        return Committed('expense:$id', expenseId: id);

      case UpdateExpenseProposal():
        final row = await expenses.getById(p.expenseId);
        if (row == null) return const Expired('That expense no longer exists.');
        if (row.expense.updatedAt.toIso8601String() != p.updatedAtBefore) {
          return const Expired('That expense changed since. Ask again.');
        }
        final c = p.changes;
        var catId = c['categoryId'] as int?;
        if (catId != null && (await categories.byId(catId)) == null) {
          return const Expired('That category no longer exists.');
        }
        await expenses.update(
          p.expenseId,
          ExpensesCompanion(
            amountPaise: c.containsKey('amountPaise') ? Value(c['amountPaise'] as int) : const Value.absent(),
            item: c.containsKey('item') ? Value(c['item'] as String) : const Value.absent(),
            categoryId: catId != null ? Value(catId) : const Value.absent(),
            location: c.containsKey('location') ? Value(c['location'] as String?) : const Value.absent(),
            paymentMethod: c.containsKey('paymentMethod')
                ? Value(c['paymentMethod'] as String?)
                : const Value.absent(),
            spentOn: c.containsKey('spentOn') ? Value(c['spentOn'] as String) : const Value.absent(),
          ),
        );
        return Committed('expense:${p.expenseId}', expenseId: p.expenseId);

      case DeleteExpenseProposal():
        final row = await expenses.getById(p.expenseId);
        if (row == null) return const Expired('That expense is already gone.');
        if (row.expense.updatedAt.toIso8601String() != p.updatedAtBefore) {
          return const Expired('That expense changed since. Ask again.');
        }
        await expenses.softDelete(p.expenseId);
        return Committed('expense:${p.expenseId}', expenseId: p.expenseId);

      case SetBudgetProposal():
        int? catId = p.categoryId;
        if (catId != null && (await categories.byId(catId)) == null) {
          return const Expired('That category no longer exists.');
        }
        if (!await budgets.upsert(catId, p.limitPaise)) {
          return const CommitFailed('That budget amount is not valid.');
        }
        return Committed('budget:${catId ?? 'overall'}');

      case LoanProposal():
        final personId = p.personId != null && await _personExists(p.personId!)
            ? p.personId!
            : (await lending.findOrCreatePerson(p.personName)).id;
        final id = await lending.addLoan(
          personId: personId,
          direction: p.direction,
          principalPaise: p.amountPaise,
          note: p.note,
          paymentMethod: p.paymentMethod,
          happenedOn: p.happenedOn,
          rawText: p.rawText,
        );
        return Committed('loan:$id');

      case RepaymentProposal():
        await lending.addRepayment(
          loanId: p.loanId,
          amountPaise: p.amountPaise,
          paidOn: p.paidOn,
          rawText: p.rawText,
        );
        return Committed('loan:${p.loanId}');

      case PickProposal():
        return const CommitFailed('Choose one first.');
    }
  }

  Future<bool> _personExists(int id) async =>
      (await lending.recentPeople(100000)).any((x) => x.id == id);

  /// The user dismissed the card.
  Future<void> cancel(String messageId) async {
    final msg = await chat.byId(messageId);
    if (msg == null || msg.cardStatus != 'pending') return;
    await chat.updateCard(messageId, status: 'cancelled');
  }

  /// Stores a changed proposal on a pending card (for example the payment
  /// method chosen from the chips) without saving it.
  Future<void> updatePending(String messageId, Proposal p) async {
    final msg = await chat.byId(messageId);
    if (msg == null || msg.cardStatus != 'pending') return;
    await chat.updateCard(messageId, payload: jsonEncode(p.toJson()));
  }

  /// The user chose one item on a pick card. The pick card is closed and the
  /// real proposal becomes a new card. Returns an error message, or null.
  Future<String?> choose(String messageId, int itemId) async {
    final msg = await chat.byId(messageId);
    if (msg == null || msg.cardStatus != 'pending') return null;
    final pick = _parse(msg);
    if (pick is! PickProposal) return null;
    final outcome = await executor.resolvePick(pick, itemId);
    switch (outcome) {
      case ProposalResult(:final proposal):
        await chat.updateCard(messageId, status: 'confirmed');
        await chat.add(
          day: msg.day,
          role: 'card',
          cardType: proposal.type,
          cardPayload: jsonEncode(proposal.toJson()),
          cardStatus: 'pending',
        );
        return null;
      case ToolError(:final message):
        await chat.updateCard(messageId, status: 'expired');
        return message;
      case ReadResult():
        return 'Something went wrong.';
    }
  }

  /// Brings back a just-deleted expense and hides its chip.
  Future<void> undoDelete(String messageId, int expenseId) async {
    await expenses.restore(expenseId);
    await chat.updateCard(messageId, status: 'cancelled');
  }
}
