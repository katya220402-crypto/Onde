class WeeklySlot {
  final int dow;
  final String masterId, startTime, endTime;
  WeeklySlot(
      {required this.dow,
      required this.masterId,
      required this.startTime,
      required this.endTime});
  factory WeeklySlot.fromMap(Map<String, dynamic> m) => WeeklySlot(
      dow: m['dow'],
      masterId: m['master_id'],
      startTime: m['start_time'],
      endTime: m['end_time']);
}

class DayException {
  final String masterId;
  final DateTime date;
  final bool isDayOff;
  final String? startTime, endTime;
  DayException(
      {required this.masterId,
      required this.date,
      required this.isDayOff,
      this.startTime,
      this.endTime});
  factory DayException.fromMap(Map<String, dynamic> m) => DayException(
      masterId: m['master_id'],
      date: DateTime.parse(m['date']).toLocal(),
      isDayOff: m['is_day_off'] as bool,
      startTime: m['start_time'],
      endTime: m['end_time']);
}
