import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/schedule.dart';

final supa = Supabase.instance.client;

class Repo {
  // Auth+User
  Future<AppUser?> currentUser() async {
    final u = supa.auth.currentUser;
    if (u == null) return null;
    final row =
        await supa.from('users').select('*').eq('id', u.id).maybeSingle();
    return row == null ? null : AppUser.fromMap(row);
  }

  Future<void> updateUser(AppUser u) async =>
      supa.from('users').update(u.toUpdate()).eq('id', u.id);

  // Services
  Future<List<ServiceItem>> masterServices(String masterId) async {
    final res = await supa
        .from('services')
        .select('*')
        .eq('master_id', masterId)
        .order('created_at');
    return (res as List).map((e) => ServiceItem.fromMap(e)).toList();
  }

  Future<String> createService(
      {required String masterId,
      required String name,
      required num price,
      required int durationMin}) async {
    final r = await supa
        .from('services')
        .insert({
          'master_id': masterId,
          'name': name,
          'price': price,
          'duration_min': durationMin,
          'is_active': true,
        })
        .select('id')
        .single();
    return r['id'];
  }

  // Schedule
  Future<List<WeeklySlot>> getWeekly(String masterId, int dow) async {
    final r = await supa
        .from('schedules_weekly')
        .select('*')
        .eq('master_id', masterId)
        .eq('dow', dow);
    return (r as List).map((e) => WeeklySlot.fromMap(e)).toList();
  }

  Future<List<DayException>> getExceptions(
      String masterId, DateTime day) async {
    final d = DateTime(day.year, day.month, day.day).toIso8601String();
    final r = await supa
        .from('schedule_exceptions')
        .select('*')
        .eq('master_id', masterId)
        .eq('date', d);
    return (r as List).map((e) => DayException.fromMap(e)).toList();
  }

  Future<void> upsertWeekly(
      {required String masterId,
      required int dow,
      required String start,
      required String end}) async {
    await supa.from('schedules_weekly').upsert({
      'master_id': masterId,
      'dow': dow,
      'start_time': start,
      'end_time': end
    });
  }

  Future<void> upsertException(
      {required String masterId,
      required DateTime date,
      bool isOff = false,
      String? start,
      String? end}) async {
    await supa.from('schedule_exceptions').upsert({
      'master_id': masterId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'is_day_off': isOff,
      'start_time': start,
      'end_time': end
    });
  }

  // Bookings
  Future<List<Booking>> clientBookings(String clientId,
      {bool active = true}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final filter = active
        ? "and(status.in.(pending,confirmed),end_at.gte.$now)"
        : "or(status.in.(done,cancelled),end_at.lt.$now)";
    final r = await supa
        .from('bookings')
        .select('id,master_id,client_id,service_id,start_at,end_at,status')
        .eq('client_id', clientId)
        .or(filter)
        .order('start_at');
    return (r as List).map((e) => Booking.fromMap(e)).toList();
  }

  Future<List<Booking>> masterBookings(
      String masterId, DateTime from, DateTime to) async {
    final r = await supa
        .from('bookings')
        .select('id,master_id,client_id,service_id,start_at,end_at,status')
        .eq('master_id', masterId)
        .gte('start_at', from.toUtc().toIso8601String())
        .lt('start_at', to.toUtc().toIso8601String())
        .order('start_at');
    return (r as List).map((e) => Booking.fromMap(e)).toList();
  }

  Future<String> createBooking(
      {required String clientId,
      required String masterId,
      required ServiceItem service,
      required DateTime startLocal}) async {
    final sUtc = startLocal.toUtc();
    final eUtc = sUtc.add(Duration(minutes: service.durationMin));
    final r = await supa
        .from('bookings')
        .insert({
          'client_id': clientId,
          'master_id': masterId,
          'service_id': service.id,
          'start_at': sUtc.toIso8601String(),
          'end_at': eUtc.toIso8601String(),
          'status': 'pending',
        })
        .select('id')
        .single();
    return r['id'];
  }

  Future<void> setBookingStatus(String bookingId, String status) async =>
      supa.from('bookings').update({'status': status}).eq('id', bookingId);
}
