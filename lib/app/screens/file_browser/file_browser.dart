import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:data_editor/app/controllers/filesystem_controller.dart';
import 'fb_nav_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'package:get_storage/get_storage.dart';

//TODOs:
// - Make file system watching sane and not crash
// - Implement popup menu buttons - DONE
// - Fix UI layout overflows - DONE
// - Implement displaying FileStat information
// - Implement application settings saving
// - Saved favorite directories
// - Prevent UI hanging when loading new directories
//    - Queue load of files
//    - Use a callback to tell the UI to update after its done
//    - Potentially delegate the work to an isolate

/* 
    8/25/2021
    I have pop over menus, so now I need to hook up some operations to them.
    I want to make saving favorites a thing.
    I also want to be able to display filestat information.

    Beyond that, all I have left to do is improve the UI and add file operations.
    There is a lot of room for polish, but I want to just get it working at a
    basic levels.

    Very soon I want to move onto actual data editing. This will require using
    both the file browser and a new UI together. The user needs to be able
    to summon the file browser to pick or create a file, which will then
    be displayed on a separate page in an editable table.

    -- update 1:
    So, for laying out the UI, if you have something that is naturally unbounded,
    FittedBox is a life saver. It automatically sizes itself based on its contents,
    parent, and a fit mode you specify. It fixed all my UI sizing issues
    on Android and Windows.
    Padding is another simple but good Widget, just to give some margin to 
    something.
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
      print("Storage permission denied");
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
    // var watch = Stopwatch();
    // watch.start();

    buildFileList().then((value) {
      setState(() {
        fileList = value;
        textControl.text = fsCon.currentPath;

        // watch.stop();
        // print("flagUpdate total: ${watch.elapsedMicroseconds}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // fsCon.scanDir(fsCon.home);

    // double screenWidth = MediaQuery.of(context).size.width;

    // BUG: Flutter treats right-shift like Caps lock
    // Bug is known and documented here: https://github.com/flutter/flutter/issues/75675
    // Will employ temporary fix as advised
    void Function(String) urlSubmitted = (val) async {
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
    };

    urlBar = TextField(
      controller: textControl,
      maxLines: 1,
      keyboardType: TextInputType.url,
      onSubmitted: urlSubmitted,
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
    );

    var appBar = AppBar(
      title: Text("File Browser"),
      actions: [
        buildBackButton(),
        buildForwardButton(),
        buildUpButton(),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: refreshDir,
        ),
      ],
    );

    var body = Column(
      children: [
        Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Form(child: urlBar)),
        Expanded(
          child: ListView(
            children: fileList,
          ),
        ),
      ],
    );

    return Scaffold(
      key: fsKey,
      appBar: appBar,
      drawer: FbNavDrawer(fsCon),
      body: body,
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
    // var watch = Stopwatch();
    // var watchList = <Stopwatch>[];
    // watch.start();

    // Initialize working variables based on context
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

    // Breaking the tile construction logic into a separate function
    // is required for proper recursion. Also my sanity.
    Widget buildTile(FsListObject<FileSystemEntity> item) {
      // var subWatch = Stopwatch();
      // watchList.add(subWatch);
      // subWatch.start();

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
        leadChild = Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(Icons.file_present));
      }

      var lead = FittedBox(
        fit: BoxFit.cover,
        child: leadChild,
      );

      void Function()? doubleTap;
      void Function()? singleTap = () {
        Future.microtask(() => fsCon.setSelectionAll(false)).whenComplete(() {
          item.selected = true;
          fsCon.setFocusedItem(item);
          flagUpdate();
        });
      };
      if (item is FsListObject<Directory> && item.focus) {
        doubleTap = () {
          fsCon.setLocation(item.entity.path).whenComplete(flagUpdate);
        };
        // onTap = () {};
      } else if (item is FsListObject<File>) {
        doubleTap = null;
        // onTap = null;
      } else if (item is FsListObject<Link> && item.focus) {
        doubleTap = () async {
          fsCon
              .setLocation(await item.entity.resolveSymbolicLinks())
              .whenComplete(flagUpdate);
        };
        // onTap = () {};
      }

      var listTileTrailing = FittedBox(
          fit: BoxFit.cover,
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
              PopupMenuButton(
                itemBuilder: (context) {
                  return <PopupMenuEntry>[
                    PopupMenuItem(
                      child: Text("test"),
                      value: "Test",
                    ),
                  ];
                },
                icon: Icon(Icons.more_vert),
                onSelected: (item) {
                  print("Item selected: ${item.toString()}");
                },
              ),
            ],
          ));

      // WARNING! Adding a GestureDetector to the ListTile seems to cause
      // misbehavior, and makes Flutter's input handling stutter.
      // My guess is this is a specific conflict between how the ListTile handles
      // input and the GestureDetector.
      // Just overlaying a GestureDetectir did not work before.
      // var title = ListTile(
      //   leading: lead,
      //   title: Text(p.basename(item.entity.path)),
      //   // title: GestureDetector(
      //   //     onDoubleTap: tapAction,
      //   //     child: Text(p.basename(item.entity.path)),
      //   //     onTap: onTap),
      //   onTap: onTap,
      //   selected: item.selected,
      //   trailing: listTileTrailing,
      // );

      var title = GestureDetector(
        child: ListTile(
          leading: lead,
          title: Text(p.basename(item.entity.path)),
          // title: GestureDetector(
          //     onDoubleTap: tapAction,
          //     child: Text(p.basename(item.entity.path)),
          //     onTap: onTap),
          selected: item.selected,
          trailing: listTileTrailing,
        ),
        onTap: singleTap,
        onDoubleTap: doubleTap,
      );

      // subWatch.stop();

      return LongPressDraggable(
        child: title,
        feedback: LimitedBox(
          child: Card(
            child: title,
          ),
          maxWidth: (window.physicalSize / window.devicePixelRatio).width - 40,
          maxHeight: 100,
        ),
      );

      // END BUILD TILE
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

    // watch.stop();
    // double averageTime;
    // int totalTime = 0;
    // for (var w in watchList) {
    //   totalTime += w.elapsedMicroseconds;
    // }
    // averageTime = totalTime / watchList.length;
    // print("buildTile times: $totalTime total, $averageTime average");
    // print("buildFileList elapsed time: ${watch.elapsedMicroseconds}");
    return list;
  }

  void printSnackBar(SnackBar content) {
    ScaffoldMessenger.of(fsKey.currentContext!).showSnackBar(content);
  }
}
