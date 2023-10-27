import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///common widget for handling FocusableActionDetector
///supports both mouse (hover) and keyboard (specific list of keys)
///supported keys: escape, tab, shift tab, enter, arrow up, arrow down
///simple callback functions for each of these events
class KeyboardActions extends StatelessWidget {
  final Function? onEscCallback;
  final Function? onTabCallback;
  final Function? onShiftTabCallback;
  final Function? onEnterCallback;
  final Function? onArrowUpCallback;
  final Function? onArrowDownCallback;
  final Function? onSelectAllCallback;
  final ValueChanged<bool>? onHoverCallback;
  final FocusNode? focusNode;
  final Widget child;

  const KeyboardActions({
    required this.child,
    this.onEscCallback,
    this.onTabCallback,
    this.onShiftTabCallback,
    this.onEnterCallback,
    this.onHoverCallback,
    this.onArrowUpCallback,
    this.onArrowDownCallback,
    this.onSelectAllCallback,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        focusNode: focusNode,
        actions: _initActions(),
        shortcuts: _initShortcuts(),
        onShowHoverHighlight: onHoverCallback,
        child: child,
      );

  _initShortcuts() => <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const _XIntent.esc(),
        LogicalKeySet(LogicalKeyboardKey.tab): const _XIntent.tab(),
        LogicalKeySet.fromSet(
                {LogicalKeyboardKey.tab, LogicalKeyboardKey.shift}):
            const _XIntent.shiftTab(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _XIntent.enter(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _XIntent.arrowUp(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _XIntent.arrowDown(),
        LogicalKeySet.fromSet(
                {LogicalKeyboardKey.control, LogicalKeyboardKey.keyA}):
            const _XIntent.controlA(),
        LogicalKeySet.fromSet(
                {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA}):
            const _XIntent.commandA(),
      };

  void _actionHandler(_XIntent intent) {
    switch (intent.type) {
      case _XIntentType.esc:
        onEscCallback?.call();
        break;
      case _XIntentType.tab:
        onTabCallback?.call();
        break;
      case _XIntentType.shiftTab:
        onShiftTabCallback?.call();
        break;
      case _XIntentType.enter:
        onEnterCallback?.call();
        break;
      case _XIntentType.arrowUp:
        onArrowUpCallback?.call();
        break;
      case _XIntentType.arrowDown:
        onArrowDownCallback?.call();
        break;
      case _XIntentType.commandA:
      case _XIntentType.controlA:
        onSelectAllCallback?.call();
        break;
    }
  }

  _initActions() => <Type, Action<Intent>>{
        _XIntent: CallbackAction<_XIntent>(
          onInvoke: _actionHandler,
        ),
      };
}

class _XIntent extends Intent {
  final _XIntentType type;

  const _XIntent({required this.type});

  const _XIntent.esc() : type = _XIntentType.esc;

  const _XIntent.tab() : type = _XIntentType.tab;

  const _XIntent.shiftTab() : type = _XIntentType.shiftTab;

  const _XIntent.enter() : type = _XIntentType.enter;

  const _XIntent.arrowUp() : type = _XIntentType.arrowUp;

  const _XIntent.arrowDown() : type = _XIntentType.arrowDown;

  const _XIntent.controlA() : type = _XIntentType.controlA;

  const _XIntent.commandA() : type = _XIntentType.commandA;
}

enum _XIntentType {
  esc,
  tab,
  shiftTab,
  enter,
  arrowUp,
  arrowDown,
  controlA,
  commandA,
}
