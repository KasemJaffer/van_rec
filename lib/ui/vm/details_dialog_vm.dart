import 'package:flutter/foundation.dart';
import 'package:importer/data/data.dart';
import 'package:van_rec/data/repo/event_repository.dart';
import 'package:van_rec/shared/logs/logger.dart';

class DetailsDialogVM extends ChangeNotifier {
  final EventRepository _repo;
  bool _loading = false;
  MyEvent? _event;

  DetailsDialogVM(this._repo, this._event);

  bool get loading => _loading;

  MyEvent? get event => _event;

  void fetchEvent({
    required int id,
    required DateTime start,
    required DateTime end,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _event = await _repo.getEvent(id: id, start: start, end: end);
    } catch (e) {
      logger.e("Unable to get event", error: e);
    }
    _loading = false;
    notifyListeners();
  }
}
