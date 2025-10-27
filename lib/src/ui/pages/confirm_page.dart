import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/hive_record_store.dart';
import '../../data/models/record.dart';
import '../router.dart';

class ConfirmPage extends StatefulWidget {
  const ConfirmPage({super.key});
  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  VerificationReport? _report;
  List<Record> _list = [];
  String _q = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final store = context.read<HiveRecordStore>();
    final report = await store.verify();
    final all = await store.getAll();
    setState(() { _report = report; _list = all; });
  }

  Future<void> _goCreate() async {
    final changed = await Navigator.pushNamed(context, AppRoutes.edit);
    if (changed == true) _load();
  }

  Future<void> _goEdit(Record r) async {
    final changed = await Navigator.pushNamed(context, AppRoutes.edit, arguments: r);
    if (changed == true) _load();
  }

  Future<void> _delete(Record r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${r.title}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) { await context.read<HiveRecordStore>().delete(r.id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('データ確認'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: '追加', onPressed: _goCreate),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreate,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _Summary(report: report),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '検索（title/note を対象）',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(child: _RecordsList(all: _list, q: _q, onEdit: _goEdit, onDelete: _delete)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});
  final VerificationReport report;

  @override
  Widget build(BuildContext context) {
    final ok = report.ok;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(ok ? '検証OK' : '問題あり', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('総件数: ${report.total}'),
            ]),
            const SizedBox(height: 12),
            if (report.duplicateIds.isNotEmpty) _badge('重複ID: ${report.duplicateIds.join(', ')}', Colors.red),
            if (report.errors.isNotEmpty) _badge('エラー件数: ${report.errors.length}', Colors.red),
            if (report.errors.isEmpty && report.duplicateIds.isEmpty) _badge('異常なし', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color)),
    ),
  );
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.all, required this.q, required this.onEdit, required this.onDelete});
  final List<Record> all;
  final String q;
  final Function(Record) onEdit;
  final Function(Record) onDelete;

  @override
  Widget build(BuildContext context) {
    final filtered = q.isEmpty
        ? all
        : all.where((r) {
      final t = r.title.toLowerCase();
      final n = (r.note ?? '').toLowerCase();
      final qq = q.toLowerCase();
      return t.contains(qq) || n.contains(qq);
    }).toList();
    if (filtered.isEmpty) return const Center(child: Text('該当なし'));

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = filtered[i];
        return ListTile(
          onTap: () => onEdit(r),
          title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('ID=${r.id} / 更新: ${r.updatedAt.toIso8601String()}'
              '${(r.note == null || r.note!.isEmpty) ? '' : '\n' + r.note!}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(r)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onDelete(r)),
            ],
          ),
        );
      },
    );
  }
}
