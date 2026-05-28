import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/app/mobile_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapptemp/src/providers/prefs_provider.dart';

Future<void> mobileMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        title: 'assisbant remote',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6366F1),
          useMaterial3: true,
        ),
        home: const MobileShell(),
      ),
    ),
  );
}
