part of data;

class Activity {
  final int id;
  final String name;

  Activity(this.id, this.name);

  Activity.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
