import 'package:assibant/src/main_page.dart';
import 'package:assibant/src/providers/prefs_provider.dart';
import 'package:assibant/src/route/base_main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> normalMain(EasyLocalization Function(Widget) elw) async {
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: elw(
        const BaseMain(
          home: MainPage(),
          showDebugBanner: true,
        ),
      ),
    ),
  );
}
