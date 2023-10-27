import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:importer/data/data.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import "dart:io";

class Importer {
  SupabaseClient supabase;

  Importer(this.supabase);

  static const activities = <Map<int, String>>[
    {3: "Public Skating & Ice Hockey"},
    {55: "Public Swimming"},
    {32: "Kerrisdale Play Palace"},
    {5: "Open Gym Times"},
    {1: "Parent and Tot Activities"},
    {47: "Seniors Activities"},
    {43: "Youth Activities"},
    {20: "Art & Culture: Dance, Music, Singing"},
    {26: "Art & Culture: Drawing, Painting, Crafts"},
    {30: "Art & Culture: Pottery & Woodworking"},
    {56: "Fitness: Aerobics/Group Fitness"},
    {8: "Fitness: Indoor Cycling"},
    {14: "Fitness: Martial Arts"},
    {16: "Fitness: Other"},
    {6: "Fitness: Yoga & Pilates"},
    {46: "Sports: Ball & Floor Hockey"},
    {10: "Sports: Basketball"},
    {49: "Sports: Other"},
    {15: "Sports: Racquet Sports"},
    {11: "Sports: Soccer"},
    {9: "Sports: Volleyball"},
    {22: "Various/Other Drop-in Activities"}
  ];

  Future<void> importActivities() async {
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final act = a.entries.first;
      stdout.write("${i + 1}/${activities.length} Updating Activities... ");
      await supabase
          .from("Activities")
          .upsert({"id": act.key, "name": act.value});
      stdout.writeln('DONE');
    }
  }

  Future<void> importCenters() async {
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final act = a.entries.first;
      final activityId = act.key;
      final round = "${i + 1}/${activities.length}";
      stdout.write("$round Fetching centers for [${act.value}]... ");
      final filters = await fetchFilters(activityId);
      stdout.writeln("(${filters.center.length})");

      final centers = filters.center.entries.toList();

      for (int j = 0; j < centers.length; j++) {
        final center = centers[j];
        final centerId = center.key;
        final name = (center.value as String).replaceFirst("*", "");
        stdout
            .write("      ${j + 1}/${centers.length} Updating Centers... ");
        await supabase
            .from("Centers")
            .upsert({"id": centerId, "name": name});
        stdout.write('DONE, updating CenterActivities... ');
        await supabase
            .from("CenterActivities")
            .upsert({"activityId": activityId, "centerId": centerId});
        stdout.writeln('DONE');
      }
    }
  }

  Future<void> importEvents() async {
    stdout.write("Fetching center activity links... ");
    final resp = await supabase
        .from("CenterActivities")
        .select('center:centerId (*), activity:activityId (*)')
        .withConverter<List<CenterActivity>>((data) => (data as List)
            .map(
              (e) => CenterActivity.fromMap(
                center: e["center"],
                activity: e["activity"],
              ),
            )
            .toList());

    stdout.writeln("(${resp.length})");
    for (int j = 0; j < resp.length; j++) {
      final link = resp[j];
      final activity = link.activity;
      final center = link.center;

      final events = (await _fetchEvents(activity, center)).toList();

      stdout.write(
          "${j + 1}/${resp.length} Inserting ${events.length} events... ");
      final r = await supabase.rpc('addEvents', params: {
        'payload': events.map((e) => e.toMap()).toList(),
      });
      stdout.writeln(r ? "OK" : "Failed");
    }
  }

  Future<List<MyEvent>> _fetchEvents(
    Activity activity,
    RecCenter center,
  ) async {
    final uri = Uri(
      scheme: "https",
      host: "ca.apm.activecommunities.com",
      path: "vancouver/ActiveNet_Calendar",
      queryParameters: ActivityParams.getEvents(
        activityId: activity.id,
        centerId: center.id,
        start: DateTime.now().startDateOfWeek,
        end: DateTime.now().startDateOfWeek.start.add(const Duration(days: 21)),
      ).toQueryString(),
    );

    final resp = await http.get(uri);

    final json = jsonDecode(utf8.decode(resp.bodyBytes));

    return (json as List).map((e) {
      e['activityId'] = activity.id;
      e['centerId'] = center.id;
      e['activityName'] = activity.name;
      e['centerName'] = center.name;
      return MyEvent.fromMap(e);
    }).toList();
  }

  Future<FiltersInfo> fetchFilters(int activityId) async {
    final uri = Uri(
      scheme: "https",
      host: "ca.apm.activecommunities.com",
      path: "vancouver/ActiveNet_Calendar",
      queryParameters: ActivityParams.generateFilter(
        activityId: activityId,
        start: DateTime.now().startDateOfWeek,
        end: DateTime.now().startDateOfWeek.start.add(const Duration(days: 21)),
      ).toQueryString(),
    );

    final resp = await http.get(uri);

    final json = jsonDecode(utf8.decode(resp.bodyBytes));

    return FiltersInfo.fromJson(json);
  }
}

class ActivityParams {
  static final _format = DateFormat("yyyy-MM-dd");

  int activityId;
  DateTime start;
  DateTime end;

  bool? getEvents;
  bool? generateFilter;

  DateTime? selectedStart;
  DateTime? selectedEnd;
  int? show;
  int? minAge;
  int? maxAge;
  int? centerId;

  ActivityParams.generateFilter({
    required this.activityId,
    required this.start,
    required this.end,
    this.generateFilter = true,
  });

  ActivityParams.getEvents({
    required this.activityId,
    required this.start,
    required this.end,
    required this.centerId,
    this.getEvents = true,
    this.show = 0,
    this.minAge = 0,
    this.maxAge = 100,
  })  : selectedStart = start,
        selectedEnd = start.start.add(const Duration(days: 21));

  Map<String, String> toQueryString() {
    return {
      'calendarId': activityId.toString(),
      'start': _format.format(start),
      'end': _format.format(end),
      if (getEvents != null) 'getEvents': getEvents.toString(),
      if (generateFilter != null)
        'GenerateCalendarSearchFilter': generateFilter.toString(),
      if (selectedStart != null)
        'selectedStart': _format.format(selectedStart!),
      if (selectedEnd != null) 'selectedEnd': _format.format(selectedEnd!),
      if (show != null) 'show': show.toString(),
      if (minAge != null) 'minAge': minAge.toString(),
      if (maxAge != null) 'maxAge': maxAge.toString(),
      if (centerId != null) 'centerId': centerId.toString(),
    };
  }
}

class FiltersInfo {
  Map<String, dynamic> show;
  Map permitCenter;
  Map<String, dynamic> activityCenter;
  Map activityAndPermitCenter;
  Map<String, dynamic> category;
  Map<String, dynamic> subcategory;
  Map<String, dynamic> activity;
  Map<String, dynamic> center;
  Map<String, List> mapActivityCenters;
  Map<String, List> mapCategoryActivities;
  Map<String, List> mapSubcategoryActivities;
  Map<String, List> mapActivityAgeRange;

  FiltersInfo.fromJson(Map<String, dynamic> map)
      : show = map['show'],
        permitCenter = map['permit_center'],
        activityCenter = map['activity_center'],
        activityAndPermitCenter = map['activity_and_permit_center'],
        category = map['category'],
        subcategory = map['subcategory'],
        activity = map['activity'],
        center = map['center'],
        mapActivityCenters =
            (map['map_activity_centers'] as Map).cast<String, List>(),
        mapCategoryActivities =
            map['map_category_activities'].cast<String, List>(),
        mapSubcategoryActivities =
            map['map_subcategory_activities'].cast<String, List>(),
        mapActivityAgeRange =
            map['map_activity_age_range'].cast<String, List>();
}
