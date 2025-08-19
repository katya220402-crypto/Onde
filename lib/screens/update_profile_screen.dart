import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _supa = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? avatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _supa.auth.currentUser;
    if (user == null) return;
    final data =
        await _supa.from('users').select().eq('id', user.id).maybeSingle();
    if (data != null) {
      _nameCtrl.text = data['name'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
    }
  }

  Future<void> _save() async {
    final user = _supa.auth.currentUser;
    if (user == null) return;
    String? avatarUrl;

    if (avatarPath != null) {
      final file = File(avatarPath!);
      final path = "avatars/${user.id}.jpg";
      await _supa.storage
          .from("public")
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      avatarUrl = _supa.storage.from("public").getPublicUrl(path);
    }

    await _supa.from('users').update({
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', user.id);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        title: const Text("Редактирование профиля",
            style: TextStyle(color: AppColors.darkBlue)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final x =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => avatarPath = x.path);
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatarPath != null ? FileImage(File(avatarPath!)) : null,
                child: avatarPath == null
                    ? const Icon(Icons.person,
                        size: 40, color: AppColors.darkBlue)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Имя"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Телефон"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkBlue),
              onPressed: _save,
              child: const Text("Сохранить",
                  style: TextStyle(color: AppColors.white)),
            )
          ],
        ),
      ),
    );
  }
}
