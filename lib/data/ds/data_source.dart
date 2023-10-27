import 'package:importer/data/data.dart';

/// This interface represents a data source for retrieving various data entities.
abstract class DataSource {
  /// Retrieves a list of events based on specified parameters.
  ///
  /// [query] A search query to filter events by title or description (nullable).
  /// [activityId] The ID of the activity to filter events by (nullable).
  /// [centerId] The ID of the center to filter events by (nullable).
  /// [date] The date for which events are retrieved (nullable).
  /// Returns a list of [MyEvent] objects representing events.
  Future<List<MyEvent>> getEvents(
      {String? query, int? activityId, int? centerId, DateTime? date});

  /// Retrieves a single event based on its ID and the start and end times.
  ///
  /// [id] The ID of the event to retrieve.
  /// [start] The start time of the event.
  /// [end] The end time of the event.
  /// Returns a [MyEvent] object representing the event, or throws an error if the operation fails.
  Future<MyEvent> getEvent(
      {required int id, required DateTime start, required DateTime end});

  /// Retrieves a list of activities.
  ///
  /// Returns a list of [Activity] objects representing activities.
  Future<List<Activity>> getActivities();

  /// Retrieves a list of centers.
  ///
  /// Returns a list of [RecCenter] objects representing centers.
  Future<List<RecCenter>> getCenters();

  /// Retrieves a list of center activities.
  ///
  /// Returns a list of [CenterActivity] objects representing center activities.
  Future<List<CenterActivity>> getCenterActivities();
}
