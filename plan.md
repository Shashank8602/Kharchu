# Kharchu: Implementation Plan (v1)

**Kharchu** (ಖರ್ಚು, Kannada for "expense") is a personal expense tracker you talk to.

Status: **Draft v2 for review.** No code yet. Section 13 lists the decisions still open.

Mockups: https://claude.ai/artifact/TTx9SLx7xsKiV5VK8QewUs
- Row 1: chat screens. Row 2: the other screens. Row 3: dark theme.
- Each screen has a Dark switch under Tweaks.
- In Play mode, the bottom nav and the Expenses/Lending switch work.

### Changes since v1
| # | Your request | Where it's handled |
|---|---|---|
| 1 | App name | **Kharchu** |
| 2 | Always reply in English | §6.5 (system prompt) |
| 3 | Use screen space well | §8 (Dashboard now fills the screen with charts and lending tiles) |
| 4 | Clean, uncluttered screens | §8.0 UI rules; helper text removed from the mockups |
| 5 | Groq only, for both chat and voice | §5 |
| 6 | Settings inside a Profile screen | §8.6 (the Settings tab is now Profile) |
| 7 | Subtle colored dark theme | §9 |
| 8 | Chat getting messy over time | §7 (fresh chat each day, collapsed cards, History, 30-day purge) |
| 9 | Lent and borrowed money | §4 (people, loans, repayments), §6, §8.4 |
| 10 | Backup file you can save to Google Drive | §8.7 |
| Q1 | Agent framework? | §6.0 (a custom Dart loop, not LangGraph) |
| Q2 | Which models? | §5.1 (`openai/gpt-oss-120b` + `whisper-large-v3`) |

---

## 1. Scope (v1)

| Area | Decision |
|---|---|
| Platform | Flutter. Android first; the code stays iOS-compatible. |
| Users | Single user, no login, no backend server. |
| Storage | Local SQLite. A backup file is saved manually, for example to Google Drive. |
| AI | **Groq only**: `openai/gpt-oss-120b` for chat, `whisper-large-v3` for voice. |
| Input languages | English and Kannada, typed or spoken. |
| Reply language | **Always English.** |
| Writes | Every add, edit, delete, budget, loan or repayment shows a **confirm card** first. |
| Entries per message | One. |
| Expense fields | amount, date, category, item, location, payment method, original text. |
| Lending | Lent and borrowed money is tracked per person, with partial repayments. It is **not counted** in spending or budgets. |
| Budget alerts | In the chat, at 80% and 100%. |
| Chat tidiness | Fresh chat each day; saved cards collapse; History screen; chat text deleted after 30 days. Entries are never deleted by this. |
| Theme | System / Light / Dark. The dark theme has a subtle teal tint. |
| Tabs | Chat · Dashboard · Transactions (Expenses / Lending) · Budgets · Profile |

**Deferred to later:** income tracking · several entries from one message · phone notifications · receipt OCR · reading bank SMS · cloud sync · iOS release.

---

## 2. Tech stack

Install with `flutter pub add <name>` to get the latest stable versions. Commit `pubspec.lock`.

| Concern | Package |
|---|---|
| State | `flutter_riverpod` |
| Routing | `go_router` (`StatefulShellRoute` for the 5 tabs) |
| Database | `drift`, `drift_flutter` (dev: `drift_dev`, `build_runner`) |
| HTTP | `dio` |
| Secret storage | `flutter_secure_storage` (Groq key) |
| Preferences | `shared_preferences` (theme, model ids, last backup date) |
| Voice | `record`, `permission_handler` |
| Charts | `fl_chart` |
| Formatting | `intl` (`en_IN` grouping: ₹1,00,000) |
| Files | `file_picker` (Save-to and Open dialogs), `share_plus`, `path_provider`, `csv` |
| Fonts | `google_fonts` (Sora, Plus Jakarta Sans, Noto Sans Kannada) |
| IDs | `uuid` |
| Tests | `flutter_test`, `mocktail` |

Minimum Android version: API 24.

---

## 3. Project structure

