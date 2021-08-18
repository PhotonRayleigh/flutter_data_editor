import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:data_editor/app/controllers/filesystem_controller.dart';
import 'fb_nav_drawer.dart';
import 'package:permission_handler/permission_handler.dart';

//TODOs:
// - Make file system watching sane and not crash
// - Allow for navigating between directories
// - Allow folding of scanned directories
// - URL bar

class FileBrowser extends StatefulWidget {
  @override
  State<FileBrowser> createState() {
    return FileBrowserState();
  }
}

class FileBrowserState extends State<FileBrowser> {
  var fileList = <Widget>[];

  late TextField urlBar;
  late TextEditingController textControl;

  FsController get fsCon {
    return Get.put(FsController(fileBrowserRefresh: flagUpdate));
  }

  @override
  void initState() {
    super.initState();
    textControl = TextEditingController();
    if (Platform.isAndroid || Platform.isIOS) {
      requestPermissions().whenComplete(start);
    } else
      start();
  }

  Future start() async {
    await fsCon.init;
    if (fsCon.currentPath == "") fsCon.currentPath = fsCon.home;

    // This works! It seems to break a little when a file is freshly created though.
    // Will need to refine it, but holy smokes it works!
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows)
      fsCon.currentDir.watch(events: FileSystemEvent.all).listen((event) {
        refreshDir();
      });
    refreshDir();
  }

  Future requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission NOT granted");
    }
  }

  Future refreshDir() async {
    await fsCon.init;
    await fsCon.scanDir().whenComplete(() => flagUpdate());
  }

  void flagUpdate() {
    setState(() {
      fileList = buildFileList();
      textControl.text = fsCon.currentPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    // fsCon.scanDir(fsCon.home);

    // double screenWidth = MediaQuery.of(context).size.width;

    // BUG: Flutter treats right-shift like Caps lock
    // Bug is known and documented here: https://github.com/flutter/flutter/issues/75675
    // Will employ temporary fix as advised
    urlBar = TextField(
      decoration: InputDecoration(
          border: UnderlineInputBorder(),
          hintMaxLines: 1,
          hintText: 'Enter URL',
          suffix: IconButton(
              onPressed: () {
                //textControl.clear();
                textControl.text = fsCon.currentPath;
              },
              icon: Icon(Icons.cancel))),
      controller: textControl,
      maxLines: 1,
      keyboardType: TextInputType.url,
      onSubmitted: (val) async {
        var checkDir = Directory(val);
        try {
          var exists = await checkDir.exists();
          if (exists == false)
            textControl.printError(info: "Invalid path");
          else {
            fsCon.setLocation(val).whenComplete(() => flagUpdate());
          }
        } catch (e) {
          print("Error in Directory.exists()");
          print("Exception message: ${e.toString()}");
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("File Browser"),
        actions: [
          buildBackButton(),
          buildForwardButton(),
          buildUpButton(),
          IconButton(
            onPressed: refreshDir,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Form(child: urlBar),
          Expanded(
            child: ListView(
              children: fileList,
            ),
          ),
        ],
      ),
      drawer: fbNavDrawer(fsCon),
    );
  }

  IconButton buildForwardButton() {
    if (fsCon.forwardHistory.length == 0)
      return IconButton(onPressed: null, icon: Icon(Icons.arrow_forward));
    else
      return IconButton(
          onPressed: () {
            fsCon.moveForward().whenComplete(() => flagUpdate());
          },
          icon: Icon(Icons.arrow_forward));
  }

  IconButton buildBackButton() {
    if (fsCon.backHistory.length == 0)
      return IconButton(onPressed: null, icon: Icon(Icons.arrow_back));
    else
      return IconButton(
          onPressed: () {
            fsCon.moveBack().whenComplete(() => flagUpdate());
          },
          icon: Icon(Icons.arrow_back));
  }

  IconButton buildUpButton() {
    return IconButton(
        onPressed: () {
          fsCon.moveUp().whenComplete(() => flagUpdate());
        },
        icon: Icon(Icons.arrow_upward));
  }

  List<Widget> buildFileList() {
    var list = <Widget>[];
    for (var dir in fsCon.dirs) {
      var tile = ListTile(
        leading: Icon(Icons.folder),
        title: Text(p.basename(dir.path)),
        onTap: () {
          fsCon.setLocation(dir.path).whenComplete(flagUpdate);
        },
      );

      list.add(LongPressDraggable(
        dragAnchorStrategy: pointerDragAnchorStrategy,
        child: tile,
        feedback: LimitedBox(
          child: Card(child: tile),
          maxHeight: 100,
          maxWidth: 200,
        ),
      ));
    }

    for (var file in fsCon.files) {
      var tile = ListTile(
        leading: Icon(Icons.file_present),
        title: Text(p.basename(file.path)),
      );

      list.add(LongPressDraggable(
        dragAnchorStrategy: pointerDragAnchorStrategy,
        child: tile,
        feedback: LimitedBox(
          child: Card(child: tile),
          maxHeight: 100,
          maxWidth: 200,
        ),
      ));
    }

    for (var link in fsCon.links) {
      var tile = ListTile(
        leading: Icon(Icons.link),
        title: Text(p.basename(link.path)),
      );

      list.add(
        LongPressDraggable(
          dragAnchorStrategy: pointerDragAnchorStrategy,
          child: tile,
          feedback: LimitedBox(
            child: Card(child: tile),
            maxHeight: 100,
            maxWidth: 200,
          ),
        ),
      );
    }

    return list;
  }
}
