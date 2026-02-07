import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MwukziApp(),
    ),
  );
}

class MwukziApp extends StatelessWidget {
  const MwukziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뭑지',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFAF5),
      ),
      home: const HomeScreen(),
    );
  }
}
