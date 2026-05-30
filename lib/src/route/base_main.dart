import 'package:assibant/src/app/theme.dart' as app_theme;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BaseMain extends StatelessWidget {
  const BaseMain({
    required this.home,
    required this.showDebugBanner,
    super.key,
  });

  final Widget home;

  final bool showDebugBanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: showDebugBanner,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'app_name'.tr(),
      home: home,
      theme: app_theme.buildAppTheme(),
      themeMode: ThemeMode.light,
    );
  }
}
