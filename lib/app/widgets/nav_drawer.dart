import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:get/get.dart';
// import 'package:data_editor/app/screens/file_browser/file_browser.dart';
import 'package:data_editor/app/systems/global_navigation.dart';

class NavDrawer extends StatefulWidget {
  @override
  _NavDrawerState createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  late GlobalNavigation nav;

  _NavDrawerState();

  @override
  void initState() {
    super.initState();

    nav = Get.find<GlobalNavigation>();
  }

  void _nav(String path, Widget view) {
    nav.currentLoc = Tuple2(path, view);
    Get.to(() => view, routeName: path);
    // Navigator.of(context)
    //     .push(MaterialPageRoute<void>(builder: (BuildContext context) {
    //   var target = _navList[viewNumber].item2;
    //   if (target is ShopperProvider) {
    //     target.prevContext = context;
    //   }
    //   return target;
    // }));
  }

  List<ListTile> _buildNavTiles() {
    var navTiles = <ListTile>[];

    nav.navList.forEach((path, item) {
      if (path == nav.currentLoc.item1) return;

      Widget? leading;
      if (path == "/")
        leading = Icon(Icons.home);
      else if (path == "/dev info")
        leading = Icon(Icons.developer_mode);
      else if (path == "/file browser") leading = Icon(Icons.folder_open);

      navTiles.add(
        ListTile(
          leading: leading,
          title: Text(item.prettyName),
          onTap: () => _nav(path, item.builder()),
        ),
      );
    });
    return navTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              'Navigation',
              style: TextStyle(fontSize: 24),
            ),
          ),
          for (var i in _buildNavTiles()) i,
          AboutListTile(
            applicationName: 'Spark Flutter',
            applicationVersion: '0.0.1',
          )
        ],
      ),
    );
  }
}
