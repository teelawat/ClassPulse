import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class ClassPulseApp extends StatelessWidget {
  const ClassPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassPulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Theme.of(context).textTheme),
      home: const HomeScreen(),
    );
  }
}