```
(project root: the Flutter app lives directly here, no sub-folder)
├─ lib/
│  ├─ main.dart  ·  app.dart (router + ThemeMode)
│  ├─ core/        theme.dart (light + dark tokens), money.dart, dates.dart, result.dart
│  ├─ data/
│  │  ├─ db/       app_database.dart, tables.dart, daos/ (expense, category, budget, people, loan, chat)
│  │  └─ repositories/
│  ├─ services/
│  │  ├─ groq/     groq_client.dart, groq_errors.dart, rate_limiter.dart
│  │  ├─ agent/    agent_service.dart, tool_schemas.dart, tool_executor.dart,
│  │  │            query_engine.dart, system_prompt.dart, proposals.dart
│  │  ├─ budget_alerts.dart · voice_service.dart · chat_retention.dart
│  │  └─ backup_service.dart · export_service.dart
│  └─ features/
│     ├─ chat/          chat_screen, history_screen, widgets/(bubbles, saved_chip, confirm_cards/*)
│     ├─ dashboard/
│     ├─ transactions/  expenses_tab, lending_tab, person_detail_screen, expense_form_sheet
│     ├─ budgets/
│     └─ profile/       profile_screen, categories_screen, export_screen
├─ test/  unit/ · widget/ · agent_eval/
└─ plan.md
```

---

## 4. Data model (Drift / SQLite)

Money is stored as **integer paise**. Dates are `TEXT 'YYYY-MM-DD'` in IST. Every table has `created_at` and `updated_at`.

**`categories`**: id, name (UNIQUE, NOCASE), color (light), color_dark, icon, is_default, is_archived.
Seeded with 10: Food & Dining, Groceries, Transport, Shopping, Bills & Utilities, Rent & Housing, Health, Entertainment, Travel, Other.

**`expenses`**: id, amount_paise (>0), category_id, item, location?, payment_method? (`cash|upi|card|netbanking|other`), spent_on, raw_text?, source (`chat|voice|manual`), deleted_at? (soft delete for Undo).
Indexes: `(spent_on)`, `(category_id, spent_on)`.

**`budgets`**: id, category_id? (UNIQUE; NULL means overall), monthly_limit_paise.

**`people`**: id, name, name_key (lower-case, trimmed, UNIQUE). Created automatically on the first loan with that person.

**`loans`**: one row per lending event.
| column | notes |
|---|---|
| id | |
| person_id | FK → people |
| direction | `lent` (they owe you) or `borrowed` (you owe them) |
| principal_paise | > 0 |
| note | e.g. "Goa trip" |
| payment_method? | |
| happened_on | date |
| raw_text? | |
| deleted_at? | |

**`loan_repayments`**: id, loan_id, amount_paise, paid_on, raw_text?.
- Outstanding = principal − sum(repayments).
- A loan is **settled** when outstanding = 0. This is derived, not stored.
- A repayment must not exceed the outstanding amount; the card shows an error if it would.

**`chat_messages`**: id (uuid), day (`YYYY-MM-DD`), role (`user|assistant|card|notice`), text?, card_type?, card_payload (JSON)?, card_status (`pending|confirmed|cancelled|expired`)?, entity_ref? (e.g. `expense:42`, `loan:7`).

**Lending is kept out of spending:** expense queries, dashboard totals and budgets read only the `expenses` table. Lending reads only `loans` and `loan_repayments`.

---

## 5. Groq (the only AI provider)

### 5.1 Models
| Purpose | Model | Why |
|---|---|---|
| Chat agent (understanding + tool calls + answers) | **`openai/gpt-oss-120b`** | Groq's recommended replacement after `llama-3.3-70b-versatile` was shut down on 16 Aug 2026. Supports tool use and JSON mode. Its 200K tokens/day matches your quota. |
| Fallback chat model | `openai/gpt-oss-20b` | Used automatically only when 120b returns 429 (rate limited). It has its own separate quota. |
| Voice → text | **`whisper-large-v3`** | Better than `-turbo` on non-English speech. Kannada accuracy matters more here than speed. |

Published Developer-plan limits (check your own under Groq console → Settings → Limits):
- `gpt-oss-120b` / `gpt-oss-20b`: 30 requests/min, 1K requests/day, 8K tokens/min, 200K tokens/day each.
- `whisper-large-v3`: 20 requests/min, 2K requests/day, 7,200 audio-seconds/hour, 28,800 audio-seconds/day.

Model ids are **editable in Profile → Groq**, so a future Groq retirement doesn't need an app update.

