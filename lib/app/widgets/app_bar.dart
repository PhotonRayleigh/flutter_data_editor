import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';

import 'package:spark_lib/navigation/spark_nav.dart';

class MainAppBar {
  static AppBar build(BuildContext context,
      {Key? key, required String titleText}) {
    Widget appBarTitle;
    List<Widget> appBarActions = [];
    WindowButtonColors windowButtonColors =
        WindowButtonColors(iconNormal: Colors.white, mouseOver: Colors.black38);

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      appBarActions = [
        // IconButton(
        //   onPressed: () {
        //     AppNavigator.defaultBack();
        //   },
        //   icon: Icon(Icons.arrow_back),
        //   color: Colors.amber[300],
        // ),
        if (AppNavigator.currentView != AppNavigator.homeScreen)
          IconButton(
            onPressed: () {
              AppNavigator.navigateBack();
            },
            icon: Icon(Icons.arrow_back),
          ),
        MinimizeWindowButton(
          colors: windowButtonColors,
        ),
        MaximizeWindowButton(colors: windowButtonColors),
        CloseWindowButton(
            colors: WindowButtonColors(
                iconNormal: Colors.white,
                mouseOver: Colors.pink[900]?.withOpacity(0.65),
                mouseDown: Colors.pink[200])),
      ];
      appBarTitle =
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            child: ConstrainedBox(
                constraints: BoxConstraints.loose(Size(double.infinity, 100)),
                child: MoveWindow(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          titleText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                Theme.of(context).textTheme.headline5?.fontSize,
                          ),
                        )))))
      ]);
    } else {
      appBarTitle = Text(
        titleText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Theme.of(context).textTheme.headline5?.fontSize,
        ),
      );
    }

    return AppBar(
      title: appBarTitle,
      actions: appBarActions,
    );
  }
}
