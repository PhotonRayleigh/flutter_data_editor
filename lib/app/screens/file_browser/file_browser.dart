import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:data_editor/app/controllers/filesystem_controller.dart';
import 'fb_nav_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

//TODOs:
// - Make file system watching sane and not crash
// - Allow for navigating between directories - DONE
// - Allow folding of scanned directories - DONE
// - URL bar - DONE
// - Quick Access - DONE, just need to finish making dir lists

/* 
    8/20/2021
    Got tree-folding working. Basic navigation is complete, but a little
    janky and disorganized. Has lots of room for improvement.
    The main issue though is that it hangs the UI when a large directory
    is loaded.

    How to solve this?
    Load directory on FsController and incrementally build as the view moves?
    Better async/await use? Do I need to use callbacks more aggressively?
    It is probably blocking on an await somewhere, but how would I fix that?
*/

class FileBrowser extends StatefulWidget {
  @override
  State<FileBrowser> createState() {
    return FileBrowserState();
  }
}

class FileBrowserState extends State<FileBrowser> {
  final fsKey = GlobalKey(debugLabel: "fsKey");
  var fileList = <Widget>[];

  late TextField urlBar;
  late TextEditingController textControl;

  FsController get fsCon {
    try {
      return Get.find<FsController>();
    } catch (e) {
      return Get.put(
          FsController(fileBrowserRefresh: flagUpdate, scaffoldKey: fsKey));
    }
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
    await fsCon.scanDir(clear: false).whenComplete(flagUpdate);
    // Get.snackbar("Refresh", "Filesystem refreshed");
    // ScaffoldMessenger.of(fsKey.currentContext!)
    //     .showSnackBar(const SnackBar(content: Text("Refresh called")));
  }

  void flagUpdate() async {
    buildFileList().then((value) => setState(() {
          fileList = value;
          textControl.text = fsCon.currentPath;
        }));
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

          if (exists == false) {
            printSnackBar(SnackBar(
              content: Text("Invalid path: Does not exist"),
            ));
            textControl.printError(info: "Invalid path: Does not exist.");
          } else {
            fsCon.setLocation(val).whenComplete(() => flagUpdate());
          }
        } catch (e) {
          // TODO: Let user access exception message by clicking on snack bar
          printSnackBar(SnackBar(
            content: Text("Error, caught exception checking currentDir."),
            action: SnackBarAction(
                label: "show",
                onPressed: () {
                  Get.defaultDialog(
                      title: "Exception Text", middleText: e.toString());
                }),
          ));
          textControl.printError(
              info: "Error, caught exception checking currentDir.");
          print("Exception message: ${e.toString()}");
        }
      },
    );

    return Scaffold(
      key: fsKey,
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

  // potential list item states:
  // Selected
  // Expanded
  Future<List<Widget>> buildFileList({String? subPath}) async {
    Widget buildTile(FsListObject<FileSystemEntity> item) {
      Widget leadChild;
      if (item is FsListObject<Directory> || item is FsListObject<Link>) {
        Widget chevron;
        if (item.expanded) {
          chevron = RotatedBox(
            child: Icon(Icons.chevron_right),
            quarterTurns: 1,
          );
        } else
          chevron = Icon(Icons.chevron_right);

        void Function() chevronTap;
        if (item is FsListObject<Directory>) {
          var path = item.entity.path;
          chevronTap = () {
            if (item.expanded) {
              item.expanded = false;
              fsCon.expandedDirs.remove(path);
              flagUpdate();
            } else {
              item.expanded = true;
              fsCon.expandedDirs[path] = SubDir(<FsListObject<Directory>>[],
                  <FsListObject<File>>[], <FsListObject<Link>>[]);
              fsCon.scanDir(subDirPath: path).whenComplete(flagUpdate);
            }
          };
        } else {
          chevronTap = () async {
            var path = await (item.entity as Link).resolveSymbolicLinks();
            if (item.expanded) {
              item.expanded = false;
              fsCon.expandedDirs.remove(path);
              flagUpdate();
            } else {
              item.expanded = true;
              fsCon.expandedDirs[path] = SubDir(<FsListObject<Directory>>[],
                  <FsListObject<File>>[], <FsListObject<Link>>[]);
              fsCon.scanDir(subDirPath: path).whenComplete(flagUpdate);
            }
          };
        }

        leadChild = Row(
          children: [
            IconButton(
              icon: chevron,
              onPressed: chevronTap,
            ),
            if (item is FsListObject<Directory>) Icon(Icons.folder),
            if (item is FsListObject<Link>) Icon(Icons.link),
          ],
        );
      } else {
        leadChild = Icon(Icons.file_present);
      }

      var lead = Container(
        width: 65,
        height: 30,
        child: leadChild,
      );

      void Function()? tapAction;
      if (item is FsListObject<Directory>) {
        tapAction = () {
          fsCon.setLocation(item.entity.path).whenComplete(flagUpdate);
        };
      } else if (item is FsListObject<File>) {
        tapAction = null;
      } else {
        tapAction = () async {
          fsCon
              .setLocation(await (item as FsListObject<Link>)
                  .entity
                  .resolveSymbolicLinks())
              .whenComplete(flagUpdate);
        };
      }

      var tile = ListTile(
        leading: lead,
        title: Text(p.basename(item.entity.path)),
        onTap: tapAction,
        selected: item.selected,
        trailing: Container(
            width: 40,
            height: 40,
            child: Row(
              children: [
                if (!item.selected)
                  IconButton(
                    icon: Icon(Icons.circle_outlined),
                    onPressed: () {
                      item.selected = true;
                      flagUpdate();
                    },
                  ),
                if (item.selected)
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, color: Colors.red),
                    onPressed: () {
                      item.selected = false;
                      flagUpdate();
                    },
                  ),
              ],
            )),
      );

      return LongPressDraggable(
        child: tile,
        feedback: LimitedBox(
          child: Card(
            child: tile,
          ),
          maxWidth: (window.physicalSize / window.devicePixelRatio).width - 40,
          maxHeight: 100,
        ),
      );
    }

    var list = <Widget>[];

    List<FsListObject<Directory>> workingDirs;
    List<FsListObject<File>> workingFiles;
    List<FsListObject<Link>> workingLinks;

    if (subPath != null) {
      workingDirs = fsCon.expandedDirs[subPath]!.item1;
      workingFiles = fsCon.expandedDirs[subPath]!.item2;
      workingLinks = fsCon.expandedDirs[subPath]!.item3;
    } else {
      workingDirs = fsCon.dirs;
      workingFiles = fsCon.files;
      workingLinks = fsCon.links;
    }

    for (var dir in workingDirs) {
      list.add(buildTile(dir));
      if (dir.expanded) {
        // Create sublist and append it
        list.add(
          Padding(
            child: Column(
              children: await buildFileList(subPath: dir.entity.path),
            ),
            padding: EdgeInsets.only(left: 20),
          ),
        );
      }
    }

    for (var file in workingFiles) {
      list.add(buildTile(file));
    }

    for (var link in workingLinks) {
      list.add(buildTile(link));
      if (link.expanded) {
        // Create sublist and append it
        list.add(
          Padding(
            child: Column(
              children: await buildFileList(
                  subPath: await link.entity.resolveSymbolicLinks()),
            ),
            padding: EdgeInsets.only(left: 20),
          ),
        );
      }
    }

    return list;
  }

  void printSnackBar(SnackBar content) {
    ScaffoldMessenger.of(fsKey.currentContext!).showSnackBar(content);
  }
}
