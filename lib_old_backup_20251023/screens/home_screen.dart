import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/hive_boxes.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/note_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = NoteRepository();
  final controller = TextEditingController();
  bool showArchived = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyAsh — Hive Demo'),
        actions: [
          IconButton(
            tooltip: showArchived ? 'アーカイブ非表示' : 'アーカイブ表示',
            onPressed: () => setState(() => showArchived = !showArchived),
            icon: Icon(showArchived ? Icons.inbox : Icons.inbox_outlined),
          ),
          IconButton(
            tooltip: '全削除（注意）',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('全削除しますか？'),
                  content: const Text('Box内のメモをすべて削除します。取り消せません。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
                  ],
                ),
              );
              if (ok == true) {
                await repo.clearAll();
                setState(() {});
              }
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: notesBox().listenable(),
        builder: (context, Box<Note> box, _) {
          final items = repo.fetchAll(includeArchived: showArchived);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'メモを入力して Enter',
                          labelText: '新規メモ',
                        ),
                        onSubmitted: (_) => _create(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('メモはありません'))
                      : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return Card(
                        child: ListTile(
                          title: Text(
                            n.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '更新: ${n.updatedAt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          leading: Icon(n.isArchived ? Icons.archive : Icons.note),
                          onTap: () async {
                            final updated = await showDialog<String?>(
                              context: context,
                              builder: (_) => NoteEditor(initial: n.text),
                            );
                            if (updated != null && updated.trim().isNotEmpty) {
                              await repo.update(n.copyWith(text: updated.trim()));
                            }
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'archive':
                                  await repo.archive(n.id, archived: !n.isArchived);
                                  break;
                                case 'delete':
                                  await repo.delete(n.id);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(n.isArchived ? 'アーカイブ解除' : 'アーカイブ'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('削除'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    await repo.create(text);
    controller.clear();
    setState(() {});
  }
}
