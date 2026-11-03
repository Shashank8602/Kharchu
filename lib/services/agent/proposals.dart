import '../../core/money.dart';

/// What the AI wants to do. A proposal never touches the database: it becomes
/// a card, and only the user's tap writes anything.
sealed class Proposal {
  const Proposal();

  String get type;
  Map<String, dynamic> toJson();

  /// One line used on the saved chip and in the AI's short-term memory.
  String get summary;

  static Proposal fromJson(Map<String, dynamic> j) => switch (j['type']) {
        'add_expense' => AddExpenseProposal.fromJson(j),
        'update_expense' => UpdateExpenseProposal.fromJson(j),
        'delete_expense' => DeleteExpenseProposal.fromJson(j),
        'set_budget' => SetBudgetProposal.fromJson(j),
        'loan' => LoanProposal.fromJson(j),
        'repayment' => RepaymentProposal.fromJson(j),
        'pick' => PickProposal.fromJson(j),
        _ => throw FormatException('Unknown proposal type: ${j['type']}'),
      };
}

class AddExpenseProposal extends Proposal {
  const AddExpenseProposal({
    required this.amountPaise,
    required this.item,
    required this.categoryName,
    this.categoryId,
    this.isNewCategory = false,
    this.location,
    this.paymentMethod,
    required this.spentOn,
    this.rawText,
    this.source = 'chat',
    this.warnings = const [],
  });

  final int amountPaise;
  final String item;
  final String categoryName;

  /// Null while the category is new and not yet created.
  final int? categoryId;
  final bool isNewCategory;
  final String? location;
  final String? paymentMethod;
  final String spentOn;
  final String? rawText;
  final String source;

  /// 'large_amount', 'future_date'.
  final List<String> warnings;

  @override
  String get type => 'add_expense';

  @override
  String get summary => '${formatINR(amountPaise)} $item · $categoryName';

  AddExpenseProposal copyWith({
    int? amountPaise,
    String? item,
    String? categoryName,
    int? categoryId,
    bool? isNewCategory,
    String? location,
    bool clearLocation = false,
    String? paymentMethod,
    bool clearPayment = false,
    String? spentOn,
    List<String>? warnings,
  }) =>
      AddExpenseProposal(
        amountPaise: amountPaise ?? this.amountPaise,
        item: item ?? this.item,
        categoryName: categoryName ?? this.categoryName,
        categoryId: categoryId ?? this.categoryId,
        isNewCategory: isNewCategory ?? this.isNewCategory,
        location: clearLocation ? null : (location ?? this.location),
        paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
        spentOn: spentOn ?? this.spentOn,
        rawText: rawText,
        source: source,
        warnings: warnings ?? this.warnings,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'amountPaise': amountPaise,
        'item': item,
        'categoryName': categoryName,
        'categoryId': categoryId,
        'isNewCategory': isNewCategory,
        'location': location,
        'paymentMethod': paymentMethod,
        'spentOn': spentOn,
        'rawText': rawText,
        'source': source,
        'warnings': warnings,
      };

  factory AddExpenseProposal.fromJson(Map<String, dynamic> j) => AddExpenseProposal(
        amountPaise: j['amountPaise'] as int,
        item: j['item'] as String,
        categoryName: j['categoryName'] as String,
        categoryId: j['categoryId'] as int?,
        isNewCategory: j['isNewCategory'] as bool? ?? false,
        location: j['location'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        spentOn: j['spentOn'] as String,
        rawText: j['rawText'] as String?,
        source: j['source'] as String? ?? 'chat',
        warnings: (j['warnings'] as List?)?.cast<String>() ?? const [],
      );
}

class UpdateExpenseProposal extends Proposal {
  const UpdateExpenseProposal({
    required this.expenseId,
    required this.before,
    required this.changes,
    required this.updatedAtBefore,
  });

  final int expenseId;

  /// Snapshot shown as "before": item, amountPaise, categoryName, location,
  /// paymentMethod, spentOn.
  final Map<String, dynamic> before;

  /// Keys among: amountPaise, item, categoryId, categoryName, location,
  /// paymentMethod, spentOn. A key with a null value clears that field.
  final Map<String, dynamic> changes;

  /// updatedAt of the expense when this was proposed; if it differs when the
  /// user taps, the expense changed elsewhere and the card has expired.
  final String updatedAtBefore;

