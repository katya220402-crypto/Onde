import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShiftTemplatesScreen extends StatefulWidget {
  const ShiftTemplatesScreen({super.key});

  @override
  State<ShiftTemplatesScreen> createState() => _ShiftTemplatesScreenState();
}

class _ShiftTemplatesScreenState extends State<ShiftTemplatesScreen> {
  final _supa = Supabase.instance.client;
  bool _loading = true;

  // dow: 1..7 (Mon..Sun) — так удобно сортировать и совпадает с Postgres EXTRACT(DOW) +1
  final _weekDays = const [
    [1, 'Понедельник'],
    [2, 'Вторник'],
    [3, 'Среда'],
    [4, 'Четверг'],
    [5, 'Пятница'],
    [6, 'Суббота'],
    [7, 'Воскресенье'],
  ];

  // dow -> row
  final Map<int, Map<String, dynamic>?> _rows = {};

  Color get _primary => Theme.of(context).colorScheme.primary;

  String _fmtTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return '--:--';
    // ожидаем форматы '09:00' либо '09:00:00'
    final parts = hhmm.split(':');
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _supa.auth.currentUser?.id;
      if (uid == null) throw 'Нужен вход';

      final data = await _supa
          .from('shifts_templates')
          .select()
          .eq('master_id', uid)
          .order('dow');

      _rows.clear();
      for (final m in List<Map<String, dynamic>>.from(data)) {
        _rows[m['dow'] as int] = m;
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось загрузить: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editDay(int dow) async {
    final current = _rows[dow];
    final res = await showModalBottomSheet<_TemplateResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TemplateEditorSheet(
        title: _weekDays.firstWhere((e) => e[0] == dow)[1] as String,
        initialStart: current?['start_time'],
        initialEnd: current?['end_time'],
        initialDayOff: (current?['is_day_off'] as bool?) ?? false,
        primary: _primary,
      ),
    );
    if (res == null) return;

    try {
      final uid = _supa.auth.currentUser?.id;
      if (uid == null) throw 'Нужен вход';

      final payload = {
        'master_id': uid,
        'dow': dow,
        'start_time': res.isDayOff ? null : res.start,
        'end_time': res.isDayOff ? null : res.end,
        'is_day_off': res.isDayOff,
      };

      if (current == null) {
        await _supa.from('shifts_templates').insert(payload);
      } else {
        await _supa
            .from('shifts_templates')
            .upsert(payload, onConflict: 'master_id,dow');
      }

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сбросить шаблоны?'),
        content: const Text('Будут удалены настройки всех дней недели.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сбросить')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final uid = _supa.auth.currentUser?.id;
      if (uid == null) throw 'Нужен вход';
      await _supa.from('shifts_templates').delete().eq('master_id', uid);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сброса: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны графика'),
        actions: [
          IconButton(
            tooltip: 'Сбросить всё',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _weekDays.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final dow = _weekDays[i][0] as int;
                  final name = _weekDays[i][1] as String;
                  final row = _rows[dow];
                  final dayOff = (row?['is_day_off'] as bool?) ?? false;

                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _primary.withOpacity(.12),
                        foregroundColor: _primary,
                        child: Text(dow.toString()),
                      ),
                      title: Text(name),
                      subtitle: dayOff
                          ? const Text('Выходной',
                              style: TextStyle(fontStyle: FontStyle.italic))
                          : Text(
                              '${_fmtTime(row?['start_time'])} — ${_fmtTime(row?['end_time'])}'),
                      trailing: Icon(Icons.edit_outlined, color: _primary),
                      onTap: () => _editDay(dow),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: () async {
              // быстрый пред-набор для всех будней 10:00–19:00
              final uid = _supa.auth.currentUser?.id;
              if (uid == null) return;
              try {
                final batch = [
                  for (final d in [1, 2, 3, 4, 5])
                    {
                      'master_id': uid,
                      'dow': d,
                      'start_time': '10:00',
                      'end_time': '19:00',
                      'is_day_off': false,
                    },
                  {'master_id': uid, 'dow': 6, 'is_day_off': true},
                  {'master_id': uid, 'dow': 7, 'is_day_off': true},
                ];
                await _supa
                    .from('shifts_templates')
                    .upsert(batch, onConflict: 'master_id,dow');
                await _load();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заполнено по шаблону будней')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка автозаполнения: $e')),
                );
              }
            },
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Заполнить будни 10:00–19:00'),
          ),
        ),
      ),
    );
  }
}

class _TemplateResult {
  final String? start;
  final String? end;
  final bool isDayOff;
  _TemplateResult({this.start, this.end, required this.isDayOff});
}

class _TemplateEditorSheet extends StatefulWidget {
  final String title;
  final String? initialStart;
  final String? initialEnd;
  final bool initialDayOff;
  final Color primary;

  const _TemplateEditorSheet({
    required this.title,
    this.initialStart,
    this.initialEnd,
    required this.initialDayOff,
    required this.primary,
  });

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  late bool _dayOff;
  String? _start; // 'HH:mm'
  String? _end;

  @override
  void initState() {
    super.initState();
    _dayOff = widget.initialDayOff;
    _start = widget.initialStart ?? '10:00';
    _end = widget.initialEnd ?? '19:00';
  }

  Future<void> _pickTime(bool isStart) async {
    final base = (isStart ? _start : _end) ?? '10:00';
    final parts = base.split(':');
    final t = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: t,
      helpText: isStart ? 'Время начала' : 'Время окончания',
    );
    if (picked != null) {
      final v =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _start = v;
        } else {
          _end = v;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.primary,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _dayOff,
            onChanged: (v) => setState(() => _dayOff = v),
            title: const Text('Выходной'),
          ),
          if (!_dayOff) ...[
            ListTile(
              title: const Text('Начало'),
              subtitle: Text(_start ?? '--:--', style: textStyle),
              leading: const Icon(Icons.schedule_outlined),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              title: const Text('Окончание'),
              subtitle: Text(_end ?? '--:--', style: textStyle),
              leading: const Icon(Icons.schedule),
              onTap: () => _pickTime(false),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  _TemplateResult(
                    start: _dayOff ? null : _start,
                    end: _dayOff ? null : _end,
                    isDayOff: _dayOff,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}
