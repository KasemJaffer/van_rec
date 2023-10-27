import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:importer/data/data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:van_rec/data/repo/event_repository.dart';
import 'package:van_rec/shared/extensions.dart';
import 'package:van_rec/shared/providers/theme.dart';
import 'package:van_rec/shared/views/adaptive_popup.dart';
import 'package:van_rec/shared/views/dialogs.dart';
import 'package:van_rec/ui/vm/details_dialog_vm.dart';

final _formatFull = DateFormat("EEE, MMM d, h:mm a");
final _formatTimeOnly = DateFormat("h:mm a");

class DetailsDialog extends StatefulWidget {
  final MyEvent? event;
  final DateTime? start;
  final DateTime? end;
  final int? id;

  const DetailsDialog({
    super.key,
    this.start,
    this.end,
    this.id,
    this.event,
  });

  @override
  State<DetailsDialog> createState() => DetailsDialogState();
}

class DetailsDialogState extends State<DetailsDialog>
    with TickerProviderStateMixin {
  late final _floatingButtonAnimCont = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final _viewModel =
      DetailsDialogVM(context.read<EventRepository>(), widget.event);
  late final _popupController = context.read<PopupController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.event != null) {
        // Build the title and floating action button which exists in the parent widget
        _popupController.update(
          title: Text(_viewModel.event?.title ?? ""),
          floatingButton: _buildFloatingActionButton(),
        );
      } else if (widget.id != null &&
          widget.start != null &&
          widget.end != null) {
        _viewModel.fetchEvent(
          id: widget.id!,
          start: widget.start!,
          end: widget.end!,
        );
      }
    });

    _viewModel.addListener(() {
      // Build the title and floating action button which exists in the parent widget
      _popupController.update(
        title: Text(_viewModel.event?.title ?? ""),
        floatingButton: _buildFloatingActionButton(),
      );
    });
  }

  @override
  void dispose() {
    _floatingButtonAnimCont.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final event = _viewModel.event;
        if (_viewModel.loading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Table(
                columnWidths: const {0: FixedColumnWidth(82)},
                border: TableBorder.all(color: context.colors.primary),
                children: [
                  TableRow(
                    children: [
                      _buildTitleCell("Title"),
                      _buildValueCell(event?.title ?? ""),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildTitleCell("Activity"),
                      _buildValueCell(event?.activityName ?? ""),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildTitleCell("Location"),
                      _buildValueCell(event?.centerName ?? ""),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildTitleCell("Time"),
                      _buildValueCell(event == null
                          ? ""
                          : "${_formatFull.format(event.start)} "
                              "- ${_formatTimeOnly.format(event.end)}${event.allDay ? " (all day)" : ""}"),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              Text("Description", style: context.theme.textTheme.titleLarge),
              Divider(color: context.colors.primary),
              Html(
                data: event?.description ?? "",
                onLinkTap: (link, _, __) {
                  if (link != null) {
                    launchUrl(Uri.parse(link));
                  }
                },
                style: {
                  "*": Style(color: context.colors.onSurface),
                  "a":
                      Style(color: ThemeProvider.of(context).custom(linkColor)),
                  "a *":
                      Style(color: ThemeProvider.of(context).custom(linkColor)),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  TableCell _buildValueCell(String value) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SelectableText(value),
      ),
    );
  }

  TableCell _buildTitleCell(String title) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          title,
          style: context.theme.textTheme.titleMedium!,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_viewModel.loading) return null;
    if (!kIsWeb) {
      return FloatingActionButton(
        tooltip: "Share",
        onPressed: () => Dialogs.share(
          context,
          subLoc: GoRouterState.of(context).uri.toString(),
          event: _viewModel.event,
        ),
        child: Icon(
          defaultTargetPlatform == TargetPlatform.iOS
              ? CupertinoIcons.share
              : Icons.share,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final target in ShareTarget.values)
          AnimatedBuilder(
              animation: _floatingButtonAnimCont,
              builder: (context, child) {
                final anim = CurvedAnimation(
                  parent: _floatingButtonAnimCont,
                  curve: Interval(
                    0.0,
                    1.0 - target.index / ShareTarget.values.length / 2.0,
                    curve: Curves.ease,
                  ),
                );
                return Opacity(
                  opacity: CurvedAnimation(
                    parent: _floatingButtonAnimCont,
                    curve: Interval(
                      0.0,
                      1.0 - target.index / ShareTarget.values.length / 2.0,
                      curve: Curves.easeOut,
                    ),
                  ).value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 40,
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        onPressed: () {
                          _floatingButtonAnimCont.reverse();
                          Dialogs.share(
                            context,
                            subLoc: GoRouterState.of(context).uri.toString(),
                            event: _viewModel.event,
                            target: target,
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FractionalTranslation(
                              translation: Tween<Offset>(
                                begin: const Offset(0.5, 0.0),
                                end: Offset.zero,
                              ).animate(anim).value,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: context.colors.secondaryContainer,
                                  borderRadius:
                                      const BorderRadiusDirectional.only(
                                    topStart: Radius.circular(12),
                                    bottomStart: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  target.title,
                                  style: TextStyle(
                                    color: context.colors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: anim.value,
                              child: Container(
                                alignment: Alignment.center,
                                color: context.colors.secondaryContainer,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(target.icon, color: target.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        FloatingActionButton(
          heroTag: null,
          elevation: 0,
          tooltip: "Share",
          child: AnimatedBuilder(
            animation: _floatingButtonAnimCont,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.rotationZ(_floatingButtonAnimCont.value * 0.5 * pi),
                alignment: FractionalOffset.center,
                child:
                    Icon(_floatingButtonAnimCont.isDismissed ? Icons.share : Icons.close),
              );
            },
          ),
          onPressed: () {
            if (_floatingButtonAnimCont.isDismissed) {
              _floatingButtonAnimCont.forward();
            } else {
              _floatingButtonAnimCont.reverse();
            }
          },
        ),
      ],
    );
  }
}
