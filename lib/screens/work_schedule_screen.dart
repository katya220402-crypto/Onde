import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  final supabase = Supabase.instance.client;
  DateTime _selectedDate = DateTime.now();
  final _timeController = TextEditingController();
  bool _isLoading = false;

  static const lightBlue = Color(0xFFB3E5FC);
  static const darkBlue = Color(0xFF01579B);

  Future<void> _saveSchedule() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _snack('Ошибка: не удалось определить пользователя');
      return;
    }

    final timeText = _timeController.text.trim();
    if (timeText.isEmpty) {
      _snack('Введите хотя бы одно время');
      return;
    }

    // Преобразуем "10:00,11:30" → ["10:00","11:30"]
    final timeSlots = timeText
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);

    try {
      await supabase.from('schedules').insert({
        'master_id': userId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time_slots': timeSlots,
      });
      _snack('График сохранён');
      Navigator.pop(context);
    } catch (e) {
      _snack('Ошибка сохранения: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: darkBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            ColorScheme.fromSeed(seedColor: lightBlue, primary: darkBlue),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkBlue, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мой график'),
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                title: const Text('Выберите дату'),
                subtitle: Text(
                    DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today, color: darkBlue),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: darkBlue,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Время (через запятую: 10:00,11:30,14:00)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Сохранить график'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
