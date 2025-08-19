import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'datetime_selection_screen.dart';

class PromoEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? promo; // если передали — редактирование
  const PromoEditorScreen({super.key, this.promo});

  @override
  State<PromoEditorScreen> createState() => _PromoEditorScreenState();
}

class _PromoEditorScreenState extends State<PromoEditorScreen> {
  final _supa = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _discount = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    if (p != null) {
      _title.text = p['title'] ?? '';
      _desc.text = p['description'] ?? '';
      if (p['discount_percent'] != null) {
        _discount.text = p['discount_percent'].toString();
      }
      _from = DateTime.tryParse(p['starts_at'] ?? '')?.toLocal();
      _to = DateTime.tryParse(p['ends_at'] ?? '')?.toLocal();
    } else {
      final now = DateTime.now();
      _from = DateTime(now.year, now.month, now.day, 0, 0);
      _to = _from!.add(const Duration(days: 14));
    }
  }

  Future<void> _pickPeriod() async {
    final res = await Navigator.push<Map<String, DateTime?>>(
      context,
      MaterialPageRoute(
        builder: (_) => DateTimeSelectionScreen(
          initialFrom: _from,
          initialTo: _to,
          allowTime: false,
          title: 'Период действия',
        ),
      ),
    );
    if (res != null) {
      setState(() {
        _from = res['from'];
        _to = res['to'];
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выбери период акции')));
      return;
    }
    setState(() => _saving = true);
    try {
      final user = _supa.auth.currentUser;
      if (user == null) throw 'Нужен вход';

      final payload = {
        'master_id': user.id,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'discount_percent': int.tryParse(_discount.text.trim()),
        'starts_at': _from!.toUtc().toIso8601String(),
        'ends_at': _to!.toUtc().toIso8601String(),
        'is_active': true,
      };

      if (widget.promo == null) {
        await _supa.from('promos').insert(payload);
      } else {
        await _supa
            .from('promos')
            .update(payload)
            .eq('id', widget.promo!['id']);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Сохранено')));
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
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromStr = _from == null
        ? '—'
        : '${_from!.day.toString().padLeft(2, '0')}.${_from!.month.toString().padLeft(2, '0')}.${_from!.year}';
    final toStr = _to == null
        ? '—'
        : '${_to!.day.toString().padLeft(2, '0')}.${_to!.month.toString().padLeft(2, '0')}.${_to!.year}';

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.promo == null ? 'Новая акция' : 'Редактирование')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Заголовок'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажи заголовок'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Скидка, %'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Период действия'),
                  subtitle: Text('$fromStr — $toStr'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickPeriod,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
