part of data;

final _format = DateFormat("MM/dd/yyyy hh:mm:ss a");
final _format24 = DateFormat("yyyy-MM-dd HH:mm:ss");

class MyEvent {
  int activityId;
  int centerId;
  String title;
  DateTime start;
  DateTime end;
  bool allDay;
  int id;
  String? description;
  String centerName;
  String activityName;



  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  MyEvent.fromMap(Map json, [bool fromWeb = true])
      : activityId = json['activityId'],
        centerId = json["centerId"],
        title = json["title"],
        start = fromWeb
            ? _format.parse(json["start"])
            : DateTime.parse(json["start"]),
        end =
            fromWeb ? _format.parse(json["end"]) : DateTime.parse(json["end"]),
        allDay = json["allDay"],
        id = json["id"],
        description = json["description"],
        centerName = json["centerName"],
        activityName = json["activityName"];

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'centerId': centerId,
      'title': title,
      'start': _format24.format(start),
      'end': _format24.format(end),
      'allDay': allDay,
      'id': id,
      'description': description,
      'activityName': activityName,
      'centerName': centerName,
    };
  }

  MyEvent({
    required this.activityId,
    required this.centerId,
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    required this.id,
    this.description,
    required this.centerName,
    required this.activityName,
  });
}





