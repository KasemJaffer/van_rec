part of data;

class CenterActivity {
  final Activity activity;
  final RecCenter center;

  CenterActivity(this.activity, this.center);

  CenterActivity.fromMap({
    required Map<String, dynamic> activity,
    required Map<String, dynamic> center,
  })  : activity = Activity.fromMap(activity),
        center = RecCenter.fromMap(center);
}
