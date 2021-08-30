import 'dart:async';
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
// - Implement popup menu buttons - DONE
// - Fix UI layout overflows - DONE
// - Implement displaying FileStat information
// - Implement application settings saving
// - Saved favorite directories
// - Prevent UI hanging when loading new directories (DONE, does not happen in release)
//    - Queue load of files
//    - Use a callback to tell the UI to update after its done
//    - Potentially delegate the work to an isolate

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
      entityType key;
      if (item is FsListObject<Directory>)
        key = entityType.directory;
      else if (item is FsListObject<File>)
        key = entityType.file;
      else
        key = entityType.link;

      Widget leadChild;
      switch (key) {
        case entityType.directory:
        case entityType.link:
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
              if (key == entityType.directory) Icon(Icons.folder),
              if (key == entityType.link) Icon(Icons.link),
            ],
          );
          break;
        default:
          leadChild = Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.file_present));
          break;
      }

      var lead = FittedBox(
        fit: BoxFit.cover,
        child: leadChild,
      );

      // void Function()? doubleTap;

      void Function()? followPath;
      void Function()? singleTap;

      switch (key) {
        case entityType.file:
          singleTap = () {
            Future.microtask(() => fsCon.setSelectionAll(false))
                .whenComplete(() {
              item.selected = true;
              fsCon.setFocusedItem(item);
              flagUpdate();
            });
            return;
          };
          break;
        default:
          switch (key) {
            case entityType.directory:
              followPath = () {
                fsCon.setLocation(item.entity.path).whenComplete(flagUpdate);
              };
              break;
            case entityType.link:
              followPath = () async {
                fsCon
                    .setLocation(await item.entity.resolveSymbolicLinks())
                    .whenComplete(flagUpdate);
              };
              break;
            default:
          }

          singleTap = () {
            if (tapWatch.isRunning) {
              if (tapWatch.elapsedMilliseconds < 300) {
                // followPath will only be null for files.
                // In which case, followPath will never be called.
                followPath!();
                tapWatch.stop();
                return;
              }
              tapWatch.stop();
              tapWatch.reset();
            }

            tapWatch.reset();
            tapWatch.start();
            watchTimer = Timer(Duration(milliseconds: 320), () {
              tapWatch.stop();
              tapWatch.reset();
            });

            Future.microtask(() => fsCon.setSelectionAll(false))
                .whenComplete(() {
              item.selected = true;
              fsCon.setFocusedItem(item);
              flagUpdate();
            });
            return;
          };
          break;
      }

      void Function(String)? contextMenu = (value) async {
        switch (value) {
          case 'fileStat':
            FileStat.stat(item.entity.path).then((stat) {
              var statMsg = stat.toString();
              Future.microtask(() => print(stat.toString()));
              Get.defaultDialog(
                actions: [
                  TextButton(onPressed: () => Get.back(), child: Text("Ok"))
                ],
                title: "FileStat",
                content: Text(
                  statMsg,
                  textAlign: TextAlign.left,
                ),
              );
            });
            break;
          case 'addFav':
            fsCon.addFavorite(item.entity.path);
            break;
          case 'removeFav':
            fsCon.removeFavorite(item.entity.path);
            break;
        }
      };

      var moreButton = PopupMenuButton<String>(
        itemBuilder: (context) {
          late PopupMenuItem<String> addFavorite;
          if (fsCon.favPaths.contains(item.entity.path)) {
            addFavorite = PopupMenuItem(
                child: Text("Remove Favorite"), value: 'removeFav');
          } else {
            addFavorite =
                PopupMenuItem(child: Text("Add Favorite"), value: 'addFav');
          }

          return <PopupMenuEntry<String>>[
            PopupMenuItem(
              child: Text("File Stat"),
              value: "fileStat",
            ),
            addFavorite,
          ];
        },
        icon: Icon(Icons.more_vert),
        onSelected: contextMenu,
      );

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
              moreButton,
            ],
          ));

      // Using double tap with a GestureDetector in addition to onTap
      // causes the detector to wait the double tap time before responding
      // to a single tap event.
      // This causes noticeable delays when selecting items.
      var title = GestureDetector(
        child: ListTile(
          leading: lead,
          title: Text(p.basename(item.entity.path)),
          selected: item.selected,
          trailing: listTileTrailing,
          onTap: singleTap,
        ),
        // TODO: Add right click support with secondaryTap.
        // onDoubleTap: doubleTap,
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
    }
    // ---- END BUILD TILE -----

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

  final Stopwatch tapWatch = Stopwatch();
  Timer? watchTimer;
}

enum entityType { directory, file, link }
