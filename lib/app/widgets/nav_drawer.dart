import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:spark_lib/navigation/spark_nav.dart';

import '../screens/app_routes.dart';
import 'package:data_editor/app/screens/file_browser/file_browser.dart';
import '../screens/editor.dart';
import '../screens/dev_info.dart';

class NavDrawer extends StatefulWidget {
  @override
  _NavDrawerState createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  _NavDrawerState();

  @override
  void initState() {
    super.initState();
  }

  List<ListTile> _buildNavTiles() {
    var navTiles = <ListTile>[
      if (!(AppNavigator.currentView is Editor))
        ListTile(
          leading: Icon(Icons.home),
          title: Text("Editor"),
          onTap: () => AppNavigator.navigateTo(AppRoutes.editor),
        ),
      if (!(AppNavigator.currentView is FileBrowser))
        ListTile(
          leading: Icon(Icons.folder_open),
          title: Text("File Browser"),
          onTap: () => AppNavigator.navigateTo(AppRoutes.fileBrowser),
        ),
      if (!(AppNavigator.currentView is DevInfo))
        ListTile(
          leading: Icon(Icons.developer_board),
          title: Text("Dev Info"),
          onTap: () => AppNavigator.navigateTo(AppRoutes.devInfo),
        ),
    ];

    return navTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text(
              'Navigation',
              style: TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
              child: ListView(children: [for (var i in _buildNavTiles()) i])),
          AboutListTile(
            applicationName: 'Spark Flutter',
            applicationVersion: '0.0.1',
          )
        ],
      ),
    );
  }
}
