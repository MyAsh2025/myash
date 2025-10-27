import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/sync/sync_service.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  String _log = '';
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _log = '同期開始...\n';
    });
    try {
      final svc = context.read<SyncService>();
      final result = await svc.sync();

      final totalPush = result.pushUpsertCount + result.pushDeleteCount;

      setState(() {
        _log += 'pull件数: ${result.pullCount}\n';
        _log += 'push件数: $totalPush\n';
        _log += '  - upsert: ${result.pushUpsertCount}\n';
        _log += '  - delete: ${result.pushDeleteCount}\n';
        _log += '競合数: ${result.conflicts}\n';
        _log += '同期後総件数: ${result.finalServerCount}\n';
        _log += '完了。';
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('同期')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _running ? null : _run,
              icon: const Icon(Icons.sync),
              label: const Text('同期を実行'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? 'ここにログが出ます' : _log,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
