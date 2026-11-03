import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'watch.dart';

class LendingException implements Exception {
  LendingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RepaymentExceedsOutstanding extends LendingException {
  RepaymentExceedsOutstanding(this.outstandingPaise)
      : super('Repayment is more than the outstanding amount');
  final int outstandingPaise;
}

/// A loan with its person and how much has been paid back.
class LoanView {
  const LoanView(this.loan, this.person, this.repaidPaise);
  final Loan loan;
  final Person person;
  final int repaidPaise;

  int get outstandingPaise => loan.principalPaise - repaidPaise;
  bool get settled => outstandingPaise <= 0;
  bool get lent => loan.direction == 'lent';
}

/// One row on the Lending tab.
class PersonBalance {
  const PersonBalance({
    required this.person,
    required this.netPaise,
    required this.openLoans,
    required this.totalLoans,
    required this.lastActivity,
  });
  final Person person;

  /// Positive: they owe you. Negative: you owe them.
  final int netPaise;
  final int openLoans;
  final int totalLoans;
  final String lastActivity;

  bool get settled => openLoans == 0;
}

class LendingTotals {
  const LendingTotals({
    required this.getPaise,
    required this.owePaise,
    required this.getPeople,
    required this.owePeople,
  });
  final int getPaise;
  final int owePaise;
  final int getPeople;
  final int owePeople;
}

class LendingEvent {
  const LendingEvent({
    required this.date,
    required this.isRepayment,
    required this.amountPaise,
    required this.loanId,
    required this.direction,
    this.note,
  });
  final String date;
  final bool isRepayment;
  final int amountPaise;
  final int loanId;
  final String direction;
  final String? note;
}

class LendingRepository {
  LendingRepository(this.db);
  final AppDatabase db;

  // ---- people --------------------------------------------------------------

