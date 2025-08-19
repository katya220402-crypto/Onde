import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onde/theme/colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _phone = '+79308382204';
  static const _instagramHandle = 'onde.beauty';
  static final _igUrl = Uri.parse('https://instagram.com/$_instagramHandle');

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть приложение')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Помощь'),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шапка
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDEEAF6), Color(0xFFE3F1F3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Если у вас возникли вопросы — мы на связи. Выберите удобный способ:',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Телефон
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
                child: const Icon(Icons.call, color: AppColors.darkBlue),
              ),
              title: const Text('Позвонить'),
              subtitle: const Text('+7 (930) 838‑22‑04'),
              onTap: () => _launch(context, Uri(scheme: 'tel', path: _phone)),
            ),
          ),

          // Instagram
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
                child: const Icon(Icons.camera_alt, color: AppColors.darkBlue),
              ),
              title: const Text('Instagram'),
              subtitle: const Text('@onde.beauty'),
              onTap: () => _launch(context, _igUrl),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Работаем ежедневно, отвечаем в течение дня.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
