import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

class GlobalNavigation {
  Map<String, NavItem> navList = <String, NavItem>{};
  Tuple2<String, Widget> currentLoc = Tuple2("", Container());
}

class NavItem {
  String prettyName;
  Widget Function() builder;
  NavItem(this.prettyName, this.builder);
}
