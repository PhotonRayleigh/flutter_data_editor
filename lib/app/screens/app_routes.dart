import 'package:flutter/material.dart';
import 'editor.dart';

import 'file_browser/file_browser.dart';

class AppRoutes {
  static Widget home = Editor();

  static Widget editor = home;
  static Widget fileBrowser = FileBrowser();
}
