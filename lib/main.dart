
import 'package:flutter/material.dart';
import 'package:aitaku/screens/LandingScreen/landing-screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aitaku',
      debugShowCheckedModeBanner: false,
      theme: _ThemeData(),
      home: const LandingScreen(),
    );
  }
}

ThemeData _ThemeData() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      onPrimary: Colors.indigo[900]
    ),
    useMaterial3: true,
  );
}
