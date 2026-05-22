import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutterapptemp/src/route/normal_main.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  EasyLocalization elw(Widget widget) {
    return EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      path: 'assets/localizations',
      fallbackLocale: const Locale('en', 'US'),
      child: widget,
    );
  }

  await normalMain(elw);
}
