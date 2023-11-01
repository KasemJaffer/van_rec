import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:importer/data/data.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import "dart:io";

/// The `ImporterImpl` class is responsible for importing data into Supabase.
class ImporterImpl {
  final SupabaseClient client;

  /// External source where all the data come from.
  final sourceUrl = Uri.parse(
      "https://ca.apm.activecommunities.com/vancouver/ActiveNet_Calendar");

  /// Constructor for the `ImporterImpl` class.
  ///
  /// Initialize a new instance of `Importer` with a Supabase client.
  ///
  /// [client] - An instance of the Supabase client.
  ImporterImpl(this.client);

  /// A static list of activities with their corresponding IDs and names.
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

  /// Import activities into the Supabase database.
  Future<void> importActivities() async {
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final act = a.entries.first;
      stdout.write("${i + 1}/${activities.length} Updating Activities... ");

      // Add to table in the database
      await client
          .from("Activities")
          .upsert({"id": act.key, "name": act.value});
      stdout.writeln('DONE');
    }
  }

  /// Import centers into the Supabase database and link them to activities.
  Future<void> importCenters() async {
    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final act = a.entries.first;
      final activityId = act.key;
      final round = "${i + 1}/${activities.length}";
      stdout.write("$round Fetching centers for [${act.value}]... ");

      // Fetch centers from external source
      final centers = await _fetchCenters(activityId);

      stdout.writeln("(${centers.length})");

      int j = 0;
      for (var center in centers) {
        j++;
        stdout.write("      $j/${centers.length} Updating Centers... ");

        // Add them to database
        await client.from("Centers").upsert({
          "id": center.id,
          "name": center.name,
        });
        stdout.write('DONE, updating CenterActivities... ');

        // Add Activity and Center link
        await client.from("CenterActivities").upsert({
          "activityId": activityId,
          "centerId": center.id,
        });
        stdout.writeln('DONE');
      }
    }
  }

  /// Import events into the Supabase database.
  Future<void> importEvents() async {
    stdout.write("Fetching center activity links... ");
    final resp = await client
        .from("CenterActivities")
        .select('center:centerId (*), activity:activityId (*)')
        .withConverter<List<CenterActivity>>((data) => (data as List)
            .map((e) => CenterActivity.fromMap(
                  center: e["center"],
                  activity: e["activity"],
                ))
            .toList());

    stdout.writeln("(${resp.length})");
    for (int j = 0; j < resp.length; j++) {
      final link = resp[j];
      final activity = link.activity;
      final center = link.center;

      // Fetch events from external source
      final events = (await _fetchEvents(activity, center)).toList();

      stdout.write(
          "${j + 1}/${resp.length} Inserting ${events.length} events... ");

      // Add them to database using addEvents stored procedure
      final r = await client.rpc('addEvents', params: {
        'payload': events.map((e) => e.toMap()).toList(),
      });
      stdout.writeln(r ? "OK" : "Failed");
    }
  }

  /// Fetch events for a given activity and center from [sourceUrl].
  Future<Iterable<MyEvent>> _fetchEvents(
    Activity activity,
    RecCenter center,
  ) async {
    final uri = Uri(
      scheme: sourceUrl.scheme,
      host: sourceUrl.host,
      path: sourceUrl.path,
      queryParameters: _QueryParams.forEvents(
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
    });
  }

  /// Fetch centers for a specific activity from [sourceUrl].
  Future<Iterable<RecCenter>> _fetchCenters(int activityId) async {
    final uri = Uri(
      scheme: sourceUrl.scheme,
      host: sourceUrl.host,
      path: sourceUrl.path,
      queryParameters: _QueryParams.forCenters(
        activityId: activityId,
        start: DateTime.now().startDateOfWeek,
        end: DateTime.now().startDateOfWeek.start.add(const Duration(days: 21)),
      ).toQueryString(),
    );

    final resp = await http.get(uri);
    final json = jsonDecode(utf8.decode(resp.bodyBytes));

    return (json['center'] as Map<String, dynamic>).entries.map((e) {
      final id = e.key;
      final name = (e.value as String).replaceFirst("*", "");
      return RecCenter(int.parse(id), name);
    });
  }
}

class _QueryParams {
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

  /// Initializes specific params for fetching centers.
  _QueryParams.forCenters({
    required this.activityId,
    required this.start,
    required this.end,
    this.generateFilter = true,
  });

  /// Initializes specific params for fetching events.
  _QueryParams.forEvents({
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
