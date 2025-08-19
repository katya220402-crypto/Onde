import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? service; // если null — создаём новую
  const ServiceEditorScreen({super.key, this.service});

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final _supa = Supabase.instance.client;
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController(text: '60');
  bool _active = true;
  bool _saving = false;

  Color get _primary => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      _name.text = s['name'] ?? '';
      _price.text = (s['price'] as num?)?.toStringAsFixed(2) ?? '';
      _duration.text = (s['duration_min'] as int?)?.toString() ?? '60';
      _active = (s['is_active'] as bool?) ?? true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = _supa.auth.currentUser;
      if (user == null) throw 'Нужен вход';

      final payload = {
        'master_id': user.id,
        'name': _name.text.trim(),
        'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0,
        'duration_min': int.tryParse(_duration.text.trim()) ?? 60,
        'is_active': _active,
      };

      if (widget.service == null) {
        await _supa.from('services').insert(payload);
      } else {
        await _supa
            .from('services')
            .update(payload)
            .eq('id', widget.service!['id']);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Услуга сохранена')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.service == null ? 'Новая услуга' : 'Редактировать услугу'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Название услуги',
                    prefixIcon: Icon(Icons.cut_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Укажи название' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Цена',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: '₽',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Длительность, мин',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('Активна'),
                  secondary: Icon(
                      _active ? Icons.check_circle : Icons.pause_circle_outline,
                      color: _primary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
