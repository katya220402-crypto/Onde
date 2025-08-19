import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onde/theme/colors.dart';
import 'dart:convert';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final supa = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  final Map<String, Map<String, num>> _byService = {};
  int _totalCount = 0;
  num _totalRevenue = 0;

  final _money =
      NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      _byService.clear();
      _totalCount = 0;
      _totalRevenue = 0;
    });

    try {
      final rows = await supa
          .from('bookings')
          .select('service_id, status, services(name, price)')
          .eq('master_id', user.id)
          .inFilter('status', ['confirmed', 'done']);

      final list = List<Map<String, dynamic>>.from(rows as List);

      for (final b in list) {
        final service = (b['services'] as Map?) ?? {};
        final name = (service['name'] ?? 'Услуга') as String;
        final price = (service['price'] ?? 0);
        final priceNum =
            price is int ? price.toDouble() : (price as num).toDouble();

        final entry = _byService.putIfAbsent(
            name, () => {'count': 0, 'revenue': 0, 'price': priceNum});
        entry['count'] = (entry['count'] ?? 0) + 1;
        entry['revenue'] = (entry['revenue'] ?? 0) + priceNum;

        _totalCount += 1;
        _totalRevenue += priceNum;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  Future<void> _exportCSV() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Услуга,Цена,Количество,Выручка');

      _byService.forEach((name, m) {
        final price = m['price'] ?? 0;
        final count = m['count'] ?? 0;
        final revenue = m['revenue'] ?? 0;
        buffer.writeln('$name,$price,$count,$revenue');
      });

      buffer.writeln('ИТОГО, ,$_totalCount,$_totalRevenue');

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/analytics.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString(), encoding: utf8);

      await Share.shareXFiles([XFile(filePath)],
          text: 'Аналитика по услугам Onde');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? topName;
    num topRevenue = 0;
    _byService.forEach((name, m) {
      final rev = (m['revenue'] ?? 0);
      if (rev > topRevenue) {
        topRevenue = rev;
        topName = name;
      }
    });

    return Theme(
      data: ThemeData(
        primaryColor: AppColors.darkBlue,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.lightBlue, primary: AppColors.darkBlue),
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: AppColors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Аналитика'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _byService.isEmpty ? null : _exportCSV,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Записей',
                                value: _totalCount.toString(),
                                icon: Icons.event_available,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Выручка',
                                value: _money.format(_totalRevenue),
                                icon: Icons.payments,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (topName != null)
                          _HighlightCard(
                            title: 'Топ-услуга',
                            subtitle: topName!,
                            value: _money.format(topRevenue),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Статистика по услугам',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ..._byService.entries.map((e) {
                          final name = e.key;
                          final cnt = (e.value['count'] ?? 0).toInt();
                          final rev = (e.value['revenue'] ?? 0);
                          final price = (e.value['price'] ?? 0);
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.design_services),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Цена: ${_money.format(price)}  •  Кол-во: $cnt'),
                              trailing: Text(_money.format(rev)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
              child: Icon(icon, color: AppColors.darkBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
