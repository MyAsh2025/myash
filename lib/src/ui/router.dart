import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/confirm_page.dart';
import 'pages/sync_page.dart';
import 'pages/note_editor_page.dart';
import '../data/models/record.dart';

class AppRoutes {
  static const home = '/';
  static const confirm = '/confirm';
  static const sync = '/sync';
  static const edit = '/edit';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.confirm:
        return MaterialPageRoute(builder: (_) => const ConfirmPage());
      case AppRoutes.sync:
        return MaterialPageRoute(builder: (_) => const SyncPage());
      case AppRoutes.edit:
        final rec = settings.arguments as Record?;
        return MaterialPageRoute(builder: (_) => NoteEditorPage(initial: rec));
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
