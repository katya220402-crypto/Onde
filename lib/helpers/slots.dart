import '../data/supabase_repo.dart';
import '../models/service.dart';

DateTime _combineLocal(DateTime day, String hhmmss) {
  final p = hhmmss.split(':').map(int.parse).toList();
  return DateTime(day.year, day.month, day.day, p[0], p[1]);
}

Future<List<DateTime>> buildFreeSlots(
    {required Repo repo,
    required String masterId,
    required ServiceItem service,
    required DateTime dayLocal}) async {
  final dow = dayLocal.weekday % 7;
  final weekly = await repo.getWeekly(masterId, dow);
  final ex = await repo.getExceptions(masterId, dayLocal);

  if (ex.isNotEmpty && ex.first.isDayOff) return [];
  final windows = <({DateTime from, DateTime to})>[];
  if (ex.isNotEmpty && ex.first.startTime != null && ex.first.endTime != null) {
    windows.add((
      from: _combineLocal(dayLocal, ex.first.startTime!),
      to: _combineLocal(dayLocal, ex.first.endTime!)
    ));
  } else {
    for (final w in weekly) {
      windows.add((
        from: _combineLocal(dayLocal, w.startTime),
        to: _combineLocal(dayLocal, w.endTime)
      ));
    }
  }

  final fromUtc = DateTime(dayLocal.year, dayLocal.month, dayLocal.day).toUtc();
  final busy = await repo.masterBookings(
      masterId, fromUtc, fromUtc.add(const Duration(days: 1)));
  final intervals = busy
      .where((b) => b.status != 'cancelled')
      .map((b) => (b.startAt.toLocal(), b.endAt.toLocal()))
      .toList();

  final step = Duration(minutes: service.durationMin);
  final out = <DateTime>[];
  for (final w in windows) {
    for (var t = w.from; !t.add(step).isAfter(w.to); t = t.add(step)) {
      final st = t, en = t.add(step);
      final hit = intervals.any((i) => st.isBefore(i.$2) && en.isAfter(i.$1));
      if (!hit) out.add(st);
    }
  }
  return out;
}
