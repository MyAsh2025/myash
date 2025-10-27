import 'package:flutter/material.dart';
import '../router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyAsh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _Tile(
              title: 'データ確認（検証・一覧・検索）',
              subtitle: '重複/必須/日付異常のチェックと、一覧表示',
              onTap: () => Navigator.pushNamed(context, AppRoutes.confirm),
              icon: Icons.rule,
            ),
            const SizedBox(height: 12),
            _Tile(
              title: '同期（擬似クラウド⇄端末）',
              subtitle: 'pull→merge→push の2-way同期を実行',
              onTap: () => Navigator.pushNamed(context, AppRoutes.sync),
              icon: Icons.sync,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
