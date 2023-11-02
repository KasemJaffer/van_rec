import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../extensions.dart';

const double kPopupToFullScreenBreakpoint = 730.0;

/// A class for displaying adaptive popups in Flutter applications.
class AdaptivePopup {
  /// Shows a popup dialog with adaptive behavior based on the screen size.
  ///
  /// * [context]: The [BuildContext] to show the popup within.
  /// * [child]: The content of the popup.
  /// * [title]: An optional title widget for the popup.
  /// * [floatingActionButton]: An optional floating action button for the popup.
  /// * [widthBreakPoint]: The width breakpoint at which the popup becomes fullscreen.
  /// * [heightBreakPoint]: The height breakpoint at which the popup becomes fullscreen.
  static Future show(
    BuildContext context, {
    required Widget child,
    Widget? title,
    Widget? floatingActionButton,
    double widthBreakPoint = kPopupToFullScreenBreakpoint,
    double heightBreakPoint = kPopupToFullScreenBreakpoint,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      transitionBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.easeIn.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, -curvedValue * 200, 0.0),
          child: Opacity(opacity: a1.value, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, a1, a2) => ChangeNotifierProvider<PopupController>(
        create: (_) => PopupController(
          title: title,
          floatingActionButton: floatingActionButton,
          widthBreakPoint: widthBreakPoint,
          heightBreakPoint: heightBreakPoint,
        ),
        child: PopupWrapper(child, autoDismissOnBack: true),
      ),
    );
  }

  /// Builds a custom [CustomTransitionPage] for displaying an adaptive popup.
  ///
  /// [child]: The content of the popup.
  /// [title]: An optional title widget for the popup.
  /// [floatingActionButton]: An optional floating action button for the popup.
  /// [widthBreakPoint]: The width breakpoint at which the popup becomes fullscreen.
  /// [heightBreakPoint]: The height breakpoint at which the popup becomes fullscreen.
  static CustomTransitionPage buildPage({
    required Widget child,
    Widget? title,
    Widget? floatingActionButton,
    double widthBreakPoint = kPopupToFullScreenBreakpoint,
    double heightBreakPoint = kPopupToFullScreenBreakpoint,
  }) {
    return CustomTransitionPage(
      barrierColor: Colors.black54,
      opaque: false,
      barrierDismissible: true,
      fullscreenDialog: true,
      barrierLabel: 'Background barrier',
      child: ChangeNotifierProvider<PopupController>(
        create: (_) => PopupController(
          title: title,
          floatingActionButton: floatingActionButton,
          widthBreakPoint: widthBreakPoint,
          heightBreakPoint: heightBreakPoint,
        ),
        child: PopupWrapper(child),
      ),
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.easeIn.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, -curvedValue * 200, 0.0),
          child: Opacity(opacity: a1.value, child: child),
        );
      },
    );
  }
}

/// A widget for wrapping the content of an adaptive popup.
class PopupWrapper extends StatefulWidget {
  final bool autoDismissOnBack;
  final Widget child;

  const PopupWrapper(this.child, {super.key, this.autoDismissOnBack = false});

  @override
  State<StatefulWidget> createState() => PopupWrapperState();
}

class PopupWrapperState extends State<PopupWrapper> {
  late final String _parentLocation;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    if (widget.autoDismissOnBack) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _router = GoRouter.of(context);
        _parentLocation = GoRouterState.of(context).uri.toString();
        _router.routerDelegate.addListener(_onChange);
      });
    }
  }

  void _onChange() {
    // Handles changes in the router and dismisses the popup if needed.
    final location = GoRouterState.of(context).uri.toString();
    if (_parentLocation != location) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  @override
  void dispose() {
    if (widget.autoDismissOnBack) {
      _router.routerDelegate.removeListener(_onChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PopupController>();
    final query = MediaQuery.of(context);
    final size = query.size;
    final showingAsPopup = size.width > controller.widthBreakPoint;

    return showingAsPopup
        ? Dialog(
            child: Stack(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: controller.widthBreakPoint,
                    maxHeight: controller.heightBreakPoint,
                  ),
                  margin: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    top: 32,
                    bottom: 76,
                  ),
                  child: CustomScrollView(
                    primary: false,
                    shrinkWrap: true,
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        primary: false,
                        pinned: true,
                        elevation: 0,
                        title: Consumer<PopupController>(
                          builder: (_, t, __) {
                            return t.title ?? const SizedBox();
                          },
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(child: widget.child),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: Consumer<PopupController>(
                    builder: (_, t, __) {
                      return t.floatingActionButton ?? const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              actions: const [CloseButton()],
              title: Consumer<PopupController>(
                builder: (_, t, __) {
                  return t.title ?? const SizedBox();
                },
              ),
            ),
            body: SafeArea(
              child: Theme(
                data: context.theme.copyWith(
                  dialogBackgroundColor: context.colors.surface,
                ),
                child: widget.child,
              ),
            ),
            floatingActionButton: Consumer<PopupController>(
              builder: (_, t, __) {
                return t.floatingActionButton ?? const SizedBox();
              },
            ),
          );
  }
}

/// A controller class for managing the title and floating action button of a popup.
class PopupController extends ChangeNotifier {
  Widget? _title;
  Widget? _floatingActionButton;
  final double widthBreakPoint;
  final double heightBreakPoint;

  Widget? get title => _title;

  Widget? get floatingActionButton => _floatingActionButton;

  void update({Widget? title, Widget? floatingButton}) {
    _title = title;
    _floatingActionButton = floatingButton;
    notifyListeners();
  }

  PopupController({
    required this.widthBreakPoint,
    required this.heightBreakPoint,
    Widget? title,
    Widget? floatingActionButton,
  })  : _title = title,
        _floatingActionButton = floatingActionButton;
}
