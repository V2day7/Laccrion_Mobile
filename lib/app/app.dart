import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class LaccrionApp extends StatelessWidget {
  const LaccrionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
