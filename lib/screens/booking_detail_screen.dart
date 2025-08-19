import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _supa = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _booking;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _supa
          .from('bookings')
          .select(
              '*, services(name, price), profiles!bookings_client_id_fkey(full_name, email, phone)')
          .eq('id', widget.bookingId)
          .single();

      setState(() => _booking = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _loading = true);
    try {
      await _supa
          .from('bookings')
          .update({'status': status}).eq('id', widget.bookingId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Статус: $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dtf = DateFormat('dd.MM.yyyy HH:mm');

    final b = _booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Запись')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : b == null
              ? const Center(child: Text('Запись не найдена'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['services']?['name'] ?? 'Услуга',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text('Клиент: ${b['profiles']?['full_name'] ?? '—'}'),
                      Text('Email: ${b['profiles']?['email'] ?? '—'}'),
                      Text('Телефон: ${b['profiles']?['phone'] ?? '—'}'),
                      const SizedBox(height: 6),
                      Text(
                          'Начало: ${dtf.format(DateTime.parse(b['start_time']).toLocal())}'),
                      Text(
                          'Конец:  ${dtf.format(DateTime.parse(b['end_time']).toLocal())}'),
                      const SizedBox(height: 6),
                      Text('Статус: ${b['status']}'),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _setStatus('cancelled'),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Отменить'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _setStatus('confirmed'),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Подтвердить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
