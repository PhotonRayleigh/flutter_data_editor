import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:spark_lib/app/app_system_manager.dart';

/*
    AppSystemManager class:
    This class provides top level control of the application
    as well as the ability to respond to system events.

    I suppose this is also a good place to run tasks not dependent
    on the UI loop, such as listening services.

    Later, I should probably implement ChangeNotifier to propagate
    changes to the UI tree in response to external events.

    I think this widget is similar to my Main node that I typically
    use in Godot applications.
*/

late final _AppManagerState appManager;

class AppManager extends AppSystemManager {
  AppManager({Key? key, required Widget child}) : super(key: key, child: child);

  @override
  _AppManagerState createState() {
    return _AppManagerState();
  }
}

class _AppManagerState extends AppSystemManagerState {
  _AppManagerState() : super() {
    appManager = this;
  }

  @override
  void initState() {
    super.initState();
    // call super init first
  }

  @override
  void dispose() {
    // call super dispose last
    super.dispose();
  }
}

// class AppSystemManager extends StatefulWidget {
//   final Widget child;
//   AppSystemManager({Key? key, required this.child}) : super(key: key);
//   @override
//   _AppSystemManagerState createState() => _AppSystemManagerState();
// }

// class _AppSystemManagerState extends State<AppSystemManager>
//     with WidgetsBindingObserver {
//   _AppSystemManagerState() {
//     if (_managerSet)
//       throw Exception(
//           "Error: Apps can only have one AppSystemManager instanced");
//     appManager = this;
//   }

//   @override
//   initState() {
//     // Use init state for system initialization tasks, I think
//     super.initState();
//     WidgetsFlutterBinding.ensureInitialized();
//     WidgetsBinding.instance!.addObserver(this);
//   }

//   @override
//   void dispose() {
//     // Clean up operations can go in the dispose section
//     WidgetsBinding.instance!.removeObserver(this);
//     super
//         .dispose(); // Remember super.dispose always comes last in dispose methods.
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     // The cases provided by Flutter don't cover all system possibilities.
//     // For example, if the app is terminated, I might need to write some
//     // finalizing code in Kotlin for Android, and might need something special
//     // in Swift for iOS.
//     switch (state) {
//       case AppLifecycleState.inactive:
//         print('inactive');
//         break;
//       case AppLifecycleState.paused:
//         print('paused');
//         break;
//       case AppLifecycleState.resumed:
//         print('resumed');
//         break;
//       case AppLifecycleState.detached:
//         print('detached');
//         break;
//       default:
//     }
//   }

//   @override
//   void didChangeMetrics() {
//     super.didChangeMetrics();

//     // print('rotated');
//     // This actually gets called every time the view is resized.
//     // There are other ways to handle screen size changes, which may be better suited
//     // than using this callback.
//   }

//   @override
//   void didHaveMemoryPressure() {
//     super.didHaveMemoryPressure();

//     print('low memory');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
