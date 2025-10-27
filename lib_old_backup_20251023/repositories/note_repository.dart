import 'dart:math';
import 'package:hive/hive.dart';
import '../core/hive_boxes.dart';
import '../models/note.dart';

class NoteRepository {
  final Box<Note> _box = notesBox();

  String _genId() {
    final rnd = Random();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = rnd.nextInt(1 << 32).toRadixString(36);
    return '$ts-$r';
  }

  List<Note> fetchAll({bool includeArchived = false}) {
    final notes = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return includeArchived ? notes : notes.where((n) => !n.isArchived).toList();
  }

  Future<Note> create(String text) async {
    final now = DateTime.now();
    final note = Note(
      id: _genId(),
      text: text,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(note.id, note);
    return note;
  }

  Future<void> update(Note note) async {
    await _box.put(note.id, note.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> archive(String id, {bool archived = true}) async {
    final n = _box.get(id);
    if (n == null) return;
    await _box.put(id, n.copyWith(isArchived: archived, updatedAt: DateTime.now()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
