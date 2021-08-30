import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as p;

typedef SubDir = Tuple3<List<FsListObject<Directory>>, List<FsListObject<File>>,
    List<FsListObject<Link>>>;

class FsController extends GetxController {
  late Future init;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String home = "";
  String systemRoot = "";
  GlobalKey? scaffoldKey;

  var _currentPath = "";
  set currentPath(String val) {
    _currentPath = val;
    _currentDir = Directory(_currentPath);
  }

  String get currentPath => _currentPath;

  late Directory _currentDir;
  Directory get currentDir => _currentDir;

  var dirs = <FsListObject<Directory>>[];
  var files = <FsListObject<File>>[];
  var links = <FsListObject<Link>>[];
  var expandedDirs = <
      String,
      Tuple3<List<FsListObject<Directory>>, List<FsListObject<File>>,
          List<FsListObject<Link>>>>{};

  Queue<String> backHistory = Queue<String>();
  Queue<String> forwardHistory = Queue<String>();
  int historyLength = 50;

  Function fileBrowserRefresh;

  FsListObject<FileSystemEntity>? focusItem;

  FsController({this.scaffoldKey, required this.fileBrowserRefresh});

  // Quick navigation variables
  List<String> systemPaths = <String>[];
  Set<String> favPaths = <String>{};
  // End quick nav variables

  @override
  void onInit() async {
    super.onInit();
    await initDirs();
    await _readPrefs();
  }

  @override
  void onClose() {
    super.onClose();
    _savePrefs();
  }

  Future _readPrefs() async {
    var prefs = await _prefs;
    if (prefs.containsKey('fsFavorites')) {
      var savedPaths = (await _prefs).getStringList('fsFavorites');
      favPaths = savedPaths!.toSet();
    }
  }

  Future _savePrefs() async {
    var prefs = await _prefs;

    prefs.setStringList('fsFavorites', favPaths.toList());
  }

  Future initDirs() async {
    /* 
        The main directories we need to be aware of for every platform are:
        - Home
        - App data
        - General documents storage
        - Drive root(s)

        The rest are system specific

        Android:
          Android has private and public directories.
          Android gives each app a sandboxed directory in:
            /data/user/0/{org name}.{app name}
          Flutter points to ./app_flutter in that dir for docs
          and points to ./files for support.
          
          Android's public file storage is under /storage/emulated/0.
          You need explicit filesystem permissions granted to access it.
          This directory contains general folders for shared stuff.
          Then application specific folders under ./Android/data,
          named similarly to the private location as ./{org name}.{app name}/files

        Windows:
          Windows is easy. Home is the user's profile directory.
          App data goes in home/AppData/Roaming/{org name}/{app name}
          You can also freely access the various system directories 
          and standard directories under home. System directories cannot be
          edited without admin permissions, however. 

          Windows can also have multiple drives attached to the system, which
          can be similarly browsed and should be detected on startup.
    */

    // Depending on our system, we will build up the list of core directories
    // here, followed by any the user has saved.
    var completer = Completer();
    init = completer.future;
    var env = Platform.environment;
    String? temp;
    if (Platform.isLinux || Platform.isMacOS) {
      var dirFutures = <Future<Directory?>>[];
      dirFutures.add(getApplicationDocumentsDirectory());
      dirFutures.add(getApplicationSupportDirectory());
      dirFutures.add(getDownloadsDirectory());
      dirFutures.add(getTemporaryDirectory());

      home = env['HOME'] ?? "";
      systemRoot = "/";

      var dirs = await Future.wait(dirFutures);

      for (var dir in dirs) {
        systemPaths.add(dir!.path);
      }
    } else if (Platform.isWindows) {
      var dirFutures = <Future<Directory?>>[];
      dirFutures.add(getApplicationDocumentsDirectory());
      dirFutures.add(getApplicationSupportDirectory());
      dirFutures.add(getDownloadsDirectory());
      dirFutures.add(getTemporaryDirectory());

      home = env['UserProfile'] ?? "";
      systemRoot = env['SYSTEMDRIVE'] ?? "";
      systemRoot = systemRoot + p.separator;

      var dirs = await Future.wait(dirFutures);
      var programFiles = env['PROGRAMFILES'];
      var programFilesx86 = env['PROGRAMFILES(X86)'];
      if (programFiles != null) systemPaths.add(programFiles);
      if (programFilesx86 != null) systemPaths.add(programFilesx86);

      systemPaths.add(p.join(home, 'Desktop'));
      systemPaths.add(dirs[0]!.path);
      systemPaths.add(dirs[2]!.path);
      systemPaths.add(p.join(home, 'Pictures'));
      systemPaths.add(dirs[1]!.path);
      systemPaths.add(dirs[3]!.path);
    } else if (Platform.isAndroid) {
      /*
        IMPORTANT: Android will not show what files are in the filesystem
        without the filesystem permission, which has to be explicitly granted.

        Here's some important ones:
        Locked directories:
          /storage
          /data
          /apex?
        
        Others:
          /mnt
          /sdcard
          /data/cache
          /system
          /storage/emulated/0 -- this is the main system storage
          /user/0/com.example.data_editor -- Temp directory for this app
       */

      // This is far from clean at the moment, but it's a start.
      var dirFutures = <Future<Directory?>>[];
      dirFutures.add(getApplicationDocumentsDirectory());
      dirFutures.add(getApplicationSupportDirectory());
      // dirFutures.add(getDownloadsDirectory()); // Doesn't work on Android
      dirFutures.add(getTemporaryDirectory());

      var dirsFutures = <Future<List<Directory>?>>[];
      dirsFutures.add(getExternalCacheDirectories());
      dirsFutures.add(getExternalStorageDirectories());

      var dirs = await Future.wait(dirFutures);
      var dirLists = await Future.wait(dirsFutures);

      home = dirs[0]!.path;
      systemRoot = '/';

      for (var dir in dirs) {
        systemPaths.add(dir!.path);
      }
      for (var list in dirLists) {
        for (var dir in list!) {
          systemPaths.add(dir.path);
        }
      }

      systemPaths.add(p.join(p.separator, "storage", "emulated", "0"));
      systemPaths.add(p.join(p.separator, "mnt"));
      systemPaths.add(p.join(p.separator, "system"));
    } else if (Platform.isIOS) {
      var dirFutures = <Future<Directory?>>[];
      dirFutures.add(getApplicationDocumentsDirectory());
      dirFutures.add(getApplicationSupportDirectory());
      dirFutures.add(getDownloadsDirectory());
      dirFutures.add(getTemporaryDirectory());

      systemRoot = "";

      var dirs = await Future.wait(dirFutures);

      home = dirs[0]!.path;

      for (var dir in dirs) {
        systemPaths.add(dir!.path);
      }
    }
    // home = temp ?? Directory.systemTemp.path;
    print(home);
    completer.complete();
  }

// Start directory navigation and inspection

