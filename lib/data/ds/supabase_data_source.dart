import 'package:importer/data/data.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data_source.dart';

/// A data source implementation that retrieves data from a remote Supabase client.
class SupbaseDataSource implements DataSource {
  final SupabaseClient client;

  // Formatter for dates
  final _formatter = DateFormat("yyyy-MM-dd HH:mm:ss");

  SupbaseDataSource(this.client);

  @override
  Future<List<MyEvent>> getEvents({
    String? query,
    int? activityId,
    int? centerId,
    DateTime? date,
  }) {
    // Define start and end date ranges for event
    // retrieval based on the provided date or the current date.
    DateTime start;
    DateTime end;
    if (date == null) {
      final now = DateTime.now();
      start = now.start;
      end = start.add(const Duration(days: 6)).end;
    } else {
      start = date.start;
      end = date.end;
    }

    // Use the SupabaseClient to query the "Events" table,
    // select specific columns, apply filters, and order the results.
    final builder = client
        .from("Events")
        .select([
          "activityId",
          "centerId",
          "title",
          "start",
          "end",
          "allDay",
          "id",
          "description",
          "centerName",
          "activityName",
        ].join(", "))
        .gte("start", _formatter.format(start))
        .lte("end", _formatter.format(end));

    if (query != null) builder.textSearch("query", "'$query'");
    if (activityId != null) builder.eq("activityId", activityId);
    if (centerId != null) builder.eq("centerId", centerId);
    builder.order("start", ascending: true);

    return builder.withConverter<List<MyEvent>>((data) =>
        (data as List).map((e) => MyEvent.fromMap(e, false)).toList());
  }

  @override
  Future<List<Activity>> getActivities() {
    // Use the SupabaseClient to query the "Activities" table and order the results.
    return client
        .from("Activities")
        .select()
        .order("name", ascending: true)
        .withConverter<List<Activity>>(
            (data) => (data as List).map((e) => Activity.fromMap(e)).toList());
  }

  @override
  Future<List<RecCenter>> getCenters() {
    // Use the SupabaseClient to query the "Center" table and order the results.
    return client
        .from("Center")
        .select()
        .order("name", ascending: true)
        .withConverter<List<RecCenter>>(
            (data) => (data as List).map((e) => RecCenter.fromMap(e)).toList());
  }

  @override
  Future<List<CenterActivity>> getCenterActivities() {
    // Use the SupabaseClient to query the "CenterActivities" table and select specific columns.
    return client
        .from("CenterActivities")
        .select('center:centerId (*), activity:activityId (*)')
        .withConverter<List<CenterActivity>>((data) => (data as List)
            .map((e) => CenterActivity.fromMap(
                center: e["center"], activity: e["activity"]))
            .toList());
  }

  @override
  Future<MyEvent> getEvent({
    required int id,
    required DateTime start,
    required DateTime end,
  }) {
    return client
        .from("Events")
        .select()
        .match({
          'id': id,
          'start': _formatter.format(start),
          'end': _formatter.format(end),
        })
        .single()
        .withConverter((data) => MyEvent.fromMap(data, false));
  }
}
