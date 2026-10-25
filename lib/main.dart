import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'countdown/countdown_controller.dart';
import 'countdown/preset_loader.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

void main() => runApp(const CountdownDemoApp());

class CountdownDemoApp extends StatelessWidget {
  const CountdownDemoApp({super.key, this.loadPresets, this.createController});

  final LoadPresets? loadPresets;
  final CountdownController Function(int seconds)? createController;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đồng hồ đếm ngược',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: DemoHost(
      loadPresets: loadPresets ?? const PresetLoader().load,
      createController:
          createController ??
          (seconds) => CountdownController(seconds: seconds),
    ),
  );
}
