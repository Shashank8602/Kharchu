import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/dates.dart';
import '../db/app_database.dart';

class ChatRepository {
  ChatRepository(this.db);
  final AppDatabase db;
  static const _uuid = Uuid();

  /// Messages sharing a second keep insertion order via rowid.
  static final _insertionOrder = CustomExpression<int>('chat_messages.rowid');

  Future<String> add({
    required String day,
    required String role,
    String? body,
    String? cardType,
    String? cardPayload,
    String? cardStatus,
    String? entityRef,
  }) async {
    final id = _uuid.v4();
    await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(
          id: id,
          day: day,
          role: role,
          body: Value(body),
          cardType: Value(cardType),
          cardPayload: Value(cardPayload),
          cardStatus: Value(cardStatus),
          entityRef: Value(entityRef),
        ));
    return id;
  }

  Stream<List<ChatMessage>> watchDay(String day) => (db.select(db.chatMessages)
        ..where((m) => m.day.equals(day))
        ..orderBy([(m) => OrderingTerm.asc(_insertionOrder)]))
      .watch();

  Future<List<ChatMessage>> messagesForDay(String day) =>
      (db.select(db.chatMessages)
            ..where((m) => m.day.equals(day))
            ..orderBy([(m) => OrderingTerm.asc(_insertionOrder)]))
          .get();

  /// The last [limit] messages of [day], oldest first, for the AI's context.
  Future<List<ChatMessage>> recentTurns(String day, int limit) async {
    final rows = await (db.select(db.chatMessages)
          ..where((m) => m.day.equals(day) & m.role.isNotIn(const ['notice']))
          ..orderBy([(m) => OrderingTerm.desc(_insertionOrder)])
          ..limit(limit))
        .get();
    return rows.reversed.toList();
  }

  Future<ChatMessage?> byId(String id) => (db.select(db.chatMessages)
        ..where((m) => m.id.equals(id)))
      .getSingleOrNull();

  Future<void> updateCard(
    String id, {
    String? status,
    String? entityRef,
    String? payload,
  }) =>
      (db.update(db.chatMessages)..where((m) => m.id.equals(id))).write(
        ChatMessagesCompanion(
          cardStatus: status == null ? const Value.absent() : Value(status),
          entityRef: entityRef == null ? const Value.absent() : Value(entityRef),
          cardPayload: payload == null ? const Value.absent() : Value(payload),
        ),
      );

  Future<void> delete(String id) =>
      (db.delete(db.chatMessages)..where((m) => m.id.equals(id))).go();

  /// Days before [today] that have chat, newest first.
  Future<List<String>> pastDays(String today) async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT day FROM chat_messages WHERE day < ? ORDER BY day DESC',
          variables: [Variable.withString(today)],
          readsFrom: {db.chatMessages},
        )
        .get();
    return rows.map((r) => r.read<String>('day')).toList();
  }

  /// Deletes chat text older than [retentionDays] before [today].
  /// Never touches expenses, loans or budgets. Returns rows deleted.
  Future<int> purgeOlderThan(String today, {int retentionDays = 30}) {
    final cutoff = addDays(today, -retentionDays);
    return (db.delete(db.chatMessages)..where((m) => m.day.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<int> clearAll() => db.delete(db.chatMessages).go();
}
