import 'package:flutter/material.dart';
import 'package:data_editor/app/widgets/nav_drawer.dart';
import 'dart:io';
import 'package:spark_lib/utility/print_env.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(),
      appBar: AppBar(
        elevation: 2,
        title: Text("Data Editor"),
      ),
      drawer: NavDrawer(),
    );
  }
}
