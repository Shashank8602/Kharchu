# Kharchu build progress

Status key: ✅ done and tested · 🟡 done, partly verified · ⬜ not started · ⚠️ known gap

| Phase | Status | Notes |
|---|---|---|
| 0. Setup | ✅ | Flutter 3.47.9, project at repo root, packages installed |
| 1. Data layer | ✅ | 7 tables, repositories |
| 2. Shell, theme, Groq client | ✅ | 5 tabs, light/dark, Profile + Groq screens |
| 3. Agent: add expense via chat | ✅ | Loop, 11 tools, validation, confirm cards, Edit sheet, new-category flow |
| 4. Edit / delete via chat | ✅ | Update/delete cards, Undo, pick card, stale-card detection |
| 5. Questions | ✅ | Spending and lending queries with exact figures |
| 6. Lending | ✅ | Chat cards, Lending tab (open/settled, net per person), person screen with repayments |
| 7. Budgets + alerts | ✅ | Chat alerts and the Budgets screen (add, edit, delete, statuses) |
| 8. Voice | 🟡 | Record, 60 s cap, Whisper transcript sent like a typed message, all failure paths tested with a fake microphone. **Not tried with a real microphone or real Kannada speech** |
| 9. Dashboard + Transactions | ✅ | Month navigation, donut, daily bars, search, filters, edit, swipe-delete with Undo |
| 10. Chat hygiene | ✅ | Fresh chat each day, History screen, 30-day purge on startup (entries never purged) |
| 11. Profile: categories, backup, CSV | ✅ | Backup/restore through the system dialog (Drive available), validated restore, CSV with BOM + formula-injection guard, Categories screen |
| 12. Hardening + release | ✅ | Signed APK, README, live AI check, GitHub pre-release |

Tests: 466 passing (+1 opt-in live AI check) (unit, agent, widget). `flutter analyze`: no issues.

## Deviations from plan.md
- **Android manifest**: added `INTERNET` and `RECORD_AUDIO` (Flutter's template only has
  INTERNET in debug builds, so a release APK could not reach Groq). Removed the unused
  `permission_handler` and `share_plus` packages.
- **Bugs found by the widget tests and fixed**: a border-with-radius crash on the expense
  list, amount/category overflow on narrow cards, Apply/Save hidden below the fold in sheets.
- **Loan and repayment cards have Cancel / Save only** (no Edit sheet). To change one,
  cancel it and say it again. Expense cards have the full Edit sheet.
- **Business logic never reads through live streams.** Found while testing: a one-off read
  via `watchAll().first` silently never completed in tests; replaced with plain queries.
- **Repositories instead of Drift DAOs.** Same queries, less generated code.
- **Search uses tokenised `LIKE`, not SQLite FTS5.** Every word must match item, location
  or the original message; partial words and any word order work. Fast enough for a
  personal-sized database, and avoids FTS table sync. `%`, `_` and `\` are escaped.
- **Stream helper `watchQuery`** replaces `async*` generators for live data: cancelling an
  `async*` generator parked on `await for` leaks the subscription.

- **`google_fonts` pinned to 8.2.1, not 9.x.** Flutter 3.47 split Material into a new
  `material_ui` package; google_fonts 9.0.0 builds its `TextTheme` from that package, which
  is a different class from `flutter/material.dart`'s, so the two cannot be combined.
- **Kannada text uses the phone's system font** instead of a bundled Noto Sans Kannada
  (one fewer download). Not checked on a real device.
- **Pasted keys are cleaned** (quotes, spaces, `Bearer `, whole `GROQ_API_KEY=` lines).

## Verified against the live Groq API (2026-11-03)
- Your account lists `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `whisper-large-v3`.
- `reasoning_effort: "low"` is accepted; a tool-call request cost about 260 tokens.
- Tool calls come back as `message.tool_calls[].function.{name,arguments}` (arguments is a
  JSON string). The model wrote the category as "Food", which the alias map resolves.
- `llama-3.3-70b-versatile` was shut down on 2026-08-16 per Groq's deprecations page, and is absent from your model list.

## Edge cases covered by tests so far
Money: floating-point rounding, Indian digit grouping, negatives, sub-rupee amounts.
Dates: impossible dates (Feb 30/31), leap years incl. 2100, IST rollover at 18:30 UTC,
month/year boundaries, 30-day purge boundary.
Expenses: zero/negative amounts rejected, bad category rejected (foreign keys on),
soft delete/restore, SQL-injection-shaped text, LIKE wildcards, date range inclusive,
`nearDate` ranking, soft-deleted rows excluded from every total.
Categories: aliases, ambiguous partial match → null, archived hidden, case-insensitive
duplicates, last active category cannot be archived.
Budgets: one overall budget only, invalid limits rejected.
Lending: over-repayment refused (and leaves no partial row), settled/deleted/missing loans,
net balance with both directions, lending never affects spending totals.
Chat: same-second ordering, 30-day purge keeps expenses/loans/budgets.

## Not verifiable overnight (needs a real phone)
Microphone and Kannada speech, Android "Save to Google Drive" dialog, on-device look.

## Release status
- Release APK is built and signed with a private release key kept outside the repo
  (`%USERPROFILE%\.kharchu-keystore\`). **Back that folder up**; without it a future version
  cannot be installed over this one.
- **Never run on a physical Android phone.** All behaviour was checked by unit tests, widget
  tests (with a fake microphone and fake file dialogs) and a live call to the Groq API.
- Live AI accuracy: see below.

## Live AI check (real Groq API, `openai/gpt-oss-120b`, 2026-11-04)
30 messages: 16 spending (8 English-only variety + 5 Kannada), 5 lending, 3 edit/delete, 4
questions, 1 budget, 1 off-topic. Every field of every result is checked (amount, category,
item, place, payment, date, ids).

- **First run: 28 of 30 correct (93%). Kannada: 7 of 7.** Replies were in English every time.
- The two misses were real bugs in my code, now fixed:
  1. "paid back Priya 500": the model guessed the loan direction when searching and found
     nothing. The prompt now says never to guess it.
  2. "top 3 categories this month": Groq rejected the model's tool call with HTTP 400 and the
     turn ended in an error. The app now tells the model what was wrong and lets it retry.
- After the fixes I re-ran **only those two cases: both passed.** The other 28 were not run
  again after the prompt change, so the figure above is the honest overall number.
- A 30-case sample is a smoke test, not a guarantee. Real phrasing varies more.

## Round 2 changes (2026-11-04, not yet released)
- **Several tasks in one chat message**: the agent runs every tool call of a round and can return
  several cards plus a written answer ("money left" = budget remaining this month). Nothing is
  saved until each card is confirmed, so totals in that same reply exclude the new entry.
- **Manual entry** (works with no Groq key or tokens): Add expense / Add lending buttons on
  Transactions, an add button in the chat bar, and "Add manually" on AI error messages.
- Chat add-expense card now has **Cancel**.
- UI: pill bottom bar and pill toggles, dashboard fits one screen (scrolls only on small
  screens), card borders no longer overdrawn at corners, single-line labels, gradient hero
  cards and tinted tabs/bubbles, "Using Kharchu since" removed from Profile.
- Live AI accuracy not re-measured after the prompt change; a multi-task case was added to
  `test/agent_eval` for the next live run.