### 5.2 Calls
- Base URL `https://api.groq.com/openai/v1`, header `Authorization: Bearer <key>`.
- **Chat:** `POST /chat/completions`
  ```json
  { "model": "openai/gpt-oss-120b", "temperature": 0.1, "reasoning_effort": "low",
    "messages": [...], "tools": [...], "tool_choice": "auto", "max_completion_tokens": 700 }
  ```
  - gpt-oss is a reasoning model. `reasoning_effort: "low"` keeps the hidden thinking tokens small. Confirm the parameter name against Groq's reasoning docs while building Phase 2.
  - gpt-oss models don't do *parallel* tool calls, so the loop in §6 calls one tool per step.
- **Voice:** `POST /audio/transcriptions` (multipart)
  - `file`: m4a, 16 kHz mono, at most 60 s
  - `model`: `whisper-large-v3`
  - `response_format`: `json`
  - `temperature`: `0`
  - `prompt`: "Expense or lending note in English or Kannada. Rupees, UPI, GPay, PhonePe, lent, borrowed, Bengaluru."
  - `language`: omitted (auto-detect), or set from Profile.
- **Key test:** `GET /models`.

### 5.3 Token budget (200K/day ≈ 100+ messages/day)
- System prompt ≤ 900 tokens.
- Only **today's** last 6 turns are sent. Confirmed cards go in as one-liners: `[saved expense ₹1000 Chats]`.
- Categories are sent as names only; people as the 15 most recent names.
- Client-side `rate_limiter.dart` tracks requests per minute and tokens per minute (from the `x-ratelimit-*` response headers), and waits briefly instead of hitting a 429 when possible.

### 5.4 Errors (shown in chat, no technical words)
| Case | Message | Action |
|---|---|---|
| No key | "Add your Groq key to start." | button to Profile |
| 401 | "Groq rejected the key." | button to Profile |
| 429 (both models) | "Busy right now. Try again in Ns." | Retry |
| Offline / 5xx / timeout | "Couldn't reach Groq." | Retry (your message is kept) |
| Bad tool arguments | retried once silently with the validation error → otherwise "Couldn't understand that, try rephrasing." | |

---

## 6. The agent

### 6.0 Framework: why not LangGraph
**There is no agent framework. It's a small tool-calling loop in Dart (about 300 lines) that runs inside the app.**
- LangGraph is a Python/JS library. Using it would mean running a backend server, which conflicts with the app being personal and on-device only.
- The flow here is short and fixed: understand → maybe look something up → propose a card. That's at most 4 steps, which doesn't need graph orchestration.
- A hand-written loop is easy to debug, and the LLM can never touch the database directly.

If a server is ever added (sync, multi-device), the same tool definitions can move to LangGraph unchanged.

### 6.1 Rules
- The LLM never writes SQL and never writes to the database.
- **Read tools** run immediately.
- **Propose tools** end the turn and show a card.
- Data changes only when you tap the card.

### 6.2 Loop
```
handle(text, source):
  store user message (day = today)
  msgs = [systemPrompt(today, categories, recentPeople, last5Expenses)] + today's last 6 turns + text
  for step in 1..4:
      r = groq.chat(msgs, tools)            // 120b; on 429 → 20b
      if r.toolCall:
          args = validate(r.toolCall)       // on error: append {"error": "..."} and continue
          if read tool:   append tool result, continue
          if propose tool: build proposal → save card → return
      else: save assistant text → return
  "Sorry, I got stuck. Try rephrasing."
```

### 6.3 Tools

**Read**
1. `find_expenses {text?, category?, date_from?, date_to?, amount_rupees?, latest_only?, limit≤5}`
   - Searches **all** expenses, of any age, not the chat history. `text` matches item, location **and** the saved original message (`raw_text`), using SQLite FTS5 so word order and partial words still match.
   - Results are ranked by closeness to the requested date, then by text match. The top 5 are returned.
   - So "change last Sunday's dinner at Meghana's to 1450" works even after that day's chat has been deleted.
2. `find_loans {person?, direction?, open_only?}` returns `[{loan_id, person, direction, principal, outstanding, note, happened_on}]`.
3. `query_spending {metric, date_from, date_to, category?, payment_method?, location?, limit?}`
   - `metric` is one of: `total | by_category | top_categories | by_day | by_payment_method | by_location | count | list | budget_status`
4. `query_lending {metric: "balances" | "person_history", person?}`

**Propose (each shows a card)**

