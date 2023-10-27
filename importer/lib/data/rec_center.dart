part of data;

class RecCenter {
  final int id;
  final String name;

  RecCenter(this.id, this.name);

  RecCenter.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecCenter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
