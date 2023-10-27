import 'package:flutter/cupertino.dart';
import 'package:importer/data/data.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:van_rec/shared/providers/providers.dart';
import 'package:van_rec/shared/views/adaptive_popup.dart';

import 'ui/view/details/details_dialog.dart';
import 'ui/view/home/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

List<NavigationDestination>? destinations;

class NavigationDestination {
  const NavigationDestination({
    required this.route,
    required this.label,
    required this.icon,
    this.child,
  });

  final String route;
  final String label;
  final Icon icon;
  final Widget? child;
}

class AppRouter {
  late final AppState appState;

  GoRouter get router => _appRouter;

  AppRouter(this.appState);

  late final _appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: appState,
    initialLocation: Uri(
      path: AppPage.home.path,
      queryParameters: {
        'a': '20', // default activity id
        'd': kDateFormat.format(DateTime.now()),
      },
    ).toString(),
    routes: [
      GoRoute(
        path: AppPage.home.path,
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final aId = params["a"];
          final cId = params["c"];

          DateTime? date;
          try {
            final d = params["d"];
            date = d != null ? kDateFormat.parse(d) : null;
          } catch (e) {
            debugPrint(e.toString());
          }

          return HomeScreen(
            activityId: aId != null ? int.tryParse(aId) : null,
            centerId: cId != null ? int.tryParse(cId) : null,
            query: params["q"],
            date: date,
          );
        },
        routes: [
          GoRoute(
            // Event details
            path: "${AppPage.event.name}/:id/:start/:end",
            pageBuilder: (context, state) {
              final event = state.extra as MyEvent?;
              int? id;
              DateTime? start;
              DateTime? end;
              try {
                id = int.parse(state.pathParameters['id']!);
                start = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(state.pathParameters['start']!) * 1000);
                end = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(state.pathParameters['end']!) * 1000);
              } catch (e) {
                // ignored
              }
              return AdaptivePopup.buildPage(
                child: DetailsDialog(
                  event: event,
                  id: id,
                  start: start,
                  end: end,
                ),
                title: Text(event?.title ?? ""),
              );
            },
          ),
        ],
      ),
    ],
  );
}
