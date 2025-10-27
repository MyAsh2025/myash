import 'package:flutter/material.dart';
import 'src/ui/pages/home_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyAshApp());
}

class MyAshApp extends StatelessWidget {
  const MyAshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAsh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
