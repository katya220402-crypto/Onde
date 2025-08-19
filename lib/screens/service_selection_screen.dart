import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onServiceSelected;

  const ServiceSelectionScreen({super.key, this.onServiceSelected});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await supabase.from('services').select();
      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки услуг: $e')),
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
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Выбор услуги')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _services.isEmpty
                ? const Center(child: Text('Нет доступных услуг'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            service['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: service['price'] != null
                              ? Text(
                                  '${service['price']} ₽',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: darkBlue),
                          onTap: () {
                            widget.onServiceSelected?.call(service);
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