  static String nameKey(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// "rahul" → "Rahul". Mixed-case input such as "McDonald" is kept.
  static String displayName(String name) {
    final t = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t != t.toLowerCase() && t != t.toUpperCase()) return t;
    return t
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Future<Person?> personByExactName(String name) {
    final key = nameKey(name);
    return (db.select(db.people)..where((p) => p.nameKey.equals(key)))
        .getSingleOrNull();
  }

  /// People whose name could be the one meant: the exact match, or a name
  /// that extends / is extended by it at a word boundary ("Rahul" vs "Rahul K").
  Future<List<Person>> candidatePeople(String name) async {
    final key = nameKey(name);
    if (key.isEmpty) return [];
    final all = await db.select(db.people).get();
    final exact = all.where((p) => p.nameKey == key).toList();
    if (exact.isNotEmpty) return exact;
    return all
        .where((p) =>
            p.nameKey.startsWith('$key ') || key.startsWith('${p.nameKey} '))
        .toList();
  }

  Future<List<Person>> recentPeople(int limit) => (db.select(db.people)
        ..orderBy([(p) => OrderingTerm.desc(p.id)])
        ..limit(limit))
      .get();

  /// Finds the person by exact (case/space-insensitive) name, or creates them.
  Future<Person> findOrCreatePerson(String name) async {
    final key = nameKey(name);
    if (key.isEmpty) throw LendingException('Person name is empty');
    if (key.length > 60) throw LendingException('Person name is too long');
    final existing = await personByExactName(name);
    if (existing != null) return existing;
    final id = await db.into(db.people).insert(PeopleCompanion.insert(
          name: displayName(name),
          nameKey: key,
        ));
    return (db.select(db.people)..where((p) => p.id.equals(id))).getSingle();
  }

  // ---- loans ---------------------------------------------------------------

  Future<int> addLoan({
    required int personId,
    required String direction,
    required int principalPaise,
    String? note,
    String? paymentMethod,
    required String happenedOn,
    String? rawText,
  }) {
    if (direction != 'lent' && direction != 'borrowed') {
      throw LendingException('Direction must be lent or borrowed');
    }
    if (principalPaise <= 0) throw LendingException('Amount must be positive');
    final cleanNote = note?.trim();
    return db.into(db.loans).insert(LoansCompanion.insert(
          personId: personId,
          direction: direction,
          principalPaise: principalPaise,
          note: Value((cleanNote == null || cleanNote.isEmpty) ? null : cleanNote),
          paymentMethod: Value(paymentMethod),
          happenedOn: happenedOn,
          rawText: Value(rawText),
        ));
  }

  Future<void> softDeleteLoan(int id) =>
      (db.update(db.loans)..where((l) => l.id.equals(id)))
          .write(LoansCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restoreLoan(int id) =>
      (db.update(db.loans)..where((l) => l.id.equals(id)))
          .write(const LoansCompanion(deletedAt: Value(null)));

  /// Records a repayment. Fails if the loan is missing/deleted, the amount is
  /// not positive, or it is more than what is still outstanding.
  Future<int> addRepayment({
    required int loanId,
    required int amountPaise,
    required String paidOn,
    String? rawText,
  }) {
    if (amountPaise <= 0) throw LendingException('Amount must be positive');
    return db.transaction(() async {
      final view = await loanView(loanId);
      if (view == null) throw LendingException('Loan not found');
      if (amountPaise > view.outstandingPaise) {
        throw RepaymentExceedsOutstanding(view.outstandingPaise);
      }
      return db.into(db.loanRepayments).insert(LoanRepaymentsCompanion.insert(
            loanId: loanId,
            amountPaise: amountPaise,
            paidOn: paidOn,
            rawText: Value(rawText),
          ));
    });
  }

  Future<void> deleteRepayment(int id) =>
      (db.delete(db.loanRepayments)..where((r) => r.id.equals(id))).go();

  Future<Map<int, int>> _repaidByLoan() async {
    final rows = await db
        .customSelect(
          'SELECT loan_id, SUM(amount_paise) AS repaid FROM loan_repayments GROUP BY loan_id',
          readsFrom: {db.loanRepayments},
        )
        .get();
    return {for (final r in rows) r.read<int>('loan_id'): r.read<int>('repaid')};
  }

  Future<LoanView?> loanView(int id) async {
    final views = await loanViews();
    for (final v in views) {
      if (v.loan.id == id) return v;
    }
    return null;
  }

  /// Non-deleted loans, newest first.
  Future<List<LoanView>> loanViews({
    int? personId,
    String? direction,
    bool openOnly = false,
  }) async {
    final q = db.select(db.loans).join([
      innerJoin(db.people, db.people.id.equalsExp(db.loans.personId)),
    ]);
    Expression<bool> where = db.loans.deletedAt.isNull();
    if (personId != null) where = where & db.loans.personId.equals(personId);
    if (direction != null) where = where & db.loans.direction.equals(direction);
    q.where(where);
    q.orderBy([
      OrderingTerm.desc(db.loans.happenedOn),
      OrderingTerm.desc(db.loans.id),
    ]);
    final rows = await q.get();
    final repaid = await _repaidByLoan();
    final views = rows
        .map((r) => LoanView(
              r.readTable(db.loans),
              r.readTable(db.people),
              repaid[r.readTable(db.loans).id] ?? 0,
            ))
        .toList();
    return openOnly ? views.where((v) => !v.settled).toList() : views;
  }

  Stream<T> _watch<T>(Future<T> Function() load) => watchQuery(
      db, {db.loans, db.loanRepayments, db.people}, load);

  Stream<List<PersonBalance>> watchBalances() => _watch(balances);
  Stream<LendingTotals> watchTotals() => _watch(totals);

  /// One entry per person with any loan, open ones first.
  Future<List<PersonBalance>> balances() async {
    final views = await loanViews();
    final byPerson = <int, List<LoanView>>{};
    for (final v in views) {
      byPerson.putIfAbsent(v.person.id, () => []).add(v);
    }
    final result = <PersonBalance>[];
    for (final entry in byPerson.entries) {
      final list = entry.value;
      var net = 0;
      var open = 0;
      var last = '';
      for (final v in list) {
        net += v.lent ? v.outstandingPaise : -v.outstandingPaise;
        if (!v.settled) open++;
        if (v.loan.happenedOn.compareTo(last) > 0) last = v.loan.happenedOn;
      }
      final repayments = await (db.select(db.loanRepayments)
            ..where((r) => r.loanId.isIn(list.map((v) => v.loan.id).toList())))
          .get();
      for (final r in repayments) {
        if (r.paidOn.compareTo(last) > 0) last = r.paidOn;
      }
      result.add(PersonBalance(
        person: list.first.person,
        netPaise: net,
        openLoans: open,
        totalLoans: list.length,
        lastActivity: last,
      ));
    }
    result.sort((a, b) {
      if (a.settled != b.settled) return a.settled ? 1 : -1;
      return b.lastActivity.compareTo(a.lastActivity);
    });
    return result;
  }

  /// "You'll get" and "You owe": sums of outstanding by direction.
  Future<LendingTotals> totals() async {
    final views = await loanViews(openOnly: true);
    var get = 0, owe = 0;
    final getPeople = <int>{}, owePeople = <int>{};
    for (final v in views) {
      if (v.lent) {
        get += v.outstandingPaise;
        getPeople.add(v.person.id);
      } else {
        owe += v.outstandingPaise;
        owePeople.add(v.person.id);
      }
    }
    return LendingTotals(
      getPaise: get,
      owePaise: owe,
      getPeople: getPeople.length,
      owePeople: owePeople.length,
    );
  }

  /// Loans and repayments for one person, oldest first.
  Future<List<LendingEvent>> history(int personId) async {
    final views = await loanViews(personId: personId);
    final events = <LendingEvent>[];
    for (final v in views) {
      events.add(LendingEvent(
        date: v.loan.happenedOn,
        isRepayment: false,
        amountPaise: v.loan.principalPaise,
        loanId: v.loan.id,
        direction: v.loan.direction,
        note: v.loan.note,
      ));
    }
    final repayments = await (db.select(db.loanRepayments)
          ..where((r) => r.loanId.isIn(views.map((v) => v.loan.id).toList())))
        .get();
    final dirById = {for (final v in views) v.loan.id: v.loan.direction};
    for (final r in repayments) {
      events.add(LendingEvent(
        date: r.paidOn,
        isRepayment: true,
        amountPaise: r.amountPaise,
        loanId: r.loanId,
        direction: dirById[r.loanId]!,
      ));
    }
    events.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      if (a.isRepayment != b.isRepayment) return a.isRepayment ? 1 : -1;
      return a.loanId.compareTo(b.loanId);
    });
    return events;
  }
}
