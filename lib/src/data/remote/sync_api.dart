import 'package:hive/hive.dart';
import '../models/record.dart';
import '../../core/hive_init.dart';

/// 擬似クラウドAPI（別Boxをクラウド代わりに）
class MockSyncApi {
  Box<Record>? _server;

  Future<void> init() async {
    _server ??= await Hive.openBox<Record>(HiveInit.serverBox);
  }

  Future<List<Record>> fetchAll() async {
    return _server!.values.toList(growable: false);
  }

  /// 追加/更新（同一IDは上書き）
  Future<void> upsertAll(List<Record> items) async {
    if (items.isEmpty) return;
    await _server!.putAll({for (final r in items) r.id: r});
  }

  /// サーバからIDで削除
  Future<void> deleteIds(List<String> ids) async {
    for (final id in ids) {
      await _server!.delete(id);
    }
  }
}