  @override
  String get type => 'update_expense';

  String get itemBefore => before['item'] as String;

  @override
  String get summary {
    final parts = <String>[];
    if (changes.containsKey('amountPaise')) {
      parts.add('${formatINR(before['amountPaise'] as int)} → '
          '${formatINR(changes['amountPaise'] as int)}');
    }
    if (changes.containsKey('categoryName')) {
      parts.add('${before['categoryName']} → ${changes['categoryName']}');
    }
    if (changes.containsKey('item')) parts.add('${before['item']} → ${changes['item']}');
    if (changes.containsKey('spentOn')) {
      parts.add('${before['spentOn']} → ${changes['spentOn']}');
    }
    if (changes.containsKey('location')) parts.add('location updated');
    if (changes.containsKey('paymentMethod')) parts.add('payment updated');
    return 'Updated #$expenseId $itemBefore: ${parts.join(', ')}';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'expenseId': expenseId,
        'before': before,
        'changes': changes,
        'updatedAtBefore': updatedAtBefore,
      };

  factory UpdateExpenseProposal.fromJson(Map<String, dynamic> j) =>
      UpdateExpenseProposal(
        expenseId: j['expenseId'] as int,
        before: Map<String, dynamic>.from(j['before'] as Map),
        changes: Map<String, dynamic>.from(j['changes'] as Map),
        updatedAtBefore: j['updatedAtBefore'] as String,
      );
}

class DeleteExpenseProposal extends Proposal {
  const DeleteExpenseProposal({
    required this.expenseId,
    required this.item,
    required this.amountPaise,
    required this.categoryName,
    required this.spentOn,
    required this.updatedAtBefore,
  });

  final int expenseId;
  final String item;
  final int amountPaise;
  final String categoryName;
  final String spentOn;
  final String updatedAtBefore;

  @override
  String get type => 'delete_expense';

  @override
  String get summary => 'Deleted #$expenseId ${formatINR(amountPaise)} $item';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'expenseId': expenseId,
        'item': item,
        'amountPaise': amountPaise,
        'categoryName': categoryName,
        'spentOn': spentOn,
        'updatedAtBefore': updatedAtBefore,
      };

  factory DeleteExpenseProposal.fromJson(Map<String, dynamic> j) =>
      DeleteExpenseProposal(
        expenseId: j['expenseId'] as int,
        item: j['item'] as String,
        amountPaise: j['amountPaise'] as int,
        categoryName: j['categoryName'] as String,
        spentOn: j['spentOn'] as String,
        updatedAtBefore: j['updatedAtBefore'] as String,
      );
}

class SetBudgetProposal extends Proposal {
  const SetBudgetProposal({
    this.categoryId,
    required this.categoryName,
    required this.limitPaise,
    this.previousLimitPaise,
  });

  /// Null means the overall monthly budget.
  final int? categoryId;
  final String categoryName;
  final int limitPaise;
  final int? previousLimitPaise;

  @override
  String get type => 'set_budget';

  @override
  String get summary => '$categoryName budget ${formatINR(limitPaise)}/month';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'limitPaise': limitPaise,
        'previousLimitPaise': previousLimitPaise,
      };

  factory SetBudgetProposal.fromJson(Map<String, dynamic> j) => SetBudgetProposal(
        categoryId: j['categoryId'] as int?,
        categoryName: j['categoryName'] as String,
        limitPaise: j['limitPaise'] as int,
        previousLimitPaise: j['previousLimitPaise'] as int?,
      );
}

class LoanProposal extends Proposal {
  const LoanProposal({
    required this.direction,
    required this.personName,
    this.personId,
    required this.amountPaise,
    this.note,
    this.paymentMethod,
    required this.happenedOn,
    this.rawText,
    this.warnings = const [],
  });

  /// 'lent' (they owe you) or 'borrowed' (you owe them).
  final String direction;
  final String personName;

  /// Null when this person does not exist yet.
  final int? personId;
  final int amountPaise;
  final String? note;
  final String? paymentMethod;
  final String happenedOn;
  final String? rawText;
  final List<String> warnings;

  bool get isNewPerson => personId == null;
  bool get lent => direction == 'lent';

  @override
  String get type => 'loan';

  @override
  String get summary =>
      '${lent ? 'Lent' : 'Borrowed'} ${formatINR(amountPaise)} ${lent ? 'to' : 'from'} $personName';

