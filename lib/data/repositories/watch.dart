import 'dart:async';

import 'package:drift/drift.dart';

/// Re-runs [load] whenever any of [tables] changes and emits the result.
///
/// Built on a StreamController rather than an `async*` generator: cancelling
/// a generator that is parked on `await for` does not complete until the next
/// table update, which leaks the subscription. Here cancel is immediate.
/// If updates arrive faster than [load] finishes, only the newest result is
/// emitted, so a slow older query can never overwrite a newer one.
Stream<T> watchQuery<T>(
  GeneratedDatabase db,
  Set<TableInfo> tables,
  Future<T> Function() load,
) {
  late final StreamController<T> controller;
  StreamSubscription<Set<TableUpdate>>? updates;
  var latest = 0;

  Future<void> emit() async {
    final mine = ++latest;
    try {
      final value = await load();
      if (mine == latest && !controller.isClosed) controller.add(value);
    } catch (e, s) {
      if (mine == latest && !controller.isClosed) controller.addError(e, s);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      emit();
      updates = db
          .tableUpdates(TableUpdateQuery.onAllTables(tables))
          .listen((_) => emit());
    },
    onCancel: () async {
      await updates?.cancel();
      updates = null;
    },
  );
  return controller.stream;
}
