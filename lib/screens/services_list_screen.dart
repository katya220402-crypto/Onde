import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import 'add_service_screen.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = supa.auth.currentUser;
      if (user == null) throw 'Не выполнен вход';
      final rows = await supa
          .from('services')
          .select('id,name,price,duration_min,is_active')
          .eq('master_id', user.id)
          .order('name');
      setState(() => _items = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить услугу?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Да')),
        ],
      ),
    );
    if (ok != true) return;

    await supa.from('services').delete().eq('id', id);
    _load();
  }

  Future<void> _toggleActive(String id, bool v) async {
    await supa.from('services').update({'is_active': v}).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, textAlign: TextAlign.center))
            : _items.isEmpty
                ? const Center(child: Text('Пока нет услуг'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = _items[i];
                      final id = s['id'] as String;
                      final active = (s['is_active'] as bool?) ?? true;
                      final price = (s['price'] ?? 0).toString();
                      final dur = (s['duration_min'] ?? 0).toString();

                      return Card(
                        child: ListTile(
                          title: Text(s['name'] ?? ''),
                          subtitle: Text('₽ $price • $dur мин'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: active,
                                onChanged: (v) => _toggleActive(id, v),
                              ),
                              IconButton(
                                tooltip: 'Редактировать',
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddServiceScreen(existing: s),
                                    ),
                                  );
                                  if (updated == true) _load();
                                },
                              ),
                              IconButton(
                                tooltip: 'Удалить',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _delete(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

    return Scaffold(
      appBar: AppBar(title: const Text('Мои услуги')),
      body: RefreshIndicator(onRefresh: _load, child: body),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServiceScreen()),
          );
          if (created == true) _load();
        },
      ),
    );
  }
}
