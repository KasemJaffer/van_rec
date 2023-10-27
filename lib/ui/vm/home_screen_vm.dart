import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:importer/data/data.dart';
import 'package:van_rec/data/repo/event_repository.dart';
import 'package:van_rec/shared/logs/logger.dart';

class HomeScreenVM extends ChangeNotifier {
  final EventRepository _repo;
  final HomeScreenUIState _uiState;

  // A mapping of activityId to associated centers (including null for all centers)
  final _allCenters = <int?, Set<RecCenter>>{};

  HomeScreenUIState get uiState => _uiState;

  HomeScreenVM(this._repo, {HomeScreenUIState? state})
      : _uiState = state ?? HomeScreenUIState() {
    _fetchActivitiesAndCenters();
  }

  Future<void> _fetchActivitiesAndCenters() async {
    await _fetchActivities();
    await _fetchCenters();
  }

  bool get hasCriteria =>
      (_uiState._query != null && _uiState._query!.isNotEmpty) ||
      _uiState._activityId != null ||
      _uiState._centerId != null;

  Future<void> _fetchActivities() async {
    if (_uiState._activities == null) {
      _uiState._loadingActivities = true;
      notifyListeners();

      try {
        final resp = await _repo.getActivities();
        _uiState._activities = List.unmodifiable(resp);
      } catch (e) {
        logger.e("Unable to fetch activities", error: e);
      } finally {
        _uiState._loadingActivities = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchCenters() async {
    if (_allCenters.isEmpty) {
      _uiState._loadingCenters = true;
      notifyListeners();
      try {
        final resp = await _repo.getCenterActivities();

        for (final ra in resp) {
          _allCenters[ra.activity.id] ??= {};
          _allCenters[ra.activity.id]!.add(ra.center);

          // add all centers in null
          _allCenters[null] ??= {};
          _allCenters[null]!.add(ra.center);
        }

        final centers =
            _allCenters[_uiState._activityId]?.sortedBy((e) => e.name);
        _uiState._filteredCenters =
            centers == null ? null : List.unmodifiable(centers);
      } catch (e) {
        logger.e("Unable to load centers", error: e);
      } finally {
        _uiState._loadingCenters = false;
        notifyListeners();
      }
    }
  }

  Activity? get activity => _uiState._activityId == null
      ? null
      : _uiState._activities
          ?.firstWhereOrNull((a) => a.id == _uiState._activityId);

  RecCenter? get center => _uiState._centerId == null
      ? null
      : _allCenters[null]?.firstWhereOrNull((a) => a.id == _uiState._centerId);

  void updateAll({
    int? activityId,
    int? centerId,
    String? query,
    DateTime? date,
  }) {
    final changed = _uiState._activityId != activityId ||
        _uiState._centerId != centerId ||
        _uiState._query != query ||
        _uiState._date?.day != date?.day ||
        _uiState._date?.month != date?.month ||
        _uiState._date?.year != date?.year;

    if (!changed) return;

    _uiState._activityId = activityId;
    _uiState._centerId = centerId;
    _uiState._query = query;
    _uiState._date = date;

    final centers = _allCenters[activityId]?.sortedBy((e) => e.name);
    _uiState._filteredCenters =
        centers == null ? null : List.unmodifiable(centers);

    refreshEvents();
  }

  Future<void> refreshEvents() async {
    if (_uiState._loadingEvents) return;

    _uiState._loadingEvents = true;
    _uiState._events = List.unmodifiable([]);

    try {
      final events = await _repo.getEvents(
        date: _uiState._date,
        query: _uiState._query,
        activityId: _uiState._activityId,
        centerId: _uiState._centerId,
      );
      _uiState._events = List.unmodifiable(events);
    } catch (e) {
      logger.e("Unable to fetch events", error: e);
    } finally {
      _uiState._loadingEvents = false;
      notifyListeners();
    }
  }
}

class HomeScreenUIState {
  String? _query;
  int? _activityId;
  int? _centerId;
  DateTime? _date;
  List<Activity>? _activities;
  List<MyEvent>? _events;
  List<RecCenter>? _filteredCenters;
  bool _loadingActivities;
  bool _loadingCenters;
  bool _loadingEvents;

  HomeScreenUIState({
    String? query,
    int? activityId,
    int? centerId,
    DateTime? date,
    List<Activity>? activities,
    List<MyEvent>? events,
    List<RecCenter>? centers,
    bool loadingActivities = false,
    bool loadingCenters = false,
    bool loadingEvents = false,
  })  : _query = query,
        _activityId = activityId,
        _centerId = centerId,
        _date = date,
        _activities = activities,
        _events = events,
        _filteredCenters = centers,
        _loadingActivities = loadingActivities,
        _loadingCenters = loadingCenters,
        _loadingEvents = loadingEvents;

  String? get query => _query;

  int? get activityId => _activityId;

  int? get centerId => _centerId;

  DateTime? get date => _date;

  List<Activity>? get activities => _activities;

  List<MyEvent>? get events => _events;

  List<RecCenter>? get centers => _filteredCenters;

  bool get loadingActivities => _loadingActivities;

  bool get loadingCenters => _loadingCenters;

  bool get loadingEvents => _loadingEvents;
}
