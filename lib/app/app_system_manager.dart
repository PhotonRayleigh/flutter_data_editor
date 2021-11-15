import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:spark_lib/app/app_system_manager.dart';

late final _AppManagerState appManager;

class AppManager extends AppSystemManager {
  AppManager({Key? key, required Widget child}) : super(key: key, child: child);

  @override
  _AppManagerState createState() {
    return _AppManagerState();
  }
}

class _AppManagerState extends AppSystemManagerState {
  _AppManagerState() : super() {
    appManager = this;
  }

  @override
  void initState() {
    super.initState();
    // call super init first
  }

  @override
  void dispose() {
    // call super dispose last
    super.dispose();
  }
}
