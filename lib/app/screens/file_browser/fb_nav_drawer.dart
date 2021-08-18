import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_editor/app/controllers/filesystem_controller.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class fbNavDrawer extends StatelessWidget {
  fbNavDrawer(this.controller, {Key? key}) : super(key: key) {
    createNavList();
  }

  final FsController controller;
  late final List<Widget> listTiles;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Align(
                  child: Row(children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Get.back();
                          Get.back();
                        }),
                    Text("Return to home"),
                  ]),
                  alignment: Alignment.topLeft,
                ),
                Expanded(
                    child: Align(
                  child: Text(
                    "Quick Access",
                    style: TextStyle(fontSize: 24),
                  ),
                  alignment: Alignment.bottomLeft,
                )),
              ],
            ),
          ),
          for (var tile in listTiles) tile,
        ],
      ),
    );
  }

  void createNavList() {
    if (kIsWeb) {
      listTiles = [
        ListTile(
          title: Text("Not supported on web"),
        )
      ];
      return;
    }

    var env = Platform.environment;
    var pathList = <String>[];

    if (Platform.isWindows) {
      var home = "";
      if (env['SYSTEMDRIVE'] != null)
        pathList.add(env['SYSTEMDRIVE']! + p.separator);
      if (env['USERPROFILE'] != null) {
        home = env['USERPROFILE']!;
        pathList.add(home);
        pathList.add(p.join(home, "documents"));
        pathList.add(p.join(home, "pictures"));
        pathList.add(p.join(home, "desktop"));
      }
    } else if (Platform.isMacOS) {
      listTiles = [
        ListTile(
          title: Text("Mac"),
        )
      ];
      return;
    } else if (Platform.isLinux) {
      listTiles = [
        ListTile(
          title: Text("Linux"),
        )
      ];
      return;
    } else if (Platform.isAndroid) {
      pathList.add(controller.home);
      pathList.add(p.join(p.separator, "storage", "emulated", "0"));
      pathList.add(p.join(p.separator,
          "sdcard")); // I think this just points to internal storage
      pathList.add(p.join(p.separator, "mnt"));
      pathList.add(p.join(p.separator, "system"));
    } else if (Platform.isIOS) {
      listTiles = [
        ListTile(
          title: Text("iOS"),
        )
      ];
      return;
    } else {
      listTiles = [
        ListTile(
          title: Text("Unsupported platform"),
        )
      ];
      return;
    }
    listTiles = [
      for (var s in pathList)
        ListTile(
            title: Text(s),
            onTap: () {
              controller
                  .setLocation(s)
                  .whenComplete(() => controller.fileBrowserRefresh());
              Get.back();
            }),
    ];
    return;
  }
}