5. `propose_add_expense {amount_rupees, item, category, is_new_category?, location?, payment_method?, spent_on}`
6. `propose_update_expense {expense_id, changes{...}}`: card shows before → after (mockup 3).
7. `propose_delete_expense {expense_id}`: red card; Undo for 5 s afterwards.
8. `propose_set_budget {category|null, monthly_limit_rupees}`
9. `propose_loan {direction: "lent"|"borrowed", person, amount_rupees, note?, payment_method?, happened_on}`
   - Card: "You lent" (blue) or "You borrowed" (purple) pill, person avatar, amount (mockup 2).
   - A person not seen before is created when you tap Save. A name close to an existing one ("rahul" vs "Rahul") is matched to that person.
10. `propose_repayment {loan_id, amount_rupees, paid_on}`
    - For "Rahul returned 1000" or "paid Priya back 500".
    - The model calls `find_loans` first. If the person has several open loans, the oldest open loan is used. *(Decision D8)*
    - Card shows the outstanding balance before → after.
11. `ask_user_to_pick {kind: "expense"|"loan", ids[], then: "update"|"delete"|"repay", changes?}`: when more than one match is found.

### 6.4 Validation (Dart, before any card)
- Amount > 0 and < ₹10,00,000. Above ₹1,00,000, show a warning chip.
- Dates must parse. A future date is clamped to today and highlighted.
- The category must exist (case-insensitive, plus a fuzzy alias map such as "food" → Food & Dining), unless `is_new_category`.
- The id must exist and not be deleted.
- A repayment must be ≤ outstanding.
- A missing payment method shows **Cash / UPI / Card** chips right on the card (mockup 1), so you don't need to open the Edit form for it.

### 6.5 System prompt (draft)
```
You are Kharchu, an expense assistant in a personal Indian expense app.
Today is {{today}} ({{weekday}}), Asia/Kolkata. Currency is INR.
Categories: {{categories}}
Payment methods: cash, upi, card, netbanking, other (GPay/PhonePe/Paytm = upi)
Known people: {{recent_people}}
Recent expenses: {{last5_compact}}

The user may write in English or Kannada (Kannada script or romanised).
ALWAYS reply in short, plain English, whatever language the user used.

Rules:
- One entry per message. If several are mentioned, handle the first and say only one is supported.
- Spending → propose_add_expense. Never say something is saved; the user confirms a card.
- "lent/gave X to <person>" → propose_loan(direction=lent). "borrowed/took X from <person>" → propose_loan(direction=borrowed).
  Lending is NOT an expense.
- "<person> returned/paid back X" or "I returned X to <person>" → find_loans, then propose_repayment.
- Resolve relative dates (yesterday, last Sunday, ನಿನ್ನೆ, ಮೊನ್ನೆ) to ISO dates. No date = today.
- Amounts: 1k=1000, 2.5k, Rs, ₹, rupees, Kannada number words and Kannada digits.
- Pick the closest category. Only if none fits, set is_new_category with a short general name.
- item: short, English, Title Case ("Chats", "Petrol").
- Never guess location or payment method; leave null.
- Edits/deletes: find_expenses first (it searches all history), then propose_update/propose_delete, or ask_user_to_pick.
- Questions: query_spending / query_lending, then answer in 1–2 sentences using only returned numbers.
- Off-topic: say briefly you only help with expenses, budgets and lending.
```

### 6.6 Budget alerts
- After any confirmed expense add, update or delete, compare this month's category spend and overall spend before and after the change.
- When a budget crosses 80% or 100% **upward**, add one `notice` to the chat. It is amber at 80% and red at 100%.
- Loans never trigger alerts.

---

## 7. Keeping the chat clean (one chat, no clutter)

1. **Fresh each day.** The Chat tab shows only today's messages (`chat_messages.day = today`). At the first open after midnight, the screen starts empty.
2. **Collapse on completion.** A confirmed card becomes a one-line chip ("✓ ₹240 Auto to MG Road · Transport"). A cancelled card disappears. Answers stay as short bubbles.
3. **History.** The clock icon in the Chat header opens the History screen (mockup 4).
   - Past days are listed newest first, as "3 saved · 1 asked".
   - Tapping a day expands its lines. It is read-only.
4. **30-day purge.**
   - `chat_retention.dart` runs on app start and deletes `chat_messages` where `day < today − 30`.
   - Expenses, loans and budgets are **never** touched, so you can still edit a 3-month-old expense from chat. The agent searches the data tables, not the chat.
5. **Clear chat history** in Profile wipes all chat text immediately (with a confirm dialog).

