import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterBookingsScreen extends StatefulWidget {
  const MasterBookingsScreen({super.key});

  @override
  State<MasterBookingsScreen> createState() => _MasterBookingsScreenState();
}

class _MasterBookingsScreenState extends State<MasterBookingsScreen> {
  final supa = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();

    // (опционально) лайв-обновление списка
    supa
        .channel('bookings-realtime-master')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'master_id',
            value: supa.auth.currentUser?.id ?? '',
          ),
          callback: (payload) => _load(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    try {
      supa.removeChannel(supa.channel('bookings-realtime-master'));
    } catch (_) {}
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
      // Актуальная схема: start_at/end_at + связи на services и users
      final rows = await supa
          .from('bookings')
          .select(
            'id, status, start_at, end_at, service_id, '
            'services(name, price), '
            'users!bookings_client_id_fkey(name)', // имя клиента (если нужно)
          )
          .eq('master_id', user.id)
          .order('start_at', ascending: true);

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

  Future<void> _setStatus(String id, String status) async {
    try {
      await supa.from('bookings').update({'status': status}).eq('id', id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус изменён на: $status')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изменения статуса: $e')),
      );
    }
  }

  String _fmt(String iso) =>
      DateFormat('dd.MM.yyyy • HH:mm').format(DateTime.parse(iso).toLocal());

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои записи')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои записи')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мои записи')),
      body: _items.isEmpty
          ? const Center(child: Text('Нет записей'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final b = _items[i];
                final id = b['id'] as String;
                final status = (b['status'] as String?) ?? 'pending';
                final startIso = b['start_at'] as String;
                final endIso = b['end_at'] as String?;
                final service = b['services'] as Map<String, dynamic>?;
                final client =
                    b['users'] as Map<String, dynamic>?; // из client_id

                final serviceName = (service?['name'] as String?) ?? 'Услуга';
                final price = service?['price'];
                final clientName = client?['name'] ?? 'Клиент';
                final timeText = endIso == null
                    ? _fmt(startIso)
                    : '${_fmt(startIso)} — ${DateFormat('HH:mm').format(DateTime.parse(endIso).toLocal())}';

                final statusChip = switch (status) {
                  'confirmed' => const Chip(
                      label: Text('Подтверждено'),
                      backgroundColor: Color(0xFFE8F5E9)),
                  'cancelled' => const Chip(
                      label: Text('Отменено'),
                      backgroundColor: Color(0xFFFFEBEE)),
                  _ => const Chip(label: Text('В ожидании')),
                };

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(serviceName),
                    subtitle: Text(
                      '$clientName\n$timeText${price != null ? '\n₽ $price' : ''}',
                      style: const TextStyle(height: 1.4),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        statusChip,
                        const SizedBox(height: 8),
                        if (status != 'cancelled')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Подтвердить',
                                onPressed: status == 'confirmed'
                                    ? null
                                    : () => _setStatus(id, 'confirmed'),
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Отменить',
                                onPressed: () => _setStatus(id, 'cancelled'),
                                icon: const Icon(Icons.cancel_outlined),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
