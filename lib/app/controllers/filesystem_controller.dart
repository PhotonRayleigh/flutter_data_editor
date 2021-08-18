import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class FsController extends GetxController {
  late Future init;
  String home = "";

  var _currentPath = "";
  set currentPath(String val) {
    _currentPath = val;
    _currentDir = Directory(_currentPath);
  }

  String get currentPath => _currentPath;

  late Directory _currentDir;
  Directory get currentDir => _currentDir;

  var dirs = <Directory>[];
  var files = <File>[];
  var links = <Link>[];

  Queue<String> backHistory = Queue<String>();
  Queue<String> forwardHistory = Queue<String>();
  int historyLength = 50;

  Function fileBrowserRefresh;

  FsController({required this.fileBrowserRefresh});

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

  Future<ScanStatus> scanDir({String? path}) async {
    await init;
    dirs = <Directory>[];
    files = <File>[];
    links = <Link>[];

    // uses existing currentPath by default, but can be overriden for
    // no good reason.
    if (path != null) {
      currentPath = path;
    }
    bool exists = false;
    try {
      exists = await currentDir.exists();
    } catch (e) {
      print("Error, caught exception checking currentDir.");
      print(e.toString());
    }
    if (!exists) {
      print("Err: directory does not exist");
      return ScanStatus.dirNoExist;
    }
    try {
      await for (var entity
          in currentDir.list(recursive: false, followLinks: false)) {
        if (entity is Directory)
          dirs.add(entity);
        else if (entity is File)
          files.add(entity);
        else if (entity is Link) links.add(entity);
      }
    } catch (e) {
      // TODO: add handler for access viloations and such
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
    await scanDir();
  }

  Future moveUp() async {
    if (backHistory.length == 0 || currentDir.parent.path != currentDir.path)
      backHistory.addLast(currentDir.path);

    if (backHistory.length > historyLength) backHistory.removeFirst();
    currentPath = currentDir.parent.path;
    forwardHistory.clear();
    await scanDir();
  }

  Future moveBack() async {
    if (backHistory.length <= 0) return;
    forwardHistory.addLast(currentPath);
    currentPath = backHistory.removeLast();
    await scanDir();
  }

  Future moveForward() async {
    if (forwardHistory.length <= 0) return;
    backHistory.addLast(currentPath);
    currentPath = forwardHistory.removeLast();
    await scanDir();
  }
}

enum ScanStatus { success, dirNoExist }
