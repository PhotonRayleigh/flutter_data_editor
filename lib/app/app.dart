import 'package:data_editor/app/screens/dev_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuple/tuple.dart';
import 'app_system_manager.dart';
import 'theme/base_theme.dart';
import 'screens/home.dart';
import 'widgets/shift_right_fixer.dart';
import 'systems/global_navigation.dart';
import 'screens/file_browser/file_browser.dart';

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

class App extends StatelessWidget {
  static const String appTitle = "Spark Data Editor";

  late final GlobalNavigation nav;

  App() {
    nav = Get.put(GlobalNavigation());

    nav.navList["/"] = NavItem("Home", () => Home());
    nav.navList["/file browser"] = NavItem("File Browser", () => FileBrowser());
    nav.navList["/dev info"] = NavItem("Developer Info", () => DevInfo());
  }

  @override
  Widget build(BuildContext context) {
    nav.currentLoc = Tuple2("/", Home());

    return ShiftRightFixer(
      child: AppSystemManager(
        child: GetMaterialApp(
          title: appTitle,
          theme: baseTheme,
          home: nav.currentLoc.item2,
        ),
      ),
    );
  }
}
