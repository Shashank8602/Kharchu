import 'package:kharchu/services/agent/agent_service.dart';
import 'package:kharchu/services/agent/proposals.dart';
import 'package:kharchu/services/groq/groq_errors.dart';

/// One real message, and what a correct result looks like.
class EvalCase {
  const EvalCase(this.input, this.check, {this.kannada = false});
  final String input;

  /// Returns the problems found (empty = correct).
  final List<String> Function(AgentReply reply) check;
  final bool kannada;
}

// "Today" in the eval is Saturday 2026-10-24.
//
// Seed (the same for every case):
//   expenses  #1 Chats ₹1,000 (Food, 24 Oct)      #2 Dinner ₹1,200 at Meghana's (Food, 18 Oct)
//             #3 Dinner ₹2,920 (Food, 13 Oct)     #4 Petrol ₹1,050 (Transport, 22 Oct)
//   loans     #1 Rahul lent ₹2,000 "Goa trip"     #2 Priya borrowed ₹1,500

final _kannada = RegExp(r'[ಀ-೿]');

List<String> _add(
  AgentReply r, {
  required int paise,
  Set<String>? categories,
  String? itemHas,
  String? location,
  String? payment,
  String? date,
  bool anyCategory = false,
}) {
  if (r is! AgentCard) return ['expected an add card, got ${_describe(r)}'];
  final p = r.proposal;
  if (p is! AddExpenseProposal) return ['expected add_expense, got ${p.type}'];
  final f = <String>[];
  if (p.amountPaise != paise) f.add('amount ${p.amountPaise} != $paise');
  if (!anyCategory && categories != null && !categories.contains(p.categoryName)) {
    f.add('category "${p.categoryName}" not in $categories');
  }
  if (itemHas != null && !p.item.toLowerCase().contains(itemHas.toLowerCase())) {
    f.add('item "${p.item}" lacks "$itemHas"');
  }
  if (location != null && (p.location ?? '').toLowerCase() != location.toLowerCase()) {
    f.add('location "${p.location}" != "$location"');
  }
  if (payment != null && p.paymentMethod != payment) {
    f.add('payment "${p.paymentMethod}" != "$payment"');
  }
  if (date != null && p.spentOn != date) f.add('date ${p.spentOn} != $date');
  return f;
}

List<String> _loan(AgentReply r, {required String dir, required String person, required int paise, String? noteHas, String? payment}) {
  if (r is! AgentCard) return ['expected a loan card, got ${_describe(r)}'];
  final p = r.proposal;
  if (p is! LoanProposal) return ['expected loan, got ${p.type}'];
  final f = <String>[];
  if (p.direction != dir) f.add('direction ${p.direction} != $dir');
  if (p.personName.toLowerCase() != person.toLowerCase()) f.add('person "${p.personName}" != "$person"');
  if (p.amountPaise != paise) f.add('amount ${p.amountPaise} != $paise');
  if (noteHas != null && !(p.note ?? '').toLowerCase().contains(noteHas)) f.add('note "${p.note}" lacks "$noteHas"');
  if (payment != null && p.paymentMethod != payment) f.add('payment ${p.paymentMethod} != $payment');
  return f;
}

List<String> _repay(AgentReply r, {required int loanId, required int paise}) {
  if (r is! AgentCard) return ['expected a repayment card, got ${_describe(r)}'];
  final p = r.proposal;
  if (p is! RepaymentProposal) return ['expected repayment, got ${p.type}'];
  return [
    if (p.loanId != loanId) 'loan ${p.loanId} != $loanId',
    if (p.amountPaise != paise) 'amount ${p.amountPaise} != $paise',
  ];
}

List<String> _answer(AgentReply r, {List<String> has = const [], bool english = true}) {
  if (r is! AgentAnswer) return ['expected a text answer, got ${_describe(r)}'];
  final f = <String>[];
  for (final h in has) {
    if (!r.text.contains(h)) f.add('answer lacks "$h": "${r.text}"');
  }
  if (english && _kannada.hasMatch(r.text)) f.add('answer is not in English: "${r.text}"');
  return f;
}

String _describe(AgentReply r) => switch (r) {
      AgentAnswer(:final text) => 'answer "$text"',
      AgentCard(:final proposal) => 'card ${proposal.type}',
      AgentFailure(:final error) => error is GroqBadRequest
          ? 'failure GroqBadRequest: ${error.detail}'
          : 'failure ${error.runtimeType}',
    };

const _food = {'Food & Dining'};
const _transport = {'Transport'};

