import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:importer/data/data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:van_rec/shared/extensions.dart';
import 'package:van_rec/shared/views/brightness_toggle.dart';
import 'package:van_rec/shared/views/dialogs.dart';
import 'package:van_rec/ui/vm/home_screen_vm.dart';
import 'package:van_rec/shared/providers/providers.dart';

class HomeScreen extends StatefulWidget {
  final int? activityId;
  final int? centerId;
  final String? query;
  final DateTime? date;

  const HomeScreen({
    super.key,
    this.activityId,
    this.centerId,
    this.query,
    this.date,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final _format = DateFormat("EEE, MMM d, yyyy h:mm a");
final kDateFormat = DateFormat("dd-MM-yyyy");
const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _HomeScreenState extends State<HomeScreen> {
  final _calendarController = CalendarController();
  late final TextEditingController _searchController;
  late final _viewModel = context.read<HomeScreenVM>();

  HomeScreenUIState get _uiState => _viewModel.uiState;

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _viewModel.updateAll(
      activityId: widget.activityId,
      centerId: widget.centerId,
      query: widget.query,
      date: widget.date,
    );
  }

  @override
  void initState() {
    super.initState();
    _calendarController.selectedDate = widget.date ?? DateTime.now();
    _searchController = TextEditingController(text: _uiState.query);

    _viewModel.updateAll(
      activityId: widget.activityId,
      centerId: widget.centerId,
      query: widget.query,
      date: widget.date,
    );
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<HomeScreenVM>();

    final now = DateTime.now();
    final events = _uiState.events;
    final newView = !_viewModel.hasCriteria || widget.date != null
        ? CalendarView.day
        : CalendarView.schedule;
    _calendarController.view = newView;
    _calendarController.displayDate = widget.date ?? DateTime.now();
    // Workaround to disable focus on Calendar when view type is changed
    bool disableFocus = _calendarController.view != newView;

    return Scaffold(
      primary: false,
      appBar: AppBar(
        title: const Text("VanRec"),
        actions: [
          IconButton(
            onPressed: () => _viewModel.refreshEvents(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
          ),
          const BrightnessToggle(),
        ],
      ),
      body: Column(
        children: [
          _buildDropDownHeader(),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(7, (i) {
              final date = now.add(Duration(days: i));

              return ChoiceChip(
                selected: widget.date?.day == date.day,
                tooltip: _format.format(date),
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                onSelected: (selected) {
                  if (!_viewModel.hasCriteria && selected) {
                    refreshPage(
                      query: widget.query,
                      activityId: widget.activityId,
                      centerId: widget.centerId,
                      date: date,
                    );
                  } else if (_viewModel.hasCriteria) {
                    refreshPage(
                      query: widget.query,
                      activityId: widget.activityId,
                      centerId: widget.centerId,
                      date: selected ? date : null,
                    );
                  }
                  setState(() {});
                },
                label: SizedBox(
                  width: 34,
                  child: Text(
                    daysOfWeek[date.weekday - 1],
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: Stack(
              children: [
                ExcludeFocus(
                  excluding: disableFocus,
                  child: SfCalendar(
                    controller: _calendarController,
                    firstDayOfWeek: 1,
                    minDate: (widget.date ?? now).start,
                    maxDate: widget.date != null
                        ? widget.date!.end
                        : (now.add(const Duration(days: 7))).end,
                    appointmentTextStyle:
                        context.theme.textTheme.titleSmall!.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                    timeSlotViewSettings:
                        const TimeSlotViewSettings(startHour: 6),
                    scheduleViewSettings: ScheduleViewSettings(
                      appointmentTextStyle:
                          context.theme.textTheme.titleSmall!.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                      monthHeaderSettings: const MonthHeaderSettings(height: 0),
                    ),
                    onTap: (d) {
                      final a = d.appointments?.first as Appointment?;
                      if (a != null) {
                        final event = a.id as MyEvent;
                        context.go(
                          Uri(
                            path:
                                "${AppPage.event.path}/${event.id}/${event.start.millisecondsSinceEpoch ~/ 1000}/${event.end.millisecondsSinceEpoch ~/ 1000}",
                            queryParameters: {
                              if (widget.query != null) 'q': widget.query,
                              if (widget.activityId != null)
                                'a': widget.activityId.toString(),
                              if (widget.centerId != null)
                                'c': widget.centerId.toString(),
                              if (widget.date != null)
                                'd': kDateFormat.format(widget.date!)
                            },
                          ).toString(),
                          extra: event,
                        );
                      }
                    },
                    dataSource: events != null
                        ? MyDataSource(events
                            .map((e) => Appointment(
                                  startTime: e.start,
                                  endTime: e.end,
                                  subject: e.title,
                                  isAllDay: e.allDay,
                                  notes: e.description,
                                  location: e.centerName,
                                  id: e,
                                  color: context.colorFor(e.id),
                                ))
                            .toList())
                        : null,
                  ),
                ),
                if (_uiState.loadingEvents)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: context.colors.background.withOpacity(0.7),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropDownHeader() {
    final center = _viewModel.center;
    final activities = _uiState.activities;
    final centers = _uiState.centers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search activities, recreational centres",
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.text = "";
                          refreshPage(
                            query: null,
                            activityId: widget.activityId,
                            centerId: widget.centerId,
                            date: widget.date,
                          );
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (value) {
                refreshPage(
                  query: value,
                  activityId: widget.activityId,
                  centerId: widget.centerId,
                  date: widget.date,
                );
              },
            ),
          ),
          if (_uiState.loadingActivities)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator.adaptive(),
            ),
          if (activities != null &&
              activities.isNotEmpty &&
              !_uiState.loadingActivities)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialogs.buildDropDownSearchableList<Activity?>(
                context,
                name: "Activity",
                value: _viewModel.activity,
                values: activities,
                builder: (activity) => activity != null
                    ? Text(activity.name)
                    : Text(
                        "Select",
                        style: TextStyle(color: context.theme.hintColor),
                      ),
                onChanged: (activity) {
                  refreshPage(
                    query: widget.query,
                    activityId: activity?.id,
                    centerId: widget.centerId,
                    date: widget.date,
                  );
                },
                filter: (item, filter) =>
                    item?.name.toLowerCase().contains(filter.toLowerCase()) ==
                    true,
              ),
            ),
          if (_uiState.loadingCenters)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator.adaptive(),
            ),
          if (centers != null && centers.isNotEmpty && !_uiState.loadingCenters)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialogs.buildDropDownSearchableList<RecCenter?>(
                context,
                name: "Centre",
                value: center,
                values: centers,
                builder: (centre) => centre != null
                    ? Text(centre.name)
                    : Text(
                        "Select",
                        style: TextStyle(color: context.theme.hintColor),
                      ),
                onChanged: (center) {
                  refreshPage(
                    query: widget.query,
                    activityId: widget.activityId,
                    centerId: center?.id,
                    date: widget.date,
                  );
                },
                filter: (item, filter) =>
                    item?.name.toLowerCase().contains(filter.toLowerCase()) ==
                    true,
              ),
            ),
        ],
      ),
    );
  }

  void refreshPage({
    int? activityId,
    int? centerId,
    String? query,
    DateTime? date,
  }) {
    context.go(
      Uri(
        path: AppPage.home.path,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (activityId != null) 'a': activityId.toString(),
          if (centerId != null) 'c': centerId.toString(),
          if (date != null) 'd': kDateFormat.format(date)
        },
      ).toString(),
    );
  }
}

class MyDataSource extends CalendarDataSource {
  MyDataSource(List<Appointment> events) {
    appointments = events;
  }
}
