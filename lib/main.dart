import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'src/core/hive_init.dart';
import 'src/ui/router.dart';
import 'src/data/local/hive_record_store.dart';
import 'src/data/sync/sync_service.dart';
import 'src/data/remote/sync_api.dart';
import 'src/data/models/record.dart';

// ← デモ投入のON/OFF。確認が済んだら false にしてください。
const bool kSeedDemo = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();

  final localStore = HiveRecordStore();
  await localStore.open();

  // ★ 初回だけダミーデータを投入（recordsBox が空のとき）
  if (kSeedDemo && await localStore.count() == 0) {
    final now = DateTime.now();
    final demo = <Record>[
      Record(id: 'demo-001', title: 'はじめてのメモ', note: 'Hive保存の動作確認', updatedAt: now.subtract(const Duration(minutes: 3))),
      Record(id: 'demo-002', title: '買い物リスト', note: '牛乳, 卵, パン', updatedAt: now.subtract(const Duration(minutes: 2))),
      Record(id: 'demo-003', title: 'やること', note: 'プロトタイプ同期テスト', updatedAt: now.subtract(const Duration(minutes: 1))),
      Record(id: 'demo-004', title: 'メモ（空ノート可）', note: '', updatedAt: now),
      Record(id: 'demo-005', title: '日時テスト', note: 'updatedAtの並び確認', updatedAt: now.add(const Duration(seconds: 10))),
    ];
    await localStore.putAll(demo);
  }

  // 擬似クラウドAPI
  final syncApi = MockSyncApi();
  await syncApi.init();

  final syncService = SyncService(localStore: localStore, api: syncApi);
  runApp(MyApp(syncService: syncService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.syncService});
  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SyncService>.value(value: syncService),
        Provider<HiveRecordStore>.value(value: syncService.localStore),
      ],
      child: MaterialApp(
        title: 'MyAsh',
        theme: ThemeData(
          fontFamily: 'NotoSansJP',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.home,
      ),
    );
  }
}