---

## 8. Screens

### 8.0 UI rules (applies everywhere)
- No helper or tip text inside screens. Hints live only in the chat input placeholder ("What did you spend?").
- One primary action per card. Numbers big (Sora), labels small.
- Cards fill the width. Content is laid out so a typical phone screen has no large empty areas. The chat stacks messages from the bottom up.
- Every status is shown with color *and* a word (Over / Near limit / On track; owes you / you owe).
- Tap targets ≥ 44 px. Tabular figures for amounts.

### 8.1 Chat (mockups 1–3) and History (mockup 4)
- **Header:** "Kharchu" wordmark + History icon.
- **Body:** reverse `ListView` of today's messages. Contents:
  - `SavedChip`
  - `UserBubble`, `AssistantBubble`
  - `BudgetNotice`
  - confirm cards: `AddExpenseCard`, `UpdateCard`, `DeleteCard`, `LoanCard`, `RepaymentCard`, `BudgetCard`, `PickCard`, `NewCategoryCard`
- **Add card:**
  - Large amount; category chip.
  - Line: "item · location · date".
  - Payment chips appear when the payment method is missing.
  - Buttons: Edit (opens the form sheet) / Save.
- **Composer:**
  - Text field and a large mic button. The mic swaps to a send arrow when you've typed something.
  - **Recording state** (mockup 3): ✕ cancel, red pill with timer and live amplitude bars, ■ stop.
  - Stop → "Transcribing…" → the transcript is sent automatically *(D6)*.
  - Recording stops automatically at 60 s.

### 8.2 Dashboard (mockup 5)
1. Month title with ‹ › arrows.
2. **Summary:** big spent amount / budget, a progress bar (green < 80%, amber 80–99%, red ≥ 100%), "₹ left · N days", and an "<Category> over" flag.
3. **By category:** 150 px donut (top 5 + Others) beside the legend with amounts.
4. **Daily:** 150 px bar chart for the month so far, today's bar highlighted; y-axis ₹0 / mid / max (rounded).
5. **Lending tiles:** "You'll get ₹X · N people" (blue) and "You owe ₹Y · N person" (purple). Tapping opens Transactions → Lending.

All of it comes from Drift `watch()` streams, so it updates live.

### 8.3 Transactions → Expenses (mockup 6)
- Segmented control **Expenses | Lending** at the top.
- Search field and a filter icon. The filter sheet has category, payment method and date range.
- Day-grouped list: category avatar, item, "location · payment", amount; day total in the group header.
- Tap → edit sheet. Swipe → delete with Undo. These manual edits don't need a card, because the form is the confirmation.

### 8.4 Transactions → Lending (mockup 7)
- Two tiles: **You'll get** (sum of outstanding *lent*) and **You owe** (sum of outstanding *borrowed*).
- **Open:** one row per person with an open balance.
  - Each row shows avatar, name, "latest note · date", amount, and "owes you" / "you owe".
  - A repayment progress bar appears when there has been a partial repayment ("₹1,000 of ₹2,500 back").
- **Settled:** a muted list of people whose balance is 0, with the last settled date.
- Tapping a person opens `PersonDetailScreen`: a timeline of loans and repayments plus a **Record repayment** button (form sheet).
- A person can have both lent and borrowed loans. The row shows the **net** balance and its direction.

### 8.5 Budgets (mockup 8)
- A "+" icon in the header opens the budget form.
- Overall card: big amount / limit, progress bar, days left.
- Category rows sorted by status (Over → Near limit → On track), each with a pill, a bar, and "₹ of ₹" / "₹ left" or "₹ over".
- Dashed "+ Category" chips for categories that have spending but no budget.

### 8.6 Profile (mockup 9): settings live here
- Avatar initial + name (editable) + "Using Kharchu since <month>". No stats row.
- **Theme:** System / Light / Dark segmented control (saved in `shared_preferences`, applied through `MaterialApp.themeMode`).
- List rows:
  - **Groq API key** → screen with an obscured key field, Test, and model ids (chat, fallback, voice) plus voice language.
  - **Categories** → `CategoriesScreen` (add, rename, recolor, archive).
  - **Back up to file** (§8.7)
  - **Restore from file** (§8.7)
  - **Export CSV** → choose a month range, then share or save. The file has a UTF-8 BOM so Excel shows Kannada correctly.
  - **Clear chat history** (red, confirm dialog).

