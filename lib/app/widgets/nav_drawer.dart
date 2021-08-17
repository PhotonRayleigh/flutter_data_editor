import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:get/get.dart';
import 'package:data_editor/app/screens/file_browser.dart';

class NavDrawer extends StatefulWidget {
  @override
  _NavDrawerState createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  static final List<Tuple2<String, Widget>> _navList =
      <Tuple2<String, Widget>>[];
  static bool _navInitialized = false;

  _NavDrawerState() {
    if (!_navInitialized) {
      _navList.add(Tuple2<String, Widget>('File Browser', FileBrowser()));
      _navInitialized = true;
    }
  }

  void _nav(int viewNumber) {
    print('$viewNumber');
    Get.to(() => _navList[viewNumber].item2, routeName: "File Browser");
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
    int i = 0;
    for (var item in _navList) {
      var temp = i;
      navTiles.add(ListTile(
        title: Text(item.item1),
        onTap: () => _nav(temp),
      ));
      i++;
    }
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