  Future<ScanStatus> scanDir(
      {String? path, bool clear = true, String? subDirPath}) async {
    await init;

    // Working lists
    List<FsListObject<Directory>> workingDirs;
    List<FsListObject<File>> workingFiles;
    List<FsListObject<Link>> workingLinks;

    if (subDirPath != null) {
      workingDirs = expandedDirs[subDirPath]!.item1;
      workingFiles = expandedDirs[subDirPath]!.item2;
      workingLinks = expandedDirs[subDirPath]!.item3;
    } else {
      workingDirs = dirs;
      workingFiles = files;
      workingLinks = links;
    }

    if (clear) {
      workingDirs.clear();
      workingFiles.clear();
      workingLinks.clear();
    }

    // uses existing currentPath by default, but can be overriden for
    // no good reason.
    if (path != null) {
      currentPath = path;
    }

    Directory workingDir;
    if (subDirPath != null) {
      workingDir = Directory(subDirPath);
    } else {
      workingDir = currentDir;
    }

    // Test if directory exists first
    try {
      if (!(await workingDir.exists())) {
        printSnackBar(SnackBar(content: Text("Invalid path: Does not exist.")));
        print("Invalid path: Does not exist.");
        return ScanStatus.dirNoExist;
      }
    } catch (e) {
      printSnackBar(
        SnackBar(
          content: Text("Error: caught exception checking currentDir."),
          action: SnackBarAction(
              label: "show",
              onPressed: () {
                Get.defaultDialog(
                    title: "Exception Text", middleText: e.toString());
              }),
        ),
      );
      print("Error: caught exception checking currentDir.");
      print(e.toString());
    }

    // Get/update list of filesystem entities
    try {
      // If clear is set, we just rebuild the lists from scratch.
      // No state checks necessary.
      if (clear) {
        await for (var entity
            in workingDir.list(recursive: false, followLinks: false)) {
          if (entity is Directory)
            workingDirs.add(FsListObject(entity));
          else if (entity is File)
            workingFiles.add(FsListObject(entity));
          else if (entity is Link) workingLinks.add(FsListObject(entity));
        }
      } else {
        // Get new list for directory.
        var directoryList = await workingDir
            .list(recursive: false, followLinks: false)
            .toList();

        // Every file that we already have, don't touch.
        // If a file is missing, remove it.
        // If a file is listed that we don't have, add it.

        // Add new and check for cached first
        for (var entity in directoryList) {
          if (entity is Directory) {
            if (workingDirs
                .any((element) => element.entity.path == entity.path)) {
              // skip
            } else
              workingDirs.add(FsListObject(entity));
          } else if (entity is File) {
            if (workingFiles
                .any((element) => element.entity.path == entity.path)) {
              // skip
            } else
              workingFiles.add(FsListObject(entity));
          } else if (entity is Link) {
            if (workingLinks
                .any((element) => element.entity.path == entity.path)) {
              // skip
            } else
              workingLinks.add(FsListObject(entity));
          }
        }

        // Second, remove missing
        for (var dir in workingDirs) {
          if (directoryList.any((element) => element.path == dir.entity.path)) {
            // Do nothing, we found it
          } else
            workingDirs.remove(dir);
        }
        for (var file in workingFiles) {
          if (directoryList
              .any((element) => element.path == file.entity.path)) {
            // Do nothing, we found it
          } else
            workingFiles.remove(file);
        }
        for (var link in workingLinks) {
          if (directoryList
              .any((element) => element.path == link.entity.path)) {
            // Do nothing, we found it
          } else
            workingLinks.remove(link);
        }
      }
    } catch (e) {
      printSnackBar(
        SnackBar(
          content: Text("Error reading directory: permission denied"),
          action: SnackBarAction(
              label: "show",
              onPressed: () {
                Get.defaultDialog(
                    title: "Exception Text", middleText: e.toString());
              }),
        ),
      );
      print("Error reading directory: permission denied");
      print("Exception text: ${e.toString()}");
      return ScanStatus.permissionDenied;
    }

    return ScanStatus.success;
  }

