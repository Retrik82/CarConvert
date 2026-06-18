import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../utils/validators.dart';
import '../widgets/design_system/app_button.dart';
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
    final tokens = context.tokens;
    final name = _name.text;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spacing24),
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tokens.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: tokens.surfaceMuted,
                        backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child: _avatarPath == null || !File(_avatarPath!).existsSync()
                            ? Text(
                                (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                style: tokens.textStyle(fontSize: 32, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: tokens.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Text(
                'Tap to change avatar',
                style: tokens.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing24),
              appTextField(
                context: context,
                controller: _name,
                label: 'Name',
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const Spacer(),
              AppButton(
                label: 'Save',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: DesignTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
