import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';

class AddServiceScreen extends StatefulWidget {
  /// если [existing] передан — это режим редактирования
  final Map<String, dynamic>? existing;
  const AddServiceScreen({super.key, this.existing});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final supa = Supabase.instance.client;

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');

  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = (e['name'] ?? '').toString();
      _priceCtrl.text = (e['price'] ?? '').toString();
      _durationCtrl.text = (e['duration_min'] ?? '').toString();
      _isActive = (e['is_active'] as bool?) ?? true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = supa.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не выполнен вход')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название')),
      );
      return;
    }

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final durationMin = int.tryParse(_durationCtrl.text.trim()) ?? 60;

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await supa.from('services').insert({
          'master_id': user.id,
          'name': name,
          'price': price,
          'duration_min': durationMin,
          'is_active': _isActive,
        });
      } else {
        await supa.from('services').update({
          'name': name,
          'price': price,
          'duration_min': durationMin,
          'is_active': _isActive,
        }).eq('id', widget.existing!['id']);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existing == null
                ? 'Услуга добавлена'
                : 'Изменения сохранены')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(isEdit ? 'Редактировать услугу' : 'Добавить услугу')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Цена (₽)'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationCtrl,
              decoration:
                  const InputDecoration(labelText: 'Длительность (мин)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Активна'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
