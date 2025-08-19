import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final supa = Supabase.instance.client;

  DateTime _visibleMonth = _firstDayOfMonth(DateTime.now());
  bool _loading = true;
  String? _error;

  // Сырые записи месяца (без фильтра)
  List<Map<String, dynamic>> _monthRows = [];

  // day -> бронирования С УЧЁТОМ статус‑фильтра
  final Map<DateTime, List<Map<String, dynamic>>> _eventsByDay = {};

  // Статусы, которые отображаем (по умолчанию активные)
  final Set<String> _visibleStatuses = {'pending', 'confirmed'};

  static DateTime _firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _lastDayOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0);

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
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
      _monthRows.clear();
      _eventsByDay.clear();
    });

    final from = _firstDayOfMonth(_visibleMonth);
    final to = _lastDayOfMonth(_visibleMonth)
        .add(const Duration(days: 1)); // open interval

    try {
      final rows = await supa
          .from('bookings')
          .select('id,start_at,end_at,status,client_name,services(name,price)')
          .eq('master_id', user.id)
          .gte('start_at', from.toUtc().toIso8601String())
          .lt('start_at', to.toUtc().toIso8601String())
          .order('start_at');

      _monthRows = List<Map<String, dynamic>>.from(rows as List);
      _rebuildFilteredMap();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  void _rebuildFilteredMap() {
    _eventsByDay.clear();
    for (final b in _monthRows) {
      final st = DateTime.parse(b['start_at']).toLocal();
      final status = (b['status'] ?? '').toString();
      if (!_visibleStatuses.contains(status)) continue;

      final key = DateTime(st.year, st.month, st.day);
      _eventsByDay.putIfAbsent(key, () => []).add(b);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await supa.from('bookings').update({'status': newStatus}).eq('id', id);
      // Локально обновим и перефильтруем, без полного запроса
      final idx =
          _monthRows.indexWhere((e) => e['id'].toString() == id.toString());
      if (idx != -1) _monthRows[idx]['status'] = newStatus;
      _rebuildFilteredMap();
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус обновлён: $newStatus')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось обновить статус: $e')),
      );
    }
  }

  void _prevMonth() {
    setState(() => _visibleMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1));
    _loadMonth();
  }

  void _nextMonth() {
    setState(() => _visibleMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1));
    _loadMonth();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('LLLL yyyy', 'ru').format(_visibleMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь записей')),
      body: Column(
        children: [
          // Навигация по месяцам
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Предыдущий месяц',
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title[0].toUpperCase() + title.substring(1),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Следующий месяц',
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Фильтр по статусам
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                _StatusFilterChip(
                  label: 'В ожидании',
                  status: 'pending',
                  selected: _visibleStatuses.contains('pending'),
                  color: Colors.orange,
                  onToggle: _toggleStatus,
                ),
                _StatusFilterChip(
                  label: 'Подтверждено',
                  status: 'confirmed',
                  selected: _visibleStatuses.contains('confirmed'),
                  color: Colors.green,
                  onToggle: _toggleStatus,
                ),
                _StatusFilterChip(
                  label: 'Отменено',
                  status: 'cancelled',
                  selected: _visibleStatuses.contains('cancelled'),
                  color: Colors.redAccent,
                  onToggle: _toggleStatus,
                ),
                _StatusFilterChip(
                  label: 'Завершено',
                  status: 'done',
                  selected: _visibleStatuses.contains('done'),
                  color: Colors.grey,
                  onToggle: _toggleStatus,
                ),
              ],
            ),
          ),

          // Заголовки дней недели
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: const [
                _Dow('Пн'),
                _Dow('Вт'),
                _Dow('Ср'),
                _Dow('Чт'),
                _Dow('Пт'),
                _Dow('Сб'),
                _Dow('Вс'),
              ],
            ),
          ),
          const Divider(height: 0),

          // Сетка месяца
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _loadMonth,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cells = _buildMonthCells(_visibleMonth);
                            return GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                              itemCount: cells.length,
                              itemBuilder: (_, i) {
                                final cell = cells[i];
                                final hasEvents =
                                    _eventsByDay[cell.dateKey]?.isNotEmpty ==
                                        true;
                                return _DayCell(
                                  date: cell.date,
                                  inMonth: cell.inMonth,
                                  hasEvents: hasEvents,
                                  isToday:
                                      _isSameDay(cell.date, DateTime.now()),
                                  onTap: () => _openDay(cell.date),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(String status, bool value) {
    setState(() {
      if (value) {
        _visibleStatuses.add(status);
      } else {
        _visibleStatuses.remove(status);
      }
      _rebuildFilteredMap();
    });
  }

  void _openDay(DateTime d) {
    final key = DateTime(d.year, d.month, d.day);
    final items = _eventsByDay[key] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2)),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM', 'ru').format(d),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Text('${items.length}',
                          style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Записей нет'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final b = items[i];
                        final start = DateTime.parse(b['start_at']).toLocal();
                        final end = DateTime.parse(b['end_at']).toLocal();
                        final service =
                            (b['services'] as Map?)?['name'] ?? 'Услуга';
                        final client = b['client_name'] ?? '—';
                        final status = (b['status'] ?? '').toString();
                        final id = b['id'].toString();

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(
                                '$service • ${_hhmm(start)}–${_hhmm(end)}'),
                            subtitle: Text('Клиент: $client'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatusChip(status: status),
                                const SizedBox(height: 6),
                                _ActionRow(
                                  status: status,
                                  onConfirm: () =>
                                      _updateStatus(id, 'confirmed'),
                                  onCancel: () =>
                                      _updateStatus(id, 'cancelled'),
                                  onDone: () => _updateStatus(id, 'done'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Cell> _buildMonthCells(DateTime month) {
    final first = _firstDayOfMonth(month);
    final last = _lastDayOfMonth(month);

    final int startWeekday = first.weekday; // 1..7 (Пн..Вс)
    final int daysInMonth = last.day;
    final leading = (startWeekday - 1) % 7;
    final cellsCount = ((leading + daysInMonth) / 7.0).ceil() * 7;

    final List<_Cell> cells = [];
    for (int i = 0; i < cellsCount; i++) {
      final dayNum = i - leading + 1;
      DateTime date;
      bool inMonth;
      if (dayNum < 1) {
        final prevLast = first.subtract(const Duration(days: 1));
        date = DateTime(prevLast.year, prevLast.month, prevLast.day + dayNum);
        inMonth = false;
      } else if (dayNum > daysInMonth) {
        final nextFirst = DateTime(month.year, month.month + 1, 1);
        date = DateTime(nextFirst.year, nextFirst.month, dayNum - daysInMonth);
        inMonth = false;
      } else {
        date = DateTime(month.year, month.month, dayNum);
        inMonth = true;
      }
      cells.add(_Cell(date: date, inMonth: inMonth));
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _hhmm(DateTime dt) => DateFormat('HH:mm').format(dt);
}

// ————— маленькие UI‑виджеты —————

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final String status;
  final bool selected;
  final Color color;
  final void Function(String status, bool value) onToggle;

  const _StatusFilterChip({
    required this.label,
    required this.status,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => onToggle(status, v),
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withOpacity(0.5)),
    );
  }
}

class _Dow extends StatelessWidget {
  final String text;
  const _Dow(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ),
    );
  }
}

class _Cell {
  final DateTime date;
  final bool inMonth;
  _Cell({required this.date, required this.inMonth});

  DateTime get dateKey => DateTime(date.year, date.month, date.day);
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final bool hasEvents;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.hasEvents,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString();
    final textColor = inMonth
        ? (isToday ? Colors.blueAccent : Colors.black87)
        : Colors.black26;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? Colors.blue.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(day,
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            if (hasEvents)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? Colors.blueAccent : Colors.blueGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      backgroundColor: _color.withOpacity(0.15),
      labelStyle: TextStyle(color: _color, fontWeight: FontWeight.w600),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String status;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const _ActionRow({
    required this.status,
    required this.onConfirm,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // Логика действий:
    // pending  -> [Подтвердить] [Отменить]
    // confirmed-> [Завершить]  [Отменить]
    // done/cancelled -> нет действий
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onConfirm, child: const Text('Подтвердить')),
          TextButton(onPressed: onCancel, child: const Text('Отменить')),
        ],
      );
    } else if (status == 'confirmed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onDone, child: const Text('Завершить')),
          TextButton(onPressed: onCancel, child: const Text('Отменить')),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
