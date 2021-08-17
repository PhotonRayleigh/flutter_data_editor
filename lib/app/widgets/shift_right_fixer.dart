import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

// Fix for bug where right shift button acts like caps lock.
// Issue and solution described here: https://github.com/flutter/flutter/issues/75675
class ShiftRightFixer extends StatefulWidget {
  ShiftRightFixer({required this.child});
  final Widget child;
  @override
  State<StatefulWidget> createState() => _ShiftRightFixerState();
}

class _ShiftRightFixerState extends State<ShiftRightFixer> {
  final FocusNode focus =
      FocusNode(skipTraversal: true, canRequestFocus: false);
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focus,
      onKey: (_, RawKeyEvent event) {
        return event.physicalKey == PhysicalKeyboardKey.shiftRight
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
