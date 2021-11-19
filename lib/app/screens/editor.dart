import 'dart:async';
import 'dart:ui';
import 'package:flutter/scheduler.dart';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:spark_lib/custom_window/window_appbar.dart';
import 'package:spark_lib/utility/print_env.dart';
import 'package:spark_lib/navigation/spark_nav.dart';
import 'package:spark_lib/notifications/notifications.dart';
import 'package:spark_lib/filesystem/file_paths.dart';

import 'package:data_editor/app/widgets/nav_drawer.dart';
import 'package:data_editor/app/widgets/data_editor_table.dart';
import '../theme/base_theme.dart';

class Editor extends StatelessWidget implements TickerProvider {
  @override
  Ticker createTicker(Function(Duration) callback) {
    return Ticker(callback);
  }

  @override
  Widget build(BuildContext context) {
    return SparkPage(
        child: Scaffold(
      body: Column(children: [
        Align(
          alignment: Alignment.topLeft,
          child: DataEditorTable(),
        ),
        ElevatedButton(
          child: Text("Show dialog"),
          onPressed: () {
            showBaseDialog(context,
                title: "Information",
                message: "This is a test notification." +
                    "\nNotifications can be customized to display information to the user.");
          },
        ),
        SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () {
              showSnackBar(context,
                  message: "This is a snack bar notification");
            },
            child: Text("Show Snackbar")),
        ElevatedButton(
            onPressed: () {
              showBanner(
                context,
                message: "This is a simple banner!",
              );
            },
            child: Text("Show Banner")),
        ElevatedButton(
            onPressed: () async {
              await systemPaths.ready;
              var sysPaths = systemPaths;
              List<String> paths = [];
              if (sysPaths is WindowsPaths) {
                paths = [
                  "System Root: ${sysPaths.systemRoot}",
                  "App Storage: ${sysPaths.applicationStorage}",
                  "User Directory: ${sysPaths.userDirectory}",
                  "Temp Directory: ${sysPaths.tempDirectory}",
                  "Documents Directory: ${sysPaths.documentsDirectory}",
                  "Downloads Directory: ${sysPaths.downloadsDirectory}",
                  "Program Files: ${sysPaths.programFiles}",
                  "Program Files x86: ${sysPaths.programFilesx86}",
                ];
              } else if (sysPaths is AndroidPaths) {
                paths = [
                  "System Root: ${sysPaths.systemRoot}",
                  "App Storage: ${sysPaths.applicationStorage}",
                  "User Directory: ${sysPaths.userDirectory}",
                  "Temp Directory: ${sysPaths.tempDirectory}",
                  "Documents Directory: ${sysPaths.documentsDirectory}",
                  "Downloads Directory: ${sysPaths.downloadsDirectory}",
                  "Mount: ${sysPaths.mount}",
                  "System: ${sysPaths.system}",
                  "Usercache: ${sysPaths.userCache}",
                ];
              } else if (sysPaths is MacOSPaths) {
                paths = [
                  "System Root: ${sysPaths.systemRoot}",
                  "App Storage: ${sysPaths.applicationStorage}",
                  "User Directory: ${sysPaths.userDirectory}",
                  "Temp Directory: ${sysPaths.tempDirectory}",
                  "Documents Directory: ${sysPaths.documentsDirectory}",
                  "Downloads Directory: ${sysPaths.downloadsDirectory}",
                ];
              } else if (sysPaths is LinuxPaths) {
                paths = [
                  "System Root: ${sysPaths.systemRoot}",
                  "App Storage: ${sysPaths.applicationStorage}",
                  "User Directory: ${sysPaths.userDirectory}",
                  "Temp Directory: ${sysPaths.tempDirectory}",
                  "Documents Directory: ${sysPaths.documentsDirectory}",
                  "Downloads Directory: ${sysPaths.downloadsDirectory}",
                ];
              } else if (sysPaths is IOSPaths) {
                paths = [
                  "System Root: ${sysPaths.systemRoot}",
                  "App Storage: ${sysPaths.applicationStorage}",
                  "User Directory: ${sysPaths.userDirectory}",
                  "Temp Directory: ${sysPaths.tempDirectory}",
                  "Documents Directory: ${sysPaths.documentsDirectory}",
                  "Downloads Directory: ${sysPaths.downloadsDirectory}",
                ];
              }
              String masterList = "";
              for (var path in paths) {
                masterList = masterList + path + "\n";
              }
              masterList = "Directories:\n" + masterList;
              showBaseDialog(
                context,
                message: masterList,
              );
            },
            child: Text("Print Directories")),
      ]),
      appBar: WindowAppBar.build(
        context,
        titleText: "Data Editor",
      ),
      drawer: NavDrawer(),
    ));
  }
}

/*
    Notes regarding table construction:

    - DataTable
      This seems like the natural control I want to use. It has the basic
      table features I am looking for. However, the docs say it is an expensive
      widget, so use with care.

      DataTable is not picky about what you put into it. It is just a scaffold
      with common table layout and interaction models. Columns are defined
      by DataColumn objects, and rows by DataRow objects.
      The actual widgets used in DataRow objects are up to me, so I can use
      TextFields, Text, or whatever I want.
    
    - InteractiveViewer
      Because a custom data editor has the potential to add many rows and
      columns like a spreadsheet, it will be important to be able to pan
      around the table if it overflows the screen.

      InteractiveViewer appears to be purpose-built for these kinds of use cases.
      It allows for panning and zooming (each can be optionally disabled,
      and zoom can be constrained).
    
    - SingleChildScrollView
      This was recommended by the Widget highlight video for the DataTable.
      If I understand it right, if the contents overflow in the selected axis,
      it will let you scroll to view the whole thing.

    To build my actual table, I think it will come down to an InteractiveViewer
    that contains a DataTable, that will have state-based construction logic
    to allow for viewing/editing of data. 

    -- Target behavior:
      I have 2 styles of data entry I want to support: JSON style document based,
      and SQL style table based.

      For SQL, the data has to have predefined column types, and each row must
      match the colum definitions. I want the user to be able to modify, add, and remove
      columns in the editor, as well as add, remove, and reorder rows.

      For JSON, it will more or less be storing a list of maps. It is a key : value
      system, and they can nest. 

      So, at root, you might have two keys: 'list' and 'students'.
      The list might just contain a list of numbers.
      'students' could contain a set of more key-value pairs. The key being
      the name of the student, and the value being a set of information about
      the student.

      This poses a much more complex UI case. I expect there to be no true
      "column" definitions, but rather just rows headed by a key, that
      contain a list of values (or a single value) as their value. The
      user can add and remove values from each key. 

      If the user adds a new map or list to an entry, I will need to expand the UI
      in some way (or maybe provide a popup or drill-down system?) to allow
      viewing/editing of the nested items.
 */
