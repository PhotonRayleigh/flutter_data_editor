import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_system_manager.dart';
import 'theme/base_theme.dart';
import 'screens/home.dart';

class App extends StatelessWidget {
  static const String appTitle = "Spark Data Editor";

  @override
  Widget build(BuildContext context) {
    return AppSystemManager(
      child: GetMaterialApp(
        title: appTitle,
        theme: baseTheme,
        home: Home(),
      ),
    );
  }
}
