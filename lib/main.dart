import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';

import 'package:spark_lib/custom_window/bitsdojo_boilerplate.dart';

import 'app/app.dart';

// 1) Make it work
// 2) Make it right
// 3) Make it fast

void main() async {
  runApp(App());

  initializeBitsdojo(
      initialSize: Size(900, 600),
      minSize: Size(200, 200),
      alignment: Alignment.center,
      title: "Data Editor");

  // bitsdogo_window startup code.
  // This is required when using the bitsdojo package,
  // Window will not otherwise show.
  // REMINDER: Custom runner code setup required PER PLATFORM
  // if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  //   doWhenWindowReady(() {
  //     final initialSize = Size(900, 600);
  //     final minSize = Size(200, 200);
  //     appWindow.size = initialSize;
  //     appWindow.minSize = minSize;
  //     appWindow.alignment = Alignment.center;
  //     appWindow.title = "Data Editor";
  //     appWindow.show();
  //   });
  // }
}
