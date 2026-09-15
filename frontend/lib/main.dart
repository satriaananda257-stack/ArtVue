import 'package:flutter/material.dart';
import 'package:frontend/pages/splashPage.dart';
import 'package:frontend/pages/homePage.dart';
import 'package:frontend/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLoggedIn = false;
  try {
    isLoggedIn = await StorageService.isLoggedIn();
  } catch (_) {
    // SharedPreferences gagal (channel error) — treat sebagai belum login
    isLoggedIn = false;
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artvue',
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff009E9A),
        ),
        scaffoldBackgroundColor: const Color(0xffffffff),
      ),
      builder: (context, child) => child!,
      home: isLoggedIn ? const homePage() : const splashPage(),
    );
  }
}
