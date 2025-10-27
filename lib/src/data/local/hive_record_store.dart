import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../../core/hive_init.dart';
import '../models/record.dart';

class HiveRecordStore {
  Box<Record>? _box;

  Future<void> open() async {
    _box ??= await Hive.openBox<Record>(HiveInit.recordsBox);
  }

  Future<void> close() async {
    await _box?.close();
  }

  bool get isOpen => _box?.isOpen ?? false;

  Future<List<Record>> getAll() async {
    final items = _box!.values.toList(growable: false);
    items.sortBy((e) => e.updatedAt);
    return items.reversed.toList();
  }

  Future<Record?> getById(String id) async => _box!.get(id);

  Future<void> put(Record r) async => _box!.put(r.id, r);

  Future<void> putAll(Iterable<Record> records) async {
    await _box!.putAll({for (final r in records) r.id: r});
  }

  Future<void> delete(String id) async => _box!.delete(id);

  Future<int> count() async => _box!.length;

  // 検証用: 主キー重複/必須/日付異常を走査
  Future<VerificationReport> verify() async {
    final list = _box!.values.toList();
    final ids = <String, int>{};
    final errors = <String>[];

    for (final r in list) {
      ids[r.id] = (ids[r.id] ?? 0) + 1;
      if (r.title.trim().isEmpty) {
        errors.add('ID=${r.id}: title が空');
      }
      if (r.updatedAt.isBefore(DateTime(1970))) {
        errors.add('ID=${r.id}: updatedAt が不正（${r.updatedAt}）');
      }
    }

    final duplicates = ids.entries.where((e) => e.value > 1).map((e) => e.key).toList();
    return VerificationReport(
      total: list.length,
      duplicateIds: duplicates,
      errors: errors,
      sample: list.take(20).toList(),
    );
  }
}

class VerificationReport {
  final int total;
  final List<String> duplicateIds;
  final List<String> errors;
  final List<Record> sample;

  VerificationReport({
    required this.total,
    required this.duplicateIds,
    required this.errors,
    required this.sample,
  });

  bool get ok => duplicateIds.isEmpty && errors.isEmpty;
}
