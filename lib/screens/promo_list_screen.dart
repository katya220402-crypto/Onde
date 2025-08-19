import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'promo_editor_screen.dart';

class PromoListScreen extends StatefulWidget {
  const PromoListScreen({super.key});

  @override
  State<PromoListScreen> createState() => _PromoListScreenState();
}

class _PromoListScreenState extends State<PromoListScreen> {
  final _supa = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = _supa.auth.currentUser;
      if (user == null) throw 'Нужен вход';

      final res = await _supa
          .from('promos')
          .select()
          .eq('master_id', user.id)
          .order('created_at', ascending: false);

      setState(() => _items = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> p, bool value) async {
    try {
      await _supa.from('promos').update({'is_active': value}).eq('id', p['id']);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изменения статуса: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить акцию?'),
        content: Text(p['title'] ?? 'Без названия'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _supa.from('promos').delete().eq('id', p['id']);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
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
      appBar: AppBar(
        title: const Text('Мои акции'),
        actions: [
          IconButton(
            tooltip: 'Создать',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PromoEditorScreen()),
              );
              if (created == true) _load();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _items[i];
                  final active = (p['is_active'] as bool?) ?? true;

                  final from = DateTime.tryParse(p['starts_at'] ?? '');
                  final to = DateTime.tryParse(p['ends_at'] ?? '');

                  return Card(
                    child: ListTile(
                      title: Text(p['title'] ?? 'Без названия'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p['description'] != null &&
                              p['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(p['description']),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Период: '
                            '${from == null ? '-' : df.format(from.toLocal())} — '
                            '${to == null ? '-' : df.format(to.toLocal())}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (p['discount_percent'] != null)
                            Chip(label: Text('-${p['discount_percent']}%')),
                          const SizedBox(height: 4),
                          Switch(
                            value: active,
                            onChanged: (v) => _toggleActive(p, v),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PromoEditorScreen(promo: p),
                          ),
                        );
                        if (changed == true) _load();
                      },
                      onLongPress: () => _delete(p),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
