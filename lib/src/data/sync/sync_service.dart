import '../local/hive_record_store.dart';
import '../models/record.dart';
import '../remote/sync_api.dart';

class SyncResult {
  final int pullCount;
  final int pushUpsertCount;
  final int pushDeleteCount;
  final int conflicts;
  final int finalServerCount;

  SyncResult({
    required this.pullCount,
    required this.pushUpsertCount,
    required this.pushDeleteCount,
    required this.conflicts,
    required this.finalServerCount,
  });
}

class SyncService {
  SyncService({required this.localStore, required this.api});
  final HiveRecordStore localStore;
  final MockSyncApi api;

  /// 削除優先の2-way同期:
  /// 1) 差分計算
  /// 2) pushDeletes（サーバ削除） -> pullUpserts -> pushUpserts
  Future<SyncResult> sync() async {
    // 現在の状態を取得
    final localList = await localStore.getAll();
    final serverList = await api.fetchAll();

    final local = {for (final r in localList) r.id: r};
    final remote = {for (final r in serverList) r.id: r};

    final toPushUpserts = <Record>[];  // local -> server (add/update)
    final toPushDeletes = <String>[];  // local が削除している -> server から削除
    final toPullUpserts = <Record>[];  // server -> local (add/update)
    int conflicts = 0;

    // local -> server の upsert
    for (final id in local.keys) {
      final l = local[id]!;
      final r = remote[id];
      if (r == null) {
        toPushUpserts.add(l);
      } else if (l.updatedAt.isAfter(r.updatedAt)) {
        toPushUpserts.add(l);
      } else if (r.updatedAt.isAfter(l.updatedAt)) {
        // 後でpull対象
      } else if ((l.title != r.title) || ((l.note ?? '') != (r.note ?? ''))) {
        // 同一時刻で内容だけ違うケース
        conflicts++;
      }
    }

    // local には無いが server にはある -> server から削除したい
    for (final id in remote.keys) {
      if (!local.containsKey(id)) {
        toPushDeletes.add(id);
      }
    }

    // server -> local の upsert（ただし削除予定IDは除外して復活を防止）
    for (final id in remote.keys) {
      if (toPushDeletes.contains(id)) continue; // ★削除優先
      final r = remote[id]!;
      final l = local[id];
      if (l == null) {
        toPullUpserts.add(r);
      } else if (r.updatedAt.isAfter(l.updatedAt)) {
        toPullUpserts.add(r);
      }
    }

    // 適用順序：削除 -> pull -> upsert
    if (toPushDeletes.isNotEmpty) {
      await api.deleteIds(toPushDeletes);
    }
    if (toPullUpserts.isNotEmpty) {
      await localStore.putAll(toPullUpserts);
    }
    if (toPushUpserts.isNotEmpty) {
      await api.upsertAll(toPushUpserts);
    }

    final finalCount = (await api.fetchAll()).length;

    return SyncResult(
      pullCount: toPullUpserts.length,
      pushUpsertCount: toPushUpserts.length,
      pushDeleteCount: toPushDeletes.length,
      conflicts: conflicts,
      finalServerCount: finalCount,
    );
  }
}
