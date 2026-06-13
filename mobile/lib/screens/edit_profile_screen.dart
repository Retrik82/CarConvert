import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/form_fields.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const EditProfileScreen({super.key, this.onSaved});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _picker = ImagePicker();
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthRepository.instance.currentUser;
    if (user == null) return;
    final override = await ProfileRepository.instance.getProfileOverride(user.id);
    _name.text = override?['display_name'] ?? user.displayName;
    _avatarPath = override?['avatar_path'];
    if (mounted) setState(() {});
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (picked == null) return;
    final user = AuthRepository.instance.currentUser;
    if (user == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/avatars/${user.id}.jpg';
    await File(dest).create(recursive: true);
    await File(picked.path).copy(dest);
    setState(() => _avatarPath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthRepository.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ProfileRepository.instance.saveProfileOverride(
        user.id,
        displayName: _name.text.trim(),
        avatarPath: _avatarPath,
      );
      await AuthRepository.instance.updateLocalProfile(displayName: _name.text.trim());
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.surfaceMuted,
                      backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                          ? FileImage(File(_avatarPath!))
                          : null,
                      child: _avatarPath == null || !File(_avatarPath!).existsSync()
                          ? Text(
                              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                              style: AppTheme.textStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change avatar',
                style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              appTextField(
                context: context,
                controller: _name,
                label: 'Name',
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