### 8.7 Backup & restore (for moving to a new phone)

**Format.** One JSON file named `kharchu-backup-YYYYMMDD-HHmm.json`. JSON rather than raw SQLite, because it's readable, survives app schema upgrades, and is small.
```json
{ "app": "kharchu", "backup_version": 1, "schema_version": 1,
  "exported_at": "2026-11-03T18:20:00+05:30",
  "counts": {"expenses": 312, "loans": 6, ...},
  "categories": [...], "expenses": [...], "budgets": [...],
  "people": [...], "loans": [...], "loan_repayments": [...] }
```
Chat history is **not** included *(D9)*. The Groq key is **never** included.

**Back up to file.**
1. Build the JSON in a background isolate.
2. Call `FilePicker.platform.saveFile(fileName: ..., bytes: ...)`. This opens Android's system **"Save to"** dialog, where you can choose **Google Drive** directly (if the Drive app is installed), Downloads, or any folder.
3. On success, store `last_backup_at`.

Profile shows "Last: <date>" and turns amber when the last backup is more than 30 days old.

**Restore from file.**
1. `FilePicker.platform.pickFiles(type: custom, allowedExtensions: ['json'])`. Drive files show up in the picker.
2. Parse the file and validate `app`, `backup_version`, required keys and data types.
3. Show a summary dialog: "312 expenses, 6 loans, 8 budgets from 3 Nov 2026. This replaces all current data." with Cancel / Restore.
4. In a single DB transaction: delete all rows → insert everything with the original ids → commit. On any error, roll back and show the error.

A unit test checks the round trip: back up → wipe → restore gives identical data.

---

## 9. Theme tokens

| Token | Light | Dark (teal-tinted) |
|---|---|---|
| bg | `#F2F4F3` | `#0E1513` |
| surface | `#FFFFFF` | `#16201D` |
| field | `#F7F9F8` | `#1C2925` |
| ink | `#15201B` | `#E4ECE8` |
| muted | `#56635C` | `#9AABA3` |
| line | `#DDE3E0` | `#26342F` |
| accent / onAccent | `#0F6B5C` / `#FFFFFF` | `#3FAE95` / `#06231C` |
| soft / softInk | `#E3F1EC` / `#0A4F44` | `#183A32` / `#8FDCC8` |
| warn / warnBg / warnInk | `#C2620F` / `#FFF4E8` / `#6E3A0A` | `#E08A3C` / `#33240F` / `#F2C08A` |
| danger / dangerBg / dangerInk | `#B42318` / `#FCEDEC` / `#8A1C12` | `#E5604F` / `#3A1A17` / `#F4A49A` |
| lent bg / ink | `#EAF0FA` / `#24477F` | `#1B2840` / `#A8C2EE` |
| borrowed bg / ink | `#F3ECF8` / `#5B3480` | `#2A1F38` / `#CDB2E8` |
| chart series | `#0F6B5C #D9822B #3A66C4 #7FB8A6 #8A5BB0 #A9B3AE` | `#3FAE95 #E08A3C #6E95E6 #8CC9B6 #A983CC #5F6E68` |

Fonts: Sora (headings, amounts), Plus Jakarta Sans (body), Noto Sans Kannada (fallback for Kannada glyphs).

Build both palettes as a `ThemeExtension<KharchuColors>` so widgets read `context.kc.lentBg` and similar, with no hard-coded colors.

---

## 10. Build phases (each ends runnable)

