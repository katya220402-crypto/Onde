import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onde/theme/colors.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String masterId;
  final String selectedService; // имя услуги
  final DateTime selectedDateTime; // локальное время начала

  const ConfirmBookingScreen({
    super.key,
    required this.masterId,
    required this.selectedService,
    required this.selectedDateTime,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final supa = Supabase.instance.client;
  bool _submitting = false;
  String? _error;

  Future<Map<String, dynamic>?> _loadService() async {
    final row = await supa
        .from('services')
        .select('id, duration_min')
        .eq('master_id', widget.masterId)
        .eq('name', widget.selectedService)
        .maybeSingle();
    return row;
  }

  Future<bool> _slotIsFree(DateTime startLocal, DateTime endLocal) async {
    final rows = await supa
        .from('bookings')
        .select('id,start_at,end_at,status')
        .eq('master_id', widget.masterId)
        .inFilter('status', ['pending', 'confirmed'])
        // пересечение интервалов: start_a <= end_b && end_a >= start_b
        .lte('start_at', endLocal.toUtc().toIso8601String())
        .gte('end_at', startLocal.toUtc().toIso8601String());
    return (rows as List).isEmpty;
  }

  Future<void> _confirm() async {
    final user = supa.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не вошли в систему')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // 1) Найти услугу у мастера
      final svc = await _loadService();
      if (svc == null) {
        throw 'Услуга не найдена у выбранного мастера';
      }
      final String serviceId = svc['id'].toString();
      final int durationMin = (svc['duration_min'] as int?) ?? 60;

      // 2) Посчитать интервалы
      final DateTime startLocal = widget.selectedDateTime;
      final DateTime endLocal = startLocal.add(Duration(minutes: durationMin));

      // 3) Проверить, что слот свободен
      final free = await _slotIsFree(startLocal, endLocal);
      if (!free) {
        throw 'Этот слот уже занят. Пожалуйста, выберите другое время.';
      }

      // 4) Вставка в bookings
      await supa.from('bookings').insert({
        'client_id': user.id,
        'master_id': widget.masterId,
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
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('dd.MM.yyyy • HH:mm').format(widget.selectedDateTime);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Подтверждение записи'),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Мастер ID', value: widget.masterId),
            const SizedBox(height: 8),
            _InfoRow(label: 'Услуга', value: widget.selectedService),
            const SizedBox(height: 8),
            _InfoRow(label: 'Дата и время', value: formatted),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Подтвердить запись'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

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
            ),
          ),
        ],
      ),
    );
  }
}
