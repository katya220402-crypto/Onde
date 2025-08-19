import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientPromoFeedScreen extends StatefulWidget {
  const ClientPromoFeedScreen({super.key});

  @override
  State<ClientPromoFeedScreen> createState() => _ClientPromoFeedScreenState();
}

class _ClientPromoFeedScreenState extends State<ClientPromoFeedScreen> {
  final _supa = Supabase.instance.client;
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _supa
          .from('promos')
          .select()
          .lte('starts_at', DateTime.now().toUtc().toIso8601String())
          .gte('ends_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);
      setState(() => _items = List<Map<String, dynamic>>.from(res));
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
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Акции и предложения')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _items[i];
                  return Card(
                    child: ListTile(
                      title: Text(p['title'] ?? 'Без названия'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p['description'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(p['description']),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Действует: ${df.format(DateTime.parse(p['starts_at']).toLocal())} — ${df.format(DateTime.parse(p['ends_at']).toLocal())}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: (p['discount_percent'] != null)
                          ? Chip(label: Text('-${p['discount_percent']}%'))
                          : null,
                      onTap: () {
                        // TODO: переход на детальную акцию / фильтр по услуге
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
