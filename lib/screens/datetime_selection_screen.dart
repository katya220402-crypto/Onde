import 'package:flutter/material.dart';

class DateTimeSelectionScreen extends StatefulWidget {
  final DateTime? initialFrom;
  final DateTime? initialTo;
  final bool allowTime; // если true — выбираем ещё и время
  final String title;

  const DateTimeSelectionScreen({
    super.key,
    this.initialFrom,
    this.initialTo,
    this.allowTime = true,
    this.title = 'Выбор периода',
  });

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.initialFrom ?? DateTime(now.year, now.month, now.day, 9, 0);
    _to = widget.initialTo ?? _from.add(const Duration(hours: 1));
  }

  Future<void> _pickDate(bool isFrom) async {
    final base = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        final withTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          base.hour,
          base.minute,
        );
        if (isFrom) {
          _from = withTime;
          if (_to.isBefore(_from)) _to = _from.add(const Duration(hours: 1));
        } else {
          _to = withTime;
          if (_to.isBefore(_from))
            _from = _to.subtract(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    if (!widget.allowTime) return;
    final base = isFrom ? _from : _to;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: isFrom ? 'Время начала' : 'Время окончания',
    );
    if (picked != null) {
      setState(() {
        final newDt = DateTime(
            base.year, base.month, base.day, picked.hour, picked.minute);
        if (isFrom) {
          _from = newDt;
          if (_to.isBefore(_from)) _to = _from.add(const Duration(hours: 1));
        } else {
          _to = newDt;
          if (_to.isBefore(_from))
            _from = _to.subtract(const Duration(hours: 1));
        }
      });
    }
  }

  void _done() {
    Navigator.pop<Map<String, DateTime?>>(context, {'from': _from, 'to': _to});
  }

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return widget.allowTime ? '$d $t' : d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Начало'),
              subtitle: Text(_fmt(_from)),
              leading: const Icon(Icons.play_circle_outline),
              onTap: () => _pickDate(true),
              trailing: widget.allowTime
                  ? IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () => _pickTime(true),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Окончание'),
              subtitle: Text(_fmt(_to)),
              leading: const Icon(Icons.stop_circle_outlined),
              onTap: () => _pickDate(false),
              trailing: widget.allowTime
                  ? IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () => _pickTime(false),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _done,
            icon: const Icon(Icons.check),
            label: const Text('Готово'),
          ),
        ],
      ),
    );
  }
}
