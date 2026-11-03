# Kharchu

**Kharchu** (ಖರ್ಚು, Kannada for "expense") is an expense tracker you talk to. Say what you
spent, in English or Kannada, typed or spoken, and it fills in the entry for you.

> "I spent Rs.1000 to eat chats in Bengaluru"
> → a card with ₹1,000 · Food & Dining · Chats · Bengaluru · Today. You tap **Save**.

Nothing is saved until you tap the card. Your data stays on your phone.

## What it does

- **Chat to add, edit, delete.** "auto 240 cash", "2.5k shoes via card yesterday",
  "change last Sunday's dinner at Meghana's to 1450", "delete the petrol expense".
- **Ask questions.** "How much on food this month?", "Top 3 categories", "Who owes me money?"
  Answers are always in English, whatever language you wrote in.
- **Lending, kept separate from spending.** "Lent 2000 to Rahul for his Goa trip",
  "Rahul returned 1000", "borrowed 1500 from Priya". Per-person balances with partial
  repayments. Lent money never counts as spending.
- **Budgets with in-chat warnings** at 80% and 100%. "Set food budget to 6000".
- **Voice.** Tap the mic, speak, and it is transcribed (Groq Whisper) and sent like a typed
  message. Recordings stop after 60 seconds.
- **Screens:** Chat · Dashboard (month charts) · Transactions (Expenses, Lending) · Budgets ·
  Profile. Light, dark and system themes.
- **Chat stays tidy.** A fresh chat each day, History for earlier days, chat text is deleted
  after 30 days. Your entries are never deleted by this.
- **Backup you can keep.** Save a backup file anywhere, including Google Drive, and restore it
  on a new phone. CSV export for spreadsheets.

## Install

1. Download `kharchu-*.apk` from the [Releases](../../releases) page onto your Android phone.
2. Open it. If Android asks, allow "install unknown apps" for your browser or Files app.
3. Open Kharchu → **Profile → Groq API key**. Paste your key (get a free one at
   <https://console.groq.com/keys>) and tap **Save and test**. You should see "Connected."
4. Go to **Chat** and say what you spent.

The app needs a Groq key because Groq's models do the understanding and the speech
recognition. The key is kept in the phone's secure storage and is never part of a backup.

## Moving to a new phone

1. Old phone: **Profile → Back up to file**, and choose Google Drive (or any folder) in the
   Android save dialog.
2. New phone: install Kharchu, then **Profile → Restore from file** and pick that file.
3. Paste your Groq key again (it is never backed up).

Restoring replaces everything on the phone, and tells you what is in the file first. A damaged
or wrong file is refused and changes nothing.

## Privacy

- Expenses, loans and budgets live in a database on the phone only.
- What is sent to Groq: the text you type, a few recent entries so "change that" works, and
  your voice clips when you use the mic. Nothing else.
- There is no account, no analytics, and no server of ours.

## How the AI part works

There is no agent framework. A small loop (`lib/services/agent/`) sends your message and a list
of 11 actions to Groq's `openai/gpt-oss-120b` (falling back to `gpt-oss-20b` if rate limited),
runs whatever it asks for, and stops when it proposes a change. **The model never touches the
database.** Lookups run immediately; every change becomes a card, and only your tap writes
anything (`lib/services/card_actions.dart`).

## Build from source

Needs Flutter 3.47+ and the Android SDK.

```
flutter pub get
flutter test                      # 460+ tests
flutter build apk --release
```

`android/key.properties` (git-ignored) points at a release keystore. Without it the build falls
back to the debug key, so the project still builds anywhere.

To check the AI against the real Groq API (spends about 100K tokens of quota; needs
`GROQ_API_KEY` in a `.env` file):

```
KHARCHU_EVAL=1 flutter test test/agent_eval/agent_eval_test.dart
```

## Project map

| Path | What is there |
|---|---|
| `lib/data/` | Drift (SQLite) tables, repositories, settings |
| `lib/services/groq/` | The only network code: chat, transcription, rate limiting, error mapping |
| `lib/services/agent/` | Tools, validation, the loop, the spending/lending queries |
| `lib/services/card_actions.dart` | The only place chat writes to the database |
| `lib/features/` | One folder per screen |
| `test/` | Unit, agent, widget tests, and the opt-in live AI check |

See [`plan.md`](plan.md) for the design and [`PROGRESS.md`](PROGRESS.md) for what is verified and
what is not.

## Known limits

- It has not been run on a physical phone yet. Widget tests and a fake microphone stand in for
  one, so voice with a real microphone, Kannada speech accuracy, and Android's Google Drive save
  dialog are untested on a device.
- Free Groq limits apply (about 8K tokens a minute, 200K a day for the main model). If you hit
  them the app says how long to wait, and uses the smaller backup model when it can.
- One entry per message. Splitting "A and B" into two entries is not supported yet.
- Android only so far; the code is iOS-compatible but nothing has been built for iOS.