  LoanProposal copyWith({
    int? amountPaise,
    String? personName,
    int? personId,
    bool clearPersonId = false,
    String? note,
    String? paymentMethod,
    bool clearPayment = false,
    String? happenedOn,
    String? direction,
  }) =>
      LoanProposal(
        direction: direction ?? this.direction,
        personName: personName ?? this.personName,
        personId: clearPersonId ? null : (personId ?? this.personId),
        amountPaise: amountPaise ?? this.amountPaise,
        note: note ?? this.note,
        paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
        happenedOn: happenedOn ?? this.happenedOn,
        rawText: rawText,
        warnings: warnings,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'direction': direction,
        'personName': personName,
        'personId': personId,
        'amountPaise': amountPaise,
        'note': note,
        'paymentMethod': paymentMethod,
        'happenedOn': happenedOn,
        'rawText': rawText,
        'warnings': warnings,
      };

  factory LoanProposal.fromJson(Map<String, dynamic> j) => LoanProposal(
        direction: j['direction'] as String,
        personName: j['personName'] as String,
        personId: j['personId'] as int?,
        amountPaise: j['amountPaise'] as int,
        note: j['note'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        happenedOn: j['happenedOn'] as String,
        rawText: j['rawText'] as String?,
        warnings: (j['warnings'] as List?)?.cast<String>() ?? const [],
      );
}

class RepaymentProposal extends Proposal {
  const RepaymentProposal({
    required this.loanId,
    required this.personName,
    required this.direction,
    required this.amountPaise,
    required this.paidOn,
    required this.outstandingBeforePaise,
    this.note,
    this.rawText,
  });

  final int loanId;
  final String personName;
  final String direction;
  final int amountPaise;
  final String paidOn;
  final int outstandingBeforePaise;
  final String? note;
  final String? rawText;

  int get outstandingAfterPaise => outstandingBeforePaise - amountPaise;
  bool get lent => direction == 'lent';

  @override
  String get type => 'repayment';

  @override
  String get summary => lent
      ? '$personName paid back ${formatINR(amountPaise)}'
      : 'Paid back $personName ${formatINR(amountPaise)}';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'loanId': loanId,
        'personName': personName,
        'direction': direction,
        'amountPaise': amountPaise,
        'paidOn': paidOn,
        'outstandingBeforePaise': outstandingBeforePaise,
        'note': note,
        'rawText': rawText,
      };

  factory RepaymentProposal.fromJson(Map<String, dynamic> j) => RepaymentProposal(
        loanId: j['loanId'] as int,
        personName: j['personName'] as String,
        direction: j['direction'] as String,
        amountPaise: j['amountPaise'] as int,
        paidOn: j['paidOn'] as String,
        outstandingBeforePaise: j['outstandingBeforePaise'] as int,
        note: j['note'] as String?,
        rawText: j['rawText'] as String?,
      );
}

class PickItem {
  const PickItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.amountPaise,
  });
  final int id;
  final String title;
  final String subtitle;
  final int? amountPaise;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amountPaise': amountPaise,
      };

  factory PickItem.fromJson(Map<String, dynamic> j) => PickItem(
        id: j['id'] as int,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        amountPaise: j['amountPaise'] as int?,
      );
}

/// Shown when the request matched more than one thing.
class PickProposal extends Proposal {
  const PickProposal({
    required this.kind,
    required this.then,
    required this.items,
    required this.followUp,
  });

  /// What is being picked: 'expense', 'loan' or 'person'.
  final String kind;

  /// What happens next: 'update', 'delete', 'repay' or 'loan'.
  final String then;
  final List<PickItem> items;

  /// The tool arguments to apply to whichever item is chosen.
  final Map<String, dynamic> followUp;

  @override
  String get type => 'pick';

  @override
  String get summary => 'Asked which ${kind == 'person' ? 'person' : kind} was meant';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'kind': kind,
        'then': then,
        'items': items.map((e) => e.toJson()).toList(),
        'followUp': followUp,
      };

  factory PickProposal.fromJson(Map<String, dynamic> j) => PickProposal(
        kind: j['kind'] as String,
        then: j['then'] as String,
        items: (j['items'] as List)
            .map((e) => PickItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        followUp: Map<String, dynamic>.from(j['followUp'] as Map),
      );
}