  Future setLocation(String path) async {
    // Don't add to backHistory if navigating to the same directory as current
    if (backHistory.length == 0 || path != currentDir.path)
      backHistory.addLast(currentDir.path);

    if (backHistory.length > historyLength) backHistory.removeFirst();
    currentPath = path;
    forwardHistory.clear();
    expandedDirs.clear();
    await scanDir();
  }

  Future moveUp() async {
    if (backHistory.length == 0 || currentDir.parent.path != currentDir.path)
      backHistory.addLast(currentDir.path);

    if (backHistory.length > historyLength) backHistory.removeFirst();
    currentPath = currentDir.parent.path;
    forwardHistory.clear();
    expandedDirs.clear();
    await scanDir();
  }

  Future moveBack() async {
    if (backHistory.length <= 0) return;
    forwardHistory.addLast(currentPath);
    currentPath = backHistory.removeLast();
    expandedDirs.clear();
    await scanDir();
  }

  Future moveForward() async {
    if (forwardHistory.length <= 0) return;
    backHistory.addLast(currentPath);
    currentPath = forwardHistory.removeLast();
    expandedDirs.clear();
    await scanDir();
  }

  // End directory navigation

  // Entry management

  void setSelectionAll(bool setting) {
    // var watch = Stopwatch();
    // watch.start();

    // Work on the root entries
    for (var entry in dirs) {
      entry.selected = setting;
    }
    for (var entry in files) {
      entry.selected = setting;
    }
    for (var entry in links) {
      entry.selected = setting;
    }

    // Work on all expanded directories
    expandedDirs.forEach((path, tuple) {
      for (var entry in tuple.item1) {
        entry.selected = setting;
      }
      for (var entry in tuple.item2) {
        entry.selected = setting;
      }
      for (var entry in tuple.item3) {
        entry.selected = setting;
      }
    });

    // watch.stop();
    // print("Select all time: ${watch.elapsedMicroseconds}");
  }

  void setFocusedItem(FsListObject<FileSystemEntity> item) {
    if (focusItem == null) {
      item.focus = true;
      focusItem = item;
    } else {
      focusItem!.focus = false;
      item.focus = true;
      focusItem = item;
    }
  }

  void addFavorite(String item) {
    favPaths.add(item);
    _savePrefs();
  }

  void removeFavorite(String item) {
    favPaths.remove(item);
    _savePrefs();
  }

  void clearFavorites() {
    favPaths.clear();
    _savePrefs();
  }

  // End Entry management

  void printSnackBar(SnackBar content) {
    if (scaffoldKey != null) {
      ScaffoldMessenger.of(scaffoldKey!.currentContext!).showSnackBar(content);
    } else {
      print(
          "Info: scaffoldKey not set in FsContoller and printSnackBar was called.");
    }
  }
}

enum ScanStatus { success, dirNoExist, permissionDenied }

class FsListObject<T> {
  T entity;
  bool expanded = false;
  bool selected = false;
  bool focus = false;

  FsListObject(this.entity);
}
