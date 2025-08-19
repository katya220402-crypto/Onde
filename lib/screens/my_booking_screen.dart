import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final supa = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  RealtimeChannel? _chan;

  @override
  void initState() {
    super.initState();
    _load();

    // --- опционально: живые обновления моих записей
    final uid = supa.auth.currentUser?.id;
    if (uid != null) {
      _chan = supa
          .channel('bookings-realtime-client')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'client_id',
              value: uid,
            ),
            callback: (payload) => _load(),
          )
          .subscribe();
    }
  }

  @override
  void dispose() {
    if (_chan != null) {
      try {
        supa.removeChannel(_chan!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = supa.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Вы не авторизованы';
      });
      return;
    }

    try {
      // Актуальная схема: берём услугу через join и сортируем по start_at
      final rows = await supa
          .from('bookings')
          .select(
            'id, status, start_at, end_at, service_id, services(name, price)',
          )
          .eq('client_id', user.id)
          .order('start_at', ascending: false);

      final list = (rows as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить записи: $e';
        _loading = false;
      });
    }
  }

  Future<void> _cancel(String bookingId) async {
    try {
      await supa
          .from('bookings')
          .update({'status': 'cancelled'}).eq('id', bookingId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись отменена')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены: $e')),
      );
    }
  }

  String _fmtDateTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd.MM.yyyy в HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : _items.isEmpty
                ? const Center(child: Text('Записей пока нет'))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final b = _items[i];
                      final id = b['id'] as String;
                      final status = (b['status'] as String?) ?? 'pending';
                      final startIso = b['start_at'] as String;
                      final endIso = b['end_at'] as String?;
                      final service = b['services'] as Map<String, dynamic>?;

                      final serviceName =
                          (service?['name'] as String?) ?? 'Услуга';
                      final price = service?['price'];
                      final statusText = switch (status) {
                        'confirmed' => '✅ Подтверждено',
                        'cancelled' => '❌ Отменено',
                        _ => '⌛ В ожидании',
                      };

                      final endPart = endIso == null
                          ? ''
                          : ' — ${DateFormat('HH:mm').format(DateTime.parse(endIso).toLocal())}';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(serviceName),
                          subtitle: Text(
                            '${_fmtDateTime(startIso)}$endPart'
                            '${price != null ? '\n₽ $price' : ''}',
                            style: const TextStyle(height: 1.4),
                          ),
                          trailing: status == 'cancelled'
                              ? Text(statusText)
                              : status == 'confirmed'
                                  ? Text(statusText)
                                  : ElevatedButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title:
                                                const Text('Отменить запись?'),
                                            content: const Text(
                                              'Вы уверены, что хотите отменить запись?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Нет'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Да'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _cancel(id);
                                        }
                                      },
                                      child: const Text('Отменить'),
                                    ),
                        ),
                      );
                    },
                  );

    return Scaffold(
      appBar: AppBar(title: Text('Мои записи')),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}
