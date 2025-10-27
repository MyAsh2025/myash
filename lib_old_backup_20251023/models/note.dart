import 'package:hive/hive.dart';

/// シンプルなメモモデル（build_runner不要）
class Note {
  int id;
  String text;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.text,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// 手書き TypeAdapter（hive_generator不要）
class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final id = reader.readInt();
    final text = reader.readString();
    final created =
    DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updated =
    DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Note(id: id, text: text, createdAt: created, updatedAt: updated);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.text)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
