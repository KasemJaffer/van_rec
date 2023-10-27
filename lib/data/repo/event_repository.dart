import 'package:importer/data/data.dart';

import '../ds/data_source.dart';

class EventRepository {
  // The data source responsible for fetching event-related data
  final DataSource dataSource;

  EventRepository(this.dataSource);

  Future<List<MyEvent>> getEvents(
      {String? query, int? activityId, int? centerId, DateTime? date}) {
    return dataSource.getEvents(
      query: query,
      activityId: activityId,
      centerId: centerId,
      date: date,
    );
  }

  Future<List<Activity>> getActivities() {
    return dataSource.getActivities();
  }

  Future<List<CenterActivity>> getCenterActivities() {
    return dataSource.getCenterActivities();
  }

  Future<MyEvent> getEvent({
    required int id,
    required DateTime start,
    required DateTime end,
  }) {
    return dataSource.getEvent(id: id, start: start, end: end);
  }
}
