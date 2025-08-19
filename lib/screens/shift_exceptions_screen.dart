import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShiftExceptionsScreen extends StatefulWidget {
  const ShiftExceptionsScreen({super.key});

  @override
  State<ShiftExceptionsScreen> createState() => _ShiftExceptionsScreenState();
}

class _ShiftExceptionsScreenState extends State<ShiftExceptionsScreen> {
  final _supa = Supabase.instance.client;

  DateTime _date = DateTime.now();
  bool _isDayOff = true;
  TimeOfDay? _start;
  TimeOfDay? _end;

  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_start ?? const TimeOfDay(hour: 9, minute: 0))
          : (_end ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = _supa.auth.currentUser;
      if (user == null) throw 'Не выполнен вход';

      final res = await _supa
          .from('shifts_exceptions')
          .select()
          .eq('master_id', user.id)
          .order('date');

      setState(() => _items = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = _supa.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выполни вход')));
      return;
    }

    if (!_isDayOff && (_start == null || _end == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажи время начала и конца')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String? startStr;
      String? endStr;
      if (!_isDayOff) {
        final dtStart = DateTime(
            _date.year, _date.month, _date.day, _start!.hour, _start!.minute);
        final dtEnd = DateTime(
            _date.year, _date.month, _date.day, _end!.hour, _end!.minute);
        startStr = dtStart.toUtc().toIso8601String();
        endStr = dtEnd.toUtc().toIso8601String();
      }

      await _supa.from('shifts_exceptions').upsert({
        'master_id': user.id,
        'date': DateTime(_date.year, _date.month, _date.day)
            .toUtc()
            .toIso8601String(),
        'is_day_off': _isDayOff,
        'start_time': startStr,
        'end_time': endStr,
      }, onConflict: 'master_id,date');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    setState(() => _loading = true);
    try {
      await _supa
          .from('shifts_exceptions')
          .delete()
          .match({'master_id': row['master_id'], 'date': row['date']});
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
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
    final tf = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Исключения графика')),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text('Дата: ${df.format(_date)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Выходной день'),
                    value: _isDayOff,
                    onChanged: (v) => setState(() => _isDayOff = v),
                  ),
                ),
              ],
            ),
            if (!_isDayOff) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(
                          'Начало: ${_start == null ? '--:--' : _start!.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(
                          'Конец: ${_end == null ? '--:--' : _end!.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить исключение'),
            ),
            const Divider(height: 32),
            if (_loading) const Center(child: CircularProgressIndicator()),
            ..._items.map((row) {
              final date = DateTime.parse(row['date']).toLocal();
              final isDayOff = (row['is_day_off'] as bool?) ?? false;

              String subtitle;
              if (isDayOff) {
                subtitle = 'Выходной';
              } else {
                final st = row['start_time'];
                final et = row['end_time'];
                final start = st == null ? null : DateTime.parse(st).toLocal();
                final end = et == null ? null : DateTime.parse(et).toLocal();
                subtitle =
                    '${start == null ? '--:--' : tf.format(start)} - ${end == null ? '--:--' : tf.format(end)}';
              }

              return Card(
                child: ListTile(
                  title: Text(df.format(date)),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(row),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
