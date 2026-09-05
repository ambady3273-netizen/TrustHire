import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';

/// User Profile Edit — lets any authenticated user update their
/// full name and profile photo.
/// The service methods (updateName, updateProfileImage) already exist
/// in FirestoreService; this screen simply calls them.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() =>
      _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _newAvatar;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // Pre-fill with current user data.
  void _init(String currentName) {
    if (!_initialized) {
      _nameCtrl.text = currentName;
      _initialized = true;
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _newAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final fs = ref.read(firestoreServiceProvider);

      // 1. Update name.
      final newName = _nameCtrl.text.trim();
      await fs.updateName(uid, newName);

      // 2. Upload new avatar if chosen.
      if (_newAvatar != null) {
        final ref_ = FirebaseStorage.instance
            .ref('profiles/$uid/avatar.jpg');
        await ref_.putFile(_newAvatar!);
        final url = await ref_.getDownloadURL();
        await fs.updateProfileImage(uid, url);
      }

      // Refresh userProvider so all screens see the updated name.
      ref.invalidate(userProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    // Pre-fill once the user loads.
    if (user != null) _init(user.fullName);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar picker ──────────────────────────
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _saving ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.tealLight,
                        backgroundImage: _newAvatar != null
                            ? FileImage(_newAvatar!) as ImageProvider
                            : (user?.profileImage.isNotEmpty == true
                                ? NetworkImage(user!.profileImage)
                                    as ImageProvider
                                : null),
                        child: (_newAvatar == null &&
                                (user?.profileImage.isEmpty ?? true))
                            ? Text(
                                (user?.fullName.isNotEmpty == true)
                                    ? user!.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap to change photo',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.mute)),

                const SizedBox(height: 32),

                // ── Name field ─────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    if (v.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Read-only info ─────────────────────────
                if (user != null) ...[
                  _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: user.role == 'job_seeker'
                          ? 'Job Seeker'
                          : user.role == 'employer'
                              ? 'Employer'
                              : 'Admin'),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Trust Score',
                      value: '${user.trustScore.toStringAsFixed(1)} / 100'),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: user.verified
                          ? Icons.verified_user
                          : Icons.pending_outlined,
                      label: 'Verification',
                      value: user.verified ? 'Verified' : 'Pending',
                      valueColor: user.verified
                          ? AppColors.teal
                          : AppColors.marigoldDark),
                ],

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mute),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mute)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}
