import 'package:flutter/material.dart';
import 'package:data_editor/app/widgets/nav_drawer.dart';
import 'dart:io';
import 'package:spark_lib/utility/print_env.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              child: TextButton(
                child: Text("Print Env Vars"),
                onPressed: () {
                  print_env_vars();
                },
              ),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.shade100,
                border: Border.all(width: 4, color: Colors.black87),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  print("Temp: ${Directory.systemTemp.path}");
                  print("Current: ${Directory.current.path}");
                  var val = await getApplicationDocumentsDirectory();
                  var val2 = await getApplicationSupportDirectory();
                  print("Docs: ${val.path}");
                  print("Support: ${val.path}");
                },
                child: Text("Print FS locs"))
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 2,
        title: Text("Data Editor"),
      ),
      drawer: NavDrawer(),
    );
  }
}
