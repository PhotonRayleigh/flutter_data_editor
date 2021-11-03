import 'package:flutter/material.dart';

import 'editor.dart';
import 'file_browser/file_browser.dart';
import 'dev_info.dart';

class AppRoutes {
  static Widget home = Editor();

  static Widget editor = home;
  static Widget fileBrowser = FileBrowser();
  static Widget devInfo = DevInfo();
}
