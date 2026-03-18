import 'package:flutter/material.dart';

import 'features/shell/presentation/root_shell.dart';

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QL Chi Tieu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6EFD)),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}
