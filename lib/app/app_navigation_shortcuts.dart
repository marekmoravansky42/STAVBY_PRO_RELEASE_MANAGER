import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide navigation, independent of the currently focused non-text control.
class AppNavigationShortcuts extends StatefulWidget {
  const AppNavigationShortcuts({
    super.key,
    required this.onSelectPage,
    required this.child,
  });

  final ValueChanged<int> onSelectPage;
  final Widget child;

  @override
  State<AppNavigationShortcuts> createState() => _AppNavigationShortcutsState();
}

class _AppNavigationShortcutsState extends State<AppNavigationShortcuts> {
  static const _digits = <PhysicalKeyboardKey>[
    PhysicalKeyboardKey.digit1,
    PhysicalKeyboardKey.digit2,
    PhysicalKeyboardKey.digit3,
    PhysicalKeyboardKey.digit4,
    PhysicalKeyboardKey.digit5,
    PhysicalKeyboardKey.digit6,
    PhysicalKeyboardKey.digit7,
    PhysicalKeyboardKey.digit8,
    PhysicalKeyboardKey.digit9,
  ];

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKeyEvent);
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (!mounted ||
        event is! KeyDownEvent ||
        event.synthesized ||
        !keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isShiftPressed ||
        keyboard.isMetaPressed ||
        ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }

    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext != null &&
        (focusContext.widget is EditableText ||
            focusContext.findAncestorWidgetOfExactType<EditableText>() !=
                null)) {
      return KeyEventResult.ignored;
    }

    // Physical keys also cover the Slovak top row (e.g. +, ľ, š instead of 1–9).
    final index = _digits.indexOf(event.physicalKey);
    if (index < 0) return KeyEventResult.ignored;
    widget.onSelectPage(index);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
