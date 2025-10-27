import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/hive_record_store.dart';
import '../../data/models/record.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.initial});
  final Record? initial;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
  TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _note =
  TextEditingController(text: widget.initial?.note ?? '');
  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = context.read<HiveRecordStore>();
    final isNew = widget.initial == null;
    final id = isNew ? const Uuid().v4() : widget.initial!.id;
    final rec = Record(
      id: id,
      title: _title.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      updatedAt: DateTime.now(),
    );
    await store.put(rec);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.initial == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${widget.initial!.title}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<HiveRecordStore>().delete(widget.initial!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '新規作成' : '編集'),
        actions: [
          if (!isNew)
            IconButton(icon: const Icon(Icons.delete), onPressed: _saving ? null : _delete),
          IconButton(icon: const Icon(Icons.save), onPressed: _saving ? null : _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'タイトルは必須です' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'メモ（任意）', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(isNew ? '作成して保存' : '上書き保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
