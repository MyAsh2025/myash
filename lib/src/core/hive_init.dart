import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/record.dart';

class HiveInit {
  static const recordsBox = 'recordsBox';
  static const serverBox = 'serverBox'; // 擬似クラウド用

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(RecordAdapter().typeId)) {
      Hive.registerAdapter(RecordAdapter());
    }
  }
}
