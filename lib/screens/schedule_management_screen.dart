import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, Map<String, String>> schedule = {
    'Понедельник': {'start': '', 'end': ''},
    'Вторник': {'start': '', 'end': ''},
    'Среда': {'start': '', 'end': ''},
    'Четверг': {'start': '', 'end': ''},
    'Пятница': {'start': '', 'end': ''},
    'Суббота': {'start': '', 'end': ''},
    'Воскресенье': {'start': '', 'end': ''},
  };

  bool isLoading = true;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('schedules')
        .select()
        .eq('master_id', user.id)
        .maybeSingle();

    if (response != null && response['data'] != null) {
      setState(() {
        final data = Map<String, dynamic>.from(response['data']);
        for (var day in schedule.keys) {
          schedule[day]?['start'] = data[day]?['start'] ?? '';
          schedule[day]?['end'] = data[day]?['end'] ?? '';
        }
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveSchedule() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = {'master_id': user.id, 'data': schedule};

    await supabase.from('schedules').upsert(data).match({'master_id': user.id});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('График обновлён')),
    );
  }

  Future<void> pickTime(String day, String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        schedule[day]?[type] =
            picked.format(context).replaceAll('.', ':'); // Формат ЧЧ:ММ
      });
    }
  }

  Widget buildTimeButton(String day, String label, String type) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: darkBlue),
        ),
        onPressed: () => pickTime(day, type),
        child: Text(
          (schedule[day]?[type] ?? '').isNotEmpty
              ? '${label}: ${schedule[day]?[type]}'
              : '$label',
          style: const TextStyle(color: darkBlue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: darkBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            ColorScheme.fromSeed(seedColor: lightBlue, primary: darkBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('График работы')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (var day in schedule.keys)
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildTimeButton(day, 'Начало', 'start'),
                                const SizedBox(width: 12),
                                buildTimeButton(day, 'Конец', 'end'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: saveSchedule,
                    child: const Text(
                      'Сохранить график',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
