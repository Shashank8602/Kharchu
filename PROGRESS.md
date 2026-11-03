# Kharchu build progress

Status key: ✅ done and tested · 🟡 done, partly verified · ⬜ not started · ⚠️ known gap

| Phase | Status | Notes |
|---|---|---|
| 0. Setup | ✅ | Flutter 3.47.9, project at repo root, packages installed |
| 1. Data layer | ✅ | 7 tables, repositories, 89 unit tests passing, `flutter analyze` clean |
| 2. Shell, theme, Groq client | ⬜ | |
| 3. Agent: add expense | ⬜ | |
| 4. Edit / delete via chat | ⬜ | |
| 5. Questions | ⬜ | |
| 6. Lending via chat + screens | ⬜ | Data layer done in phase 1 |
| 7. Budgets + alerts | ⬜ | |
| 8. Voice | ⬜ | |
| 9. Dashboard + Transactions | ⬜ | |
| 10. Chat hygiene (History, purge) | ⬜ | Purge logic done in phase 1 |
| 11. Profile + backup | ⬜ | |
| 12. Hardening + release | ⬜ | |

## Deviations from plan.md
- **Repositories instead of Drift DAOs.** Same queries, less generated code.
- **Search uses tokenised `LIKE`, not SQLite FTS5.** Every word must match item, location
  or the original message; partial words and any word order work. Fast enough for a
  personal-sized database, and avoids FTS table sync. `%`, `_` and `\` are escaped.
- **Stream helper `watchQuery`** replaces `async*` generators for live data: cancelling an
  `async*` generator parked on `await for` leaks the subscription.

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
