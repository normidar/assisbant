import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/mobile_shell.dart';
import 'package:assibant/src/data/services/notification_service.dart';
import 'package:assibant/src/providers/prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> mobileMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = await initLocalNotifications();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localNotificationsProvider.overrideWithValue(notifications),
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
