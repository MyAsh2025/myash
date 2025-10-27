import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('myash')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MyAsh デプロイ確認ページ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('この画面が出ていれば、GitHub Pages への反映は成功です！'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✨ 反映OK！'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('動作チェック'),
            ),
          ],
        ),
      ),
    );
  }
}
