import 'package:importer/data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_rec/shared/logs/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:van_rec/ui/vm/details_dialog_vm.dart';
import 'home_screen_vm_test.mocks.dart';

void main() async {
  SharedPreferences.setMockInitialValues({});
  late final mockRepo = MockEventRepository();
  initializeLogger();

  test('DetailsDialogVM fetches event correctly', () async {
    final detailsDialogVM = DetailsDialogVM(mockRepo, null);

    final testEvent = MyEvent(
      activityId: 1,
      centerId: 1,
      title: "test",
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(hours: 4)),
      allDay: false,
      id: 1,
      centerName: "test",
      activityName: "test",
    );

    when(mockRepo.getEvent(
      id: testEvent.id,
      start: testEvent.start,
      end: testEvent.end,
    )).thenAnswer((_) async {
      return testEvent;
    });

    detailsDialogVM.fetchEvent(
      id: testEvent.id,
      start: testEvent.start,
      end: testEvent.end,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    final actualEvent = detailsDialogVM.event;
    expect(actualEvent, isNotNull);
    expect(actualEvent, testEvent);
  });
}
