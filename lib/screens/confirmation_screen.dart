import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';

class ConfirmationScreen extends StatefulWidget {
  final String selectedService; // имя услуги
  final String selectedMaster; // имя мастера (для показа)
  final String selectedMasterId; // id мастера (uuid)
  final DateTime selectedDate; // выбранный день (без времени)
  final String selectedTime; // 'HH:mm'

  const ConfirmationScreen({
    super.key,
    required this.selectedService,
    required this.selectedMaster,
    required this.selectedMasterId,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final supa = Supabase.instance.client;
  bool _saving = false;

  TimeOfDay _parseHHmm(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  /// Находит услугу у мастера и возвращает {id, duration_min}
  Future<Map<String, dynamic>?> _loadService() async {
    final row = await supa
        .from('services')
        .select('id,duration_min')
        .eq('master_id', widget.selectedMasterId)
        .eq('name', widget.selectedService)
        .maybeSingle();
    return row;
  }

  Future<bool> _isSlotFree(DateTime startAt, DateTime endAt) async {
    final rows = await supa
        .from('bookings')
        .select('id,start_at,end_at,status')
        .eq('master_id', widget.selectedMasterId)
        .inFilter('status', ['pending', 'confirmed'])
        .lte('start_at', endAt.toUtc().toIso8601String())
        .gte('end_at', startAt.toUtc().toIso8601String());
    // условие "пересечения" уже покрыто диапазоном лево/право (start<=end && end>=start)
    return (rows as List).isEmpty;
  }

  Future<void> _confirmBooking() async {
    final user = supa.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не вошли в систему')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Найдём услугу
      final svc = await _loadService();
      if (svc == null) {
        throw 'Услуга не найдена у выбранного мастера';
      }
      final serviceId = svc['id'];
      final durationMin = (svc['duration_min'] as int?) ?? 60;

      // 2) Посчитаем start/end
      final t = _parseHHmm(widget.selectedTime);
      final startLocal = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        t.hour,
        t.minute,
      );
      final endLocal = startLocal.add(Duration(minutes: durationMin));

      // 3) Проверим пересечения
      final free = await _isSlotFree(startLocal, endLocal);
      if (!free) {
        throw 'Этот слот уже занят. Выберите другое время.';
      }

      // 4) Создадим бронирование
      await supa.from('bookings').insert({
        'client_id': user.id,
        'master_id': widget.selectedMasterId,
        'service_id': serviceId,
        'start_at': startLocal.toUtc().toIso8601String(),
        'end_at': endLocal.toUtc().toIso8601String(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись создана')),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy').format(widget.selectedDate);
    final time = widget.selectedTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RowLine(label: 'Услуга', value: widget.selectedService),
            const SizedBox(height: 8),
            _RowLine(label: 'Мастер', value: widget.selectedMaster),
            const SizedBox(height: 8),
            _RowLine(label: 'Дата', value: date),
            const SizedBox(height: 8),
            _RowLine(label: 'Время', value: time),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Подтвердить запись',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;
  const _RowLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
