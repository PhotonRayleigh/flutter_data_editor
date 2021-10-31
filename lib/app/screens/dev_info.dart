import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:spark_lib/utility/print_env.dart';

import 'package:data_editor/app/widgets/nav_drawer.dart';

class DevInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Dev Info"),
      ),
      drawer: NavDrawer(),
      body: Center(child: FittedBox(child: EnvInfoButtons())),
    );
  }
}

class EnvInfoButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            printEnvVars();
          },
          child: Text("Print Env Vars"),
        ),
        Divider(
          color: Colors.grey.shade700,
          thickness: null,
        ),
        ElevatedButton(
            onPressed: () async {
              print("Dart.io Temp: ${Directory.systemTemp.path}");
              print("Dart.io Current: ${Directory.current.path}");
              try {
                var val = await getApplicationDocumentsDirectory();
                print("Application Documents directory: ${val.path}");
              } catch (e) {
                print("Application Documents directory not supported.");
              }

              try {
                var val = await getApplicationSupportDirectory();
                print("Application Support directory: ${val.path}");
              } catch (e) {
                print("Applications Support directory not supported.");
              }

              try {
                var val = await getDownloadsDirectory();
                print("Downloads directory: ${val!.path}");
              } catch (e) {
                print("Downloads directory not supported.");
              }

              try {
                var val = await getExternalCacheDirectories();
                int i = 0;
                for (var dir in val!) {
                  print("External Cache Directory $i: ${dir.path}");
                }
              } catch (e) {
                print("External Cache directories not supported.");
              }

              try {
                var val = await getExternalStorageDirectories();
                int i = 0;
                for (var dir in val!) {
                  print("External Storage Directory $i: ${dir.path}");
                }
              } catch (e) {
                print("External Storage Directories directory not supported.");
              }

              try {
                var val = await getExternalStorageDirectory();
                print("External Storage directory: ${val!.path}");
              } catch (e) {
                print("External Storage directory not supported.");
              }

              try {
                var val = await getLibraryDirectory();
                print("Library directory: ${val.path}");
              } catch (e) {
                print("Library directory not supported.");
              }

              try {
                var val = await getTemporaryDirectory();
                print("Temporary directory: ${val.path}");
              } catch (e) {
                print("Temporary directory not supported.");
              }
            },
            child: Text("Print FS locs"))
      ],
    );
  }
}
