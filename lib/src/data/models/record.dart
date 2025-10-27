import 'package:hive/hive.dart';
part 'record.g.dart';

@HiveType(typeId: 1)
class Record {
  @HiveField(0)
  final String id; // 主キー（JSONインポート時に付与済み前提）

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? note;

  @HiveField(3)
  final DateTime updatedAt;

  Record({
    required this.id,
    required this.title,
    this.note,
    required this.updatedAt,
  });

  Record copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? updatedAt,
  }) {
    return Record(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Record fromMap(Map<String, dynamic> m) {
    return Record(
      id: m['id'] as String,
      title: (m['title'] ?? '').toString(),
      note: m['note']?.toString(),
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
