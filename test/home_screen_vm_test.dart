import 'package:importer/data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_rec/data/repo/event_repository.dart';
import 'package:van_rec/shared/logs/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:van_rec/ui/vm/home_screen_vm.dart';
import 'home_screen_vm_test.mocks.dart';

// Run `flutter pub run build_runner build` to generate mock classes
@GenerateNiceMocks([MockSpec<EventRepository>()])
void main() async {
  SharedPreferences.setMockInitialValues({});
  late final mockRepo = MockEventRepository();
  initializeLogger();

  final centerActivities = <CenterActivity>[];
  final activities = <Activity>[];

  setUp(() {
    centerActivities.clear();
    activities.clear();

    // Populate test data
    for (int i = 0; i < 10; i++) {
      final activity = Activity(i, "Activity-$i");
      activities.add(activity);

      centerActivities.addAll(List.generate(5, (j) {
        final offset = i * 5;
        return CenterActivity(
          activity,
          RecCenter(j + offset, "RecCenter: ${j + offset}"),
        );
      }));
    }

    when(mockRepo.getActivities()).thenAnswer((_) async {
      return activities;
    });

    when(mockRepo.getCenterActivities()).thenAnswer((_) async {
      return centerActivities;
    });

    when(mockRepo.getEvents()).thenAnswer((_) async {
      return [];
    });
  });

  group('Home Screen Test', () {
    test('HomeScreenVM populates activities correctly', () async {
      // Create a HomeScreenVM instance with the mock repository
      final homeScreenVM = HomeScreenVM(mockRepo);

      await Future.delayed(const Duration(milliseconds: 500));

      // Verify that the activities list in the ViewModel is populated with the expected data
      final actualActivities = homeScreenVM.uiState.activities;
      expect(actualActivities, isNotNull);
      expect(actualActivities!.length, activities.length);
      expect(actualActivities, activities);
    });

    test('HomeScreenVM populates RecCenters correctly', () async {
      // Create a HomeScreenVM instance with the mock repository
      final homeScreenVM = HomeScreenVM(mockRepo);

      await Future.delayed(const Duration(milliseconds: 500));

      // Verify that the RecCenters list in the ViewModel is populated with the expected data
      var expectedCenters = centerActivities.map((e) => e.center);
      var centers = homeScreenVM.uiState.centers;
      expect(centers, isNotNull);
      expect(centers!.length, expectedCenters.length);

      // Test with given activity id
      var activityId = activities.first.id;
      homeScreenVM.updateAll(activityId: activityId);
      await Future.delayed(const Duration(milliseconds: 500));

      expectedCenters = centerActivities
          .where((e) => e.activity.id == activityId)
          .map((e) => e.center);
      centers = homeScreenVM.uiState.centers;
      expect(centers, isNotNull);
      expect(centers!.length, expectedCenters.length);
    });

    test('HomeScreenVM populates Events correctly', () async {
      final homeScreenVM = HomeScreenVM(mockRepo);
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
      when(mockRepo.getEvents(query: "test")).thenAnswer((_) async {
        return [testEvent];
      });

      // Test with given query
      homeScreenVM.updateAll(query: "test");
      await Future.delayed(const Duration(milliseconds: 500));
      var actualEvents = homeScreenVM.uiState.events;
      expect(actualEvents, isNotNull);
      expect(actualEvents!.length, 1);
      expect(actualEvents.first, testEvent);
    });
  });
}
