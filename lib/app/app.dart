import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'package:spark_lib/widgets/shift_right_fixer.dart';
import 'package:spark_lib/navigation/spark_nav.dart';

import 'package:data_editor/app/screens/dev_info.dart';
import 'theme/base_theme.dart';
import 'screens/editor.dart';
import 'controllers/global_navigation.dart';
import 'app_system_manager.dart';
import 'screens/file_browser/file_browser.dart';
import 'screens/app_routes.dart';

/* 
    8/30/2021
    Upgraded navigation system. Added a global navigation controller that
    holds global application routes.

    Updated navigation drawer to look nicer and accept the new system.

    Next: I want to start building the editor part of the data editor.
    This will require:
      - Interface for viewing/modifying data.
      - A way to select a file to open.
      - A way to make a new file, edit it, and save it
      - And I want to be able to view the raw text of a file.

    I'll start with JSON as the file format since that has good support
    from Dart out of the box. I'll move to support SQLite after.

    TODO: The global navigator isn't getting updated when the file browser
    goes back. Fix that.
 */

// 11/1/2021 UPDATE
// TODO: Need to replace old navigator with new one from Spark Lib.
// Need to integrate custom window bar on all screens, probably
//  extract to Spark Lib
// Need to switch all screens to Spark Pages
// Probably extract AppSystemManager to Spark Lib and generalize it.
//  I expect customization will be done via overrides.

class App extends StatelessWidget {
  static const String appTitle = "Spark Data Editor";

  late final GlobalNavigation nav;

  App();

  @override
  Widget build(BuildContext context) {
    AppNavigator.initialize(home: AppRoutes.editor);

    var materialApp = MaterialApp(
      navigatorKey: AppNavigator.rootNavKey,
      debugShowCheckedModeBanner: false,
      home: AppRoutes.editor,
      theme: baseTheme,
      title: appTitle,
    );

    Widget sysManagerChild;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sysManagerChild =
          WindowBorder(color: Colors.blueGrey, width: 1, child: materialApp);
    } else {
      sysManagerChild = materialApp;
    }

    return ShiftRightFixer(child: AppManager(child: sysManagerChild));
  }
}
