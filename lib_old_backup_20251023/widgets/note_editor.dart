import 'package:flutter/material.dart';

class NoteEditor extends StatefulWidget {
  final String initial;
  const NoteEditor({super.key, required this.initial});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メモを編集'),
      content: TextField(
        controller: controller,
        maxLines: 6,
        decoration: const InputDecoration(hintText: '内容を編集'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('キャンセル')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('保存')),
      ],
    );
  }
}