| Phase | Work | Done when |
|---|---|---|
| 0. Setup (½ d) | Flutter + Android Studio + emulator; `flutter create --org <your.domain> --project-name kharchu --platforms android,ios .` (run in the project root); packages; lints; `git init`. | Default app runs. |
| 1. Data (2 d) | Tables from §4, seed, DAOs, money/date helpers, in-memory DB tests. | Unit tests pass. |
| 2. Shell + theme + Groq (1 d) | 5-tab shell, light/dark `ThemeExtension`, Profile → Groq key + Test, `GroqClient` + rate limiter + error mapping. | Key test shows Connected; theme switch works. |
| 3. Add expense via chat (3 d) | Tools 1, 5; agent loop; add and new-category cards; payment chips; saved chips. | Mockup-1 flow works; a Kannada sentence gets an English reply and a correct card. |
| 4. Edit/delete (1–2 d) | Tools 6, 7, 11; Undo. | "change last Sunday's dinner to 1450" works on an expense older than today's chat. |
| 5. Questions (1–2 d) | `query_engine` + tests; tool 3. | Answers match the dashboard numbers. |
| 6. Lending (2–3 d) | Tables, tools 2, 4, 9, 10; loan and repayment cards; Lending tab; person detail. | Lend → partial repay → full repay moves the person from Open to Settled; spending totals unchanged. |
| 7. Budgets + alerts (1 d) | Tool 8, alerts, Budgets screen. | Crossing 80% and 100% each show one notice. |
| 8. Voice (1–2 d) | `record` + Whisper; recording UI. | Spoken English and Kannada both produce correct cards. |
| 9. Dashboard + Transactions (3 d) | §8.2, §8.3. | Matches mockups with live data. |
| 10. Chat hygiene (1 d) | Day-scoped chat, History screen, 30-day purge, Clear history. | Changing the device date to tomorrow starts a fresh chat; History shows yesterday. |
| 11. Profile + backup (2 d) | §8.6, §8.7, CSV export. | Back up to Drive → reinstall the app → restore from Drive brings back everything. |
| 12. Hardening + release (2 d) | Agent eval ≥ 90% field accuracy, empty states, offline, release keystore, `flutter build apk --release`. | APK installed on your phone. |

**Rough total: 4–5 weeks part-time.**

---

## 11. Testing
- **Unit:** money/date helpers, every query metric, lending balance math (partial, over-repay rejected, net per person), budget crossings, backup round trip, 30-day purge leaves entries alone.
- **Widget:** each confirm-card variant; theme switch; History expand.
- **Agent eval** (`test/agent_eval/utterances.json`): about 50 cases (30 English, 20 Kannada) with a fixed "today". The runner prints per-field accuracy and checks that the **reply is in English**. Sample cases:
  - "I spent Rs.1000 to eat chats in Bengaluru" → add 1000, Food & Dining, Chats, Bengaluru
  - "ನಿನ್ನೆ ಪೆಟ್ರೋಲ್‌ಗೆ 500 ರೂ ಕೊಟ್ಟೆ" → add 500, Transport, yesterday
  - "lent 2000 to Rahul for his Goa trip on gpay" → loan lent 2000, Rahul, "Goa trip", upi
  - "borrowed 1500 from Priya" → loan borrowed 1500, Priya
  - "Rahul returned 1000" → find_loans → repayment 1000
  - "ರಾಹುಲ್‌ಗೆ 500 ಸಾಲ ಕೊಟ್ಟೆ" → loan lent 500, Rahul (English reply)
  - "change last Sunday's dinner at Meghana's to 1450" → find_expenses → update
  - "how much do people owe me?" → query_lending balances
  - "ಈ ತಿಂಗಳು ಊಟಕ್ಕೆ ಎಷ್ಟು ಖರ್ಚಾಯ್ತು?" → query_spending → English answer

---

## 12. Risks
| Risk | Mitigation |
|---|---|
| Groq retires a model (already happened to Llama 3.3) | Model ids editable in Profile; a clear error on model-not-found. |
| Daily token cap | Small prompts; today-only context; automatic fallback to 20b; client rate limiter. |
| Kannada voice accuracy | `whisper-large-v3` (not turbo); vocabulary prompt; the confirm card is always shown. |
| Person name ambiguity ("Rahul" vs "Rahul K") | Exact-then-fuzzy match; when unsure, a pick card. |
| Phone lost or changed | Manual backup to Drive with a 30-day amber reminder. |
| Key leakage | Secure storage only; never in backups or logs. |

---

## 13. Decisions still open (defaults in bold)

| # | Question | Default |
|---|---|---|
| D1 | Android package id | **`com.<yourname>.kharchu`**: tell me your preferred reverse domain |
| D2 | State management | **Riverpod** |
| D3 | Preset categories | **The 10 in §4** |
| D5 | Future dates | **Not allowed; clamp to today** |
| D6 | Voice: send the transcript automatically, or let you review it first? | **Auto-send** (the card is the review step) |
| D7 | Manual "+ Add" button on Transactions? | **No, chat only** |
| D8 | Repayment when someone has several open loans | **Apply to the oldest loan first** |
| D9 | Include chat history in backups? | **No** (it expires after 30 days anyway) |
| D11 | Overall monthly budget in addition to category budgets? | **Yes** |
| D12 | Any mockup changes? | Comment on the canvas |
