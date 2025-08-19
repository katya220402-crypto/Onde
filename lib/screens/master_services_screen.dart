import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterServicesScreen extends StatefulWidget {
  const MasterServicesScreen({super.key});

  @override
  State<MasterServicesScreen> createState() => _MasterServicesScreenState();
}

class _MasterServicesScreenState extends State<MasterServicesScreen> {
  final supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('services')
          .select()
          .eq('master_id', user.id)
          .order('name');

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> _addService() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) return;

    final price = double.tryParse(priceText);
    if (price == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final newService = {
      'master_id': user.id,
      'name': name,
      'price': price,
    };

    try {
      await supabase.from('services').insert(newService);
      _nameController.clear();
      _priceController.clear();
      await _loadServices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления: $e')),
      );
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      await supabase.from('services').delete().eq('id', id);
      await _loadServices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
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
            backgroundColor: darkBlue, foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Мои услуги')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название услуги',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addService,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить услугу'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _services.isEmpty
                          ? const Center(child: Text('Услуг пока нет'))
                          : ListView.builder(
                              itemCount: _services.length,
                              itemBuilder: (context, index) {
                                final service = _services[index];
                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    title: Text(
                                      service['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text('${service['price']} ₽'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () =>
                                          _deleteService(service['id']),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
