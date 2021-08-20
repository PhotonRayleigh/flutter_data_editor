import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:tuple/tuple.dart';

typedef SubDir = Tuple3<List<FsListObject<Directory>>, List<FsListObject<File>>,
    List<FsListObject<Link>>>;

class FsController extends GetxController {
  late Future init;
  String home = "";
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

  FsController({this.scaffoldKey, required this.fileBrowserRefresh});

  @override
  void onInit() async {
    super.onInit();
    await initDirs();
  }

  Future initDirs() async {
    var completer = Completer();
    init = completer.future;
    var env = Platform.environment;
    String? temp;
    if (Platform.isLinux || Platform.isMacOS)
      temp = env['HOME'];
    else if (Platform.isWindows)
      temp = env['UserProfile'];
    else if (Platform.isAndroid) {
      /*
        IMPORTANT: Android will not show what files are in the filesystem
        without the filesystem permission, which has to be explicitly granted.
        I'll have to figure that out...

        Storage on Android is funky.
        There are a bunch of directories you can't access because the environment
        is sandboxed. In general, each app can only access files located in
        the main system storage (/storage/emulated/0), attached storage devices
        (i.e. sd cards), and your app's system-provided storage 
        (/data/user/0/{your org name}/{your app's name}). You can read some select other
        directories, like system and mnt. 

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

        But where is my dedicated storage for this app specifically?

        getApplicationDocumentsDirectory() and getApplicationSupportDirectory();
        both point to the same location on Android and Windows.
        /data/user/0/com.example.data_editor/app_flutter for Android,
        and Documents for Windows.

        On Android, Directory.systemTemp points to the same directory as well.
        On Windows, it points to the AppData\local\temp directory.
       */
      // Will use this as the standard to get the home directory on Android.
      // However, I will need to add quick access to the standard Android dirs.
      var docDir = await getApplicationDocumentsDirectory();
      temp = docDir.path;
    }
    home = temp ?? Directory.systemTemp.path;
    print(home);
    completer.complete();
  }

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

  FsListObject(this.entity);
}
