import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/app.dart';
import 'package:get_storage/get_storage.dart';

// 1) Make it work
// 2) Make it right
// 3) Make it fast

void main() async {
  await GetStorage.init();
  runApp(App());
}
