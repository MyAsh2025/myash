import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'src/core/hive_init.dart';
import 'src/ui/router.dart';
import 'src/data/local/hive_record_store.dart';
import 'src/data/sync/sync_service.dart';
import 'src/data/remote/sync_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();

  final localStore = HiveRecordStore();
  await localStore.open();

  // 擬似クラウドAPI（ローカル別Boxをクラウド代わりに）
  final syncApi = MockSyncApi(); // 将来ここを本物のREST実装に差し替え
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