final evalCases = <EvalCase>[
  // ---- spending, English
  EvalCase('I spent Rs.1000 to eat chats in Bengaluru',
      (r) => _add(r, paise: 100000, categories: _food, itemHas: 'chat', location: 'Bengaluru', date: '2026-10-24')),
  EvalCase('auto 240 cash',
      (r) => _add(r, paise: 24000, categories: _transport, payment: 'cash')),
  EvalCase('2.5k shoes from Decathlon via card yesterday',
      (r) => _add(r, paise: 250000, categories: {'Shopping'}, payment: 'card', date: '2026-10-23')),
  EvalCase('petrol 1050 gpay',
      (r) => _add(r, paise: 105000, categories: _transport, payment: 'upi')),
  EvalCase('paid 1,499 for electricity bill',
      (r) => _add(r, paise: 149900, categories: {'Bills & Utilities'})),
  EvalCase('bought vegetables for 380 at KR Market',
      (r) => _add(r, paise: 38000, categories: {'Groceries'}, location: 'KR Market')),
  EvalCase('movie tickets 830 last Sunday',
      (r) => _add(r, paise: 83000, categories: {'Entertainment'}, date: '2026-10-18')),
  EvalCase('dinner at Meghana\'s 1200 on 18th Oct',
      (r) => _add(r, paise: 120000, categories: _food, date: '2026-10-18')),
  EvalCase('rent 15000', (r) => _add(r, paise: 1500000, categories: {'Rent & Housing'})),
  EvalCase('haircut 350', (r) => _add(r, paise: 35000, anyCategory: true, itemHas: 'hair')),
  EvalCase('pharmacy 300 card',
      (r) => _add(r, paise: 30000, categories: {'Health'}, payment: 'card')),

  // ---- spending, Kannada
  EvalCase('ನಿನ್ನೆ ಪೆಟ್ರೋಲ್‌ಗೆ 500 ರೂ ಕೊಟ್ಟೆ',
      (r) => _add(r, paise: 50000, categories: _transport, date: '2026-10-23'), kannada: true),
  EvalCase('ಇಂದು ಚಹಾ 20 ರೂಪಾಯಿ', (r) => _add(r, paise: 2000, categories: _food), kannada: true),
  EvalCase('ತರಕಾರಿ 250 ರೂ', (r) => _add(r, paise: 25000, categories: {'Groceries'}), kannada: true),
  EvalCase('ಆಟೋಗೆ 80 ರೂಪಾಯಿ ಕೊಟ್ಟೆ', (r) => _add(r, paise: 8000, categories: _transport), kannada: true),
  EvalCase('ಮೆಡಿಕಲ್ ಸ್ಟೋರ್ 340 ರೂ', (r) => _add(r, paise: 34000, categories: {'Health'}), kannada: true),

  // ---- lending
  EvalCase('lent 2000 to Rahul for his Goa trip on gpay',
      (r) => _loan(r, dir: 'lent', person: 'Rahul', paise: 200000, noteHas: 'goa', payment: 'upi')),
  EvalCase('borrowed 1500 from Priya',
      (r) => _loan(r, dir: 'borrowed', person: 'Priya', paise: 150000)),
  EvalCase('Rahul returned 1000', (r) => _repay(r, loanId: 1, paise: 100000)),
  EvalCase('paid back Priya 500', (r) => _repay(r, loanId: 2, paise: 50000)),
  EvalCase('ರಾಹುಲ್‌ಗೆ 500 ಸಾಲ ಕೊಟ್ಟೆ',
      (r) => _loan(r, dir: 'lent', person: 'Rahul', paise: 50000), kannada: true),

  // ---- edit and delete
  EvalCase("change last Sunday's dinner at Meghana's to 1450", (r) {
    if (r is! AgentCard) return ['expected an update card, got ${_describe(r)}'];
    final p = r.proposal;
    if (p is! UpdateExpenseProposal) return ['expected update_expense, got ${p.type}'];
    return [
      if (p.expenseId != 2) 'expense ${p.expenseId} != 2',
      if (p.changes['amountPaise'] != 145000) 'amount ${p.changes['amountPaise']} != 145000',
    ];
  }),
  EvalCase('change the last expense to 800', (r) {
    if (r is! AgentCard) return ['expected an update card, got ${_describe(r)}'];
    final p = r.proposal;
    if (p is! UpdateExpenseProposal) return ['expected update_expense, got ${p.type}'];
    return [
      if (p.expenseId != 1) 'expense ${p.expenseId} != 1',
      if (p.changes['amountPaise'] != 80000) 'amount ${p.changes['amountPaise']} != 80000',
    ];
  }),
  EvalCase('delete the petrol expense', (r) {
    if (r is! AgentCard) return ['expected a delete card, got ${_describe(r)}'];
    final p = r.proposal;
    if (p is! DeleteExpenseProposal) return ['expected delete_expense, got ${p.type}'];
    return [if (p.expenseId != 4) 'expense ${p.expenseId} != 4'];
  }),

  // ---- questions
  EvalCase('how much did I spend on food this month?', (r) => _answer(r, has: ['5,120'])),
  EvalCase('ಈ ತಿಂಗಳು ಊಟಕ್ಕೆ ಎಷ್ಟು ಖರ್ಚಾಯ್ತು?', (r) => _answer(r, has: ['5,120']), kannada: true),
  EvalCase('who owes me money?', (r) => _answer(r, has: ['Rahul', '2,000'])),
  EvalCase('top 3 categories this month', (r) => _answer(r, has: ['Food'])),

  // ---- budget, and things it should refuse
  EvalCase('set food budget to 6000', (r) {
    if (r is! AgentCard) return ['expected a budget card, got ${_describe(r)}'];
    final p = r.proposal;
    if (p is! SetBudgetProposal) return ['expected set_budget, got ${p.type}'];
    return [
      if (p.categoryName != 'Food & Dining') 'category ${p.categoryName}',
      if (p.limitPaise != 600000) 'limit ${p.limitPaise} != 600000',
    ];
  }),
  EvalCase("what's the weather in Bengaluru?", (r) {
    if (r is AgentCard) return ['an off-topic message produced a card (${r.proposal.type})'];
    return _answer(r);
  }),
];
