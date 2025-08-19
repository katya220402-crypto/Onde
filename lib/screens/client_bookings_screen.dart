import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onde/theme/colors.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  final supa = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supa.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Не выполнен вход';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await supa
          .from('bookings')
          .select(
              'id, service_id, start_at, end_at, status, services(name,price)')
          .eq('client_id', user.id)
          .order('start_at', ascending: false);

      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить записи: $e';
      });
    }
  }

  String _fmtDateTime(String isoUtc) {
    final dt = DateTime.parse(isoUtc).toLocal();
    return DateFormat('dd.MM.yyyy в HH:mm').format(dt);
  }

  bool _isFuture(String isoUtc) {
    final dt = DateTime.parse(isoUtc).toLocal();
    return dt.isAfter(DateTime.now());
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.redAccent;
      case 'done':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await supa.from('bookings').update({'status': 'cancelled'}).eq('id', id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись отменена')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отменить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: AppColors.darkBlue,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lightBlue,
          primary: AppColors.darkBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Мои записи')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? const Center(child: Text('Записей пока нет'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final b = _items[i];
                            final service =
                                b['services'] as Map<String, dynamic>?;
                            final name = service?['name'] ?? 'Услуга';
                            final price = service?['price'];
                            final status = (b['status'] ?? '').toString();
                            final startAt = (b['start_at'] ?? '').toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(_fmtDateTime(startAt)),
                                    if (price != null)
                                      Text('$price ₽',
                                          style: const TextStyle(
                                              color: Colors.black54)),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Chip(
                                      label: Text(status),
                                      backgroundColor: _statusColor(status)
                                          .withOpacity(0.15),
                                      labelStyle: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (status != 'cancelled' &&
                                        status != 'done' &&
                                        _isFuture(startAt))
                                      TextButton(
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                  'Отменить запись?'),
                                              content: const Text(
                                                  'Вы уверены, что хотите отменить запись?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Нет'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Да'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (ok == true)
                                            _cancel(b['id'].toString());
                                        },
                                        child: const Text('Отменить'),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
