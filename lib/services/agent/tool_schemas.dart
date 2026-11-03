// The only actions the AI can take. Kept terse: this list is sent with every
// request, and Groq's free tier allows ~8K tokens a minute.

const kReadTools = {'find_expenses', 'find_loans', 'query_spending', 'query_lending'};
const kProposeTools = {
  'propose_add_expense',
  'propose_update_expense',
  'propose_delete_expense',
  'propose_set_budget',
  'propose_loan',
  'propose_repayment',
  'ask_user_to_pick',
};

const _s = {'type': 'string'};
const _n = {'type': 'number'};
const _i = {'type': 'integer'};
const _b = {'type': 'boolean'};
const _date = {'type': 'string', 'description': 'YYYY-MM-DD'};
const _pay = {
  'type': 'string',
  'enum': ['cash', 'upi', 'card', 'netbanking', 'other']
};

Map<String, dynamic> _tool(
  String name,
  String description,
  Map<String, dynamic> props, [
  List<String> required = const [],
]) =>
    {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': props,
          'required': required,
        },
      },
    };

final List<Map<String, dynamic>> toolSchemas = [
  _tool(
    'find_expenses',
    'Search ALL saved expenses (any age). Use before editing or deleting.',
    {
      'text': {'type': 'string', 'description': 'words from item or place'},
      'category': _s,
      'date_from': _date,
      'date_to': _date,
      'near_date': {'type': 'string', 'description': 'rank by closeness to this date'},
      'amount_rupees': _n,
      'latest_only': {'type': 'boolean', 'description': 'for "the last expense"'},
      'limit': _i,
    },
  ),
  _tool(
    'find_loans',
    'List lent/borrowed money, with outstanding balance.',
    {
      'person': _s,
      'direction': {
        'type': 'string',
        'enum': ['lent', 'borrowed']
      },
      'open_only': _b,
    },
  ),
  _tool(
    'query_spending',
    'Answer spending questions. Returns exact figures.',
    {
      'metric': {
        'type': 'string',
        'enum': [
          'total',
          'by_category',
          'top_categories',
          'by_day',
          'by_payment_method',
          'by_location',
          'count',
          'list',
          'budget_status'
        ]
      },
      'date_from': _date,
      'date_to': _date,
      'category': _s,
      'limit': _i,
    },
    ['metric', 'date_from', 'date_to'],
  ),
  _tool(
    'query_lending',
    'Who owes whom.',
    {
      'metric': {
        'type': 'string',
        'enum': ['balances', 'person_history']
      },
      'person': _s,
    },
    ['metric'],
  ),
  _tool(
    'propose_add_expense',
    'Record spending. The user confirms on a card.',
    {
      'amount_rupees': _n,
      'item': {'type': 'string', 'description': 'short, English'},
      'category': {'type': 'string', 'description': 'an existing category'},
      'is_new_category': {'type': 'boolean', 'description': 'only if none fit'},
      'location': _s,
      'payment_method': _pay,
      'spent_on': _date,
    },
    ['amount_rupees', 'item', 'category', 'spent_on'],
  ),
  _tool(
    'propose_update_expense',
    'Change a saved expense (get expense_id from find_expenses).',
    {
      'expense_id': _i,
      'amount_rupees': _n,
      'item': _s,
      'category': _s,
      'location': _s,
      'payment_method': _pay,
      'spent_on': _date,
    },
    ['expense_id'],
  ),
  _tool(
    'propose_delete_expense',
    'Delete a saved expense.',
    {'expense_id': _i},
    ['expense_id'],
  ),
  _tool(
    'propose_set_budget',
    'Set a monthly budget. Omit category for the overall budget.',
    {'category': _s, 'monthly_limit_rupees': _n},
    ['monthly_limit_rupees'],
  ),
  _tool(
    'propose_loan',
    'Record money lent to or borrowed from a person. NOT an expense.',
    {
      'direction': {
        'type': 'string',
        'enum': ['lent', 'borrowed']
      },
      'person': _s,
      'amount_rupees': _n,
      'note': _s,
      'payment_method': _pay,
      'happened_on': _date,
    },
    ['direction', 'person', 'amount_rupees', 'happened_on'],
  ),
  _tool(
    'propose_repayment',
    'Record part or all of a loan being paid back (get loan_id from find_loans).',
    {'loan_id': _i, 'amount_rupees': _n, 'paid_on': _date},
    ['loan_id', 'amount_rupees', 'paid_on'],
  ),
  _tool(
    'ask_user_to_pick',
    'When several expenses or loans match, let the user choose.',
    {
      'kind': {
        'type': 'string',
        'enum': ['expense', 'loan']
      },
      'ids': {
        'type': 'array',
        'items': _i,
      },
      'then': {
        'type': 'string',
        'enum': ['update', 'delete', 'repay']
      },
      'amount_rupees': _n,
      'item': _s,
      'category': _s,
      'location': _s,
      'payment_method': _pay,
      'spent_on': _date,
      'paid_on': _date,
    },
    ['kind', 'ids', 'then'],
  ),
];
