import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterSelectionScreen extends StatefulWidget {
  final String selectedService;
  final Function(String) onMasterSelected;

  const MasterSelectionScreen({
    super.key,
    required this.selectedService,
    required this.onMasterSelected,
  });

  @override
  State<MasterSelectionScreen> createState() => _MasterSelectionScreenState();
}

class _MasterSelectionScreenState extends State<MasterSelectionScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _masters = [];
  bool _isLoading = true;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  @override
  void initState() {
    super.initState();
    _fetchMastersForService();
  }

  Future<void> _fetchMastersForService() async {
    try {
      final response = await supabase
          .from('services')
          .select('master_id, users(name, avatar_url)')
          .eq('name', widget.selectedService);

      final uniqueMasters =
          <String, Map<String, String>>{}; // id -> {name, avatar}

      for (final row in response) {
        final masterId = row['master_id'] as String;
        final name = row['users']['name'] as String? ?? 'Без имени';
        final avatar = row['users']['avatar_url'] as String? ?? '';
        uniqueMasters[masterId] = {'name': name, 'avatar': avatar};
      }

      setState(() {
        _masters = uniqueMasters.entries
            .map((e) => {
                  'id': e.key,
                  'name': e.value['name'],
                  'avatar': e.value['avatar']
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки мастеров: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            ColorScheme.fromSeed(seedColor: lightBlue, primary: darkBlue),
        appBarTheme: const AppBarTheme(
            backgroundColor: darkBlue, foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Выбор мастера'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _masters.isEmpty
                ? const Center(child: Text('Нет доступных мастеров'))
                : ListView.builder(
                    itemCount: _masters.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final master = _masters[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundImage: (master['avatar'] != null &&
                                    master['avatar'].toString().isNotEmpty)
                                ? NetworkImage(master['avatar'])
                                : const AssetImage(
                                        'assets/images/default_avatar.png')
                                    as ImageProvider,
                          ),
                          title: Text(
                            master['name'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.grey),
                          onTap: () {
                            widget.onMasterSelected(master['id']);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
