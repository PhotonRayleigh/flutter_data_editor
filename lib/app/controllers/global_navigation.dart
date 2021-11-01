import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

class GlobalNavigation extends GetxController {
  Map<String, NavItem> navList = <String, NavItem>{};
  String currentPath = "";
  Widget currentViewRoot = Container();

  @override
  void onInit() async {
    super.onInit();
    // Init first
  }

  @override
  void onClose() {
    // Close last
    super.onClose();
  }

  /// USAGE: when used with Get.to or Navigator.push,
  /// use navigate(path) as the builder callback.
  /// Use it directly to generate the home view of the
  /// Material/CupertinoApp.
  Widget navigate(String path) {
    var newView = navList[path];
    if (newView == null) {
      throw NullThrownError();
    }
    currentPath = path;
    currentViewRoot = newView.builder();
    return currentViewRoot;
  }

  operator []=(String key, NavItem value) {
    navList[key] = value;
  }

  NavItem? operator [](String key) {
    return navList[key];
  }
}

class NavItem {
  String prettyName;
  Widget Function() builder;
  NavItem(this.prettyName, this.builder);
}
