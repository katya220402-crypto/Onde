import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SlotActionsScreen extends StatefulWidget {
  const SlotActionsScreen({super.key});

  @override
  State<SlotActionsScreen> createState() => _SlotActionsScreenState();
}

class _SlotActionsScreenState extends State<SlotActionsScreen> {
  final _supa = Supabase.instance.client;

  bool _loading = false;
  String? _lastLog;

  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _onPrimary => Theme.of(context).colorScheme.onPrimary;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;

  Future<void> _callSlotGen({int days = 14}) async {
    setState(() {
      _loading = true;
      _lastLog = null;
    });

    try {
      final user = _supa.auth.currentUser;
      if (user == null) {
        throw 'Нет сессии. Выполни вход.';
      }

      // Вызов Edge Function slotGen
      final resp = await _supa.functions.invoke(
        'slotGen',
        body: {
          'master_id': user.id,
          'days': days,
        },
      );

      if (resp.status >= 200 && resp.status < 300) {
        _lastLog = 'OK: ${resp.data}';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Слоты сгенерированы')),
        );
      } else {
        throw 'Ошибка функции (${resp.status}): ${resp.data}';
      }
    } catch (e) {
      _lastLog = 'Ошибка: $e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Генерация слотов'),
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: _surface,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: _primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Сгенерируй свободные слоты на период вперёд.',
                        style: TextStyle(color: _onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _callSlotGen(days: 7),
                    child: const Text('На 7 дней'),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _callSlotGen(days: 14),
                    child: const Text('На 14 дней'),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _callSlotGen(days: 30),
                    child: const Text('На 30 дней'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Последний ответ:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _primary.withValues(alpha: 0.25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _lastLog ?? '—',
                    style: TextStyle(color: _onSurface),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
