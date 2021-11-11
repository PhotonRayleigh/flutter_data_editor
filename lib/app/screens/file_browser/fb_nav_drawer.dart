import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:data_editor/app/controllers/filesystem_controller.dart';
import 'package:spark_lib/navigation/app_navigator.dart';

class FbNavDrawer extends StatefulWidget {
  FbNavDrawer(this.controller, {Key? key}) : super(key: key);

  final FsController controller;

  @override
  State<StatefulWidget> createState() {
    return FbNavDrawerState(controller);
  }
}

class FbNavDrawerState extends State<FbNavDrawer> {
  FbNavDrawerState(this.controller);

  @override
  void initState() {
    super.initState();
    createNavList();
  }

  final FsController controller;
  List<Widget> listTiles = [];

  @override
  Widget build(BuildContext context) {
    var drawerHeader = DrawerHeader(
      child: Column(
        children: [
          Align(
            child: Row(children: [
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    AppNavigator.navigateBack();
                  }),
              Text("Return to last screen"),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (_) {
                      return <PopupMenuItem<String>>[
                        PopupMenuItem(
                          child: Text("Clear Favorites"),
                          value: 'clearFavs',
                        ),
                      ];
                    },
                    onSelected: (item) {
                      switch (item) {
                        case 'clearFavs':
                          Future.microtask(() => controller.clearFavorites())
                              .whenComplete(() async => await createNavList())
                              .whenComplete(() => setState(() {}));
                          break;
                      }
                    },
                  ),
                ),
              )
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
    );

    var drawerBody = Expanded(
      child: ListView(
        controller: ScrollController(),
        children: [
          ...listTiles,
        ],
      ),
    );

    var drawerHelp = ListTile(
      leading: Icon(Icons.help),
      title: Text("Help"),
      onTap: () {
        Get.defaultDialog(
            title: "Usage Instructions",
            content: Text(
              "- Double tap a folder or link to follow it.\n" +
                  "- Press the cheveron to reveal a folder's contents in-line.\n" +
                  "- Type an address into the address bar and press enter to go to it.\n" +
                  "- Use navigation buttons in top right to go back, forward, or up a directory\n",
              textAlign: TextAlign.start,
            ),
            confirm: TextButton(
              child: Text("Ok"),
              onPressed: AppNavigator.safePop,
            ));
      },
    );

    return Drawer(
      child: Column(
        children: [
          drawerHeader,
          drawerBody,
          drawerHelp,
        ],
      ),
    );
  }

  Future createNavList() async {
    if (kIsWeb) {
      listTiles = [
        ListTile(
          title: Text("Not supported on web"),
        )
      ];
      return;
    }

    await controller.init;

    var pathList = <String>[];

    if (Platform.isWindows) {
      pathList.add(controller.systemRoot);
      pathList.add(controller.systemPaths[0]);
      pathList.add(controller.systemPaths[1]);
      pathList.add(controller.home);
      pathList.addAll(
          controller.systemPaths.sublist(2, controller.systemPaths.length));
      pathList.addAll(controller.favPaths);
    } else if (Platform.isMacOS || Platform.isLinux) {
      pathList.add(controller.systemRoot);
      pathList.add(controller.home);
      pathList.addAll(controller.systemPaths);
      pathList.addAll(controller.favPaths);
    } else if (Platform.isAndroid) {
      pathList.add(controller.systemRoot);
      pathList.addAll(controller.systemPaths);
      pathList.addAll(controller.favPaths);
    } else if (Platform.isIOS) {
      pathList.add(controller.home);
      pathList.addAll(controller.systemPaths);
      pathList.addAll(controller.favPaths);
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
              AppNavigator.safePop();
            }),
    ];
    setState(() {});
    return;
  }
}
