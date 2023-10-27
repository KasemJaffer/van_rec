part of data;

extension DateTimeE on DateTime {
  DateTime get startDateOfWeek => subtract(Duration(days: weekday - 1));

  DateTime get endDateOfWeek =>
      add(Duration(days: DateTime.daysPerWeek - weekday));

  DateTime get start => DateTime(year, month, day);

  DateTime get end => DateTime(year, month, day, 23, 59, 59);
}