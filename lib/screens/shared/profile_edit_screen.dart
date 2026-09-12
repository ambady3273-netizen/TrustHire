import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ─────────────────────────────────────────────────────────────
// Profile Edit + KYC Submission Screen
// Accessible from all 3 roles via the person icon in the AppBar.
// ─────────────────────────────────────────────────────────────

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('My Profile'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            Tab(icon: Icon(Icons.verified_user_outlined), text: 'KYC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProfileTab(user: user),
          _KycTab(user: user),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 — Profile Edit
// ═══════════════════════════════════════════════════════════════

class _ProfileTab extends ConsumerStatefulWidget {
  final UserModel? user;
  const _ProfileTab({required this.user});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _nameCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  File?  _newAvatar;
  bool   _saving      = false;
  bool   _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _init(String name) {
    if (!_initialized) {
      _nameCtrl.text = name;
      _initialized   = true;
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');
      final fs = ref.read(firestoreServiceProvider);

      await fs.updateName(uid, _nameCtrl.text.trim());

      if (_newAvatar != null) {
        final storageRef =
            FirebaseStorage.instance.ref('profiles/$uid/avatar.jpg');
        await storageRef.putFile(_newAvatar!);
        final url = await storageRef.getDownloadURL();
        await fs.updateProfileImage(uid, url);
      }

      ref.invalidate(userProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated!'),
        backgroundColor: AppColors.teal,
      ));
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
    final user = widget.user;
    if (user != null) _init(user.fullName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Avatar ─────────────────────────────────────
            GestureDetector(
              onTap: _saving ? null : _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.tealLight,
                    backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!) as ImageProvider
                        : (user?.profileImage.isNotEmpty == true
                            ? NetworkImage(user!.profileImage) as ImageProvider
                            : null),
                    child: (_newAvatar == null &&
                            (user?.profileImage.isEmpty ?? true))
                        ? Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 17, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Tap photo to change',
                style: TextStyle(fontSize: 11.5, color: AppColors.mute)),
            const SizedBox(height: 28),

            // ── Name ───────────────────────────────────────
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
                if (v == null || v.trim().isEmpty) return 'Name cannot be empty';
                if (v.trim().length < 3) return 'At least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Read-only info ─────────────────────────────
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
                  icon: Icons.star_outline_rounded,
                  label: 'Trust Score',
                  value: '${user.trustScore.toStringAsFixed(1)} / 100'),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: user.verified
                      ? Icons.verified_user
                      : Icons.pending_outlined,
                  label: 'Account',
                  value: user.verified ? 'Verified ✓' : 'Not Verified',
                  valueColor:
                      user.verified ? AppColors.teal : AppColors.marigoldDark),
              const SizedBox(height: 8),
              _KycStatusRow(kycStatus: user.kycStatus),
            ],

            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────
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
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 — KYC Submission
// ═══════════════════════════════════════════════════════════════

class _KycTab extends ConsumerStatefulWidget {
  final UserModel? user;
  const _KycTab({required this.user});

  @override
  ConsumerState<_KycTab> createState() => _KycTabState();
}

class _KycTabState extends ConsumerState<_KycTab> {
  File? _idFile;
  File? _selfieFile;
  bool  _uploading = false;
  String? _error;

  Future<void> _pickId() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) setState(() => _idFile = File(picked.path));
  }

  Future<void> _pickSelfie() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null && mounted) setState(() => _selfieFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (_idFile == null || _selfieFile == null) {
      setState(() => _error = 'Please upload both your Government ID and Selfie.');
      return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final storage = FirebaseStorage.instance;

      final idRef = storage.ref('kyc/$uid/government_id.jpg');
      await idRef.putFile(_idFile!);
      final idUrl = await idRef.getDownloadURL();

      final selfieRef = storage.ref('kyc/$uid/selfie.jpg');
      await selfieRef.putFile(_selfieFile!);
      final selfieUrl = await selfieRef.getDownloadURL();

      await ref.read(firestoreServiceProvider).submitKyc(
            uid: uid,
            governmentIdUrl: idUrl,
            selfieUrl: selfieUrl,
          );

      ref.invalidate(userProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('KYC documents submitted! Admin will review within 24 hours.'),
        backgroundColor: AppColors.teal,
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final kycStatus = user?.kycStatus ?? KycStatus.none;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────────────
          _KycBanner(kycStatus: kycStatus, rejectReason: user?.kycRejectReason ?? ''),
          const SizedBox(height: 24),

          // ── Already verified ───────────────────────────────
          if (kycStatus == KycStatus.verified) ...[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_user, size: 72, color: AppColors.teal),
                  SizedBox(height: 12),
                  Text(
                    'Your identity is verified ✓',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your KYC documents have been approved by our team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mute),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Instructions ─────────────────────────────────
            const Text('Identity Verification',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text(
              'Upload a clear photo of your Government ID (Aadhaar/PAN) '
              'and take a selfie. Our team reviews within 24 hours.',
              style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Government ID ─────────────────────────────────
            const Text('Government ID',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            _UploadTile(
              icon: Icons.badge_outlined,
              title: _idFile != null ? '✓ ID selected' : 'Upload Aadhaar / PAN',
              subtitle: 'JPG or PNG · max 5 MB',
              picked: _idFile != null,
              disabled: _uploading,
              onTap: _pickId,
            ),
            const SizedBox(height: 16),

            // ── Selfie ────────────────────────────────────────
            const Text('Live Selfie',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            _UploadTile(
              icon: Icons.face_retouching_natural,
              title: _selfieFile != null ? '✓ Selfie captured' : 'Take a live selfie',
              subtitle: 'Camera · matched against your ID',
              picked: _selfieFile != null,
              disabled: _uploading,
              onTap: _pickSelfie,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: AppColors.coral, fontSize: 12)),
            ],

            const SizedBox(height: 28),

            if (kycStatus == KycStatus.submitted) ...[
              AppCard(
                bg: AppColors.warnBg,
                borderColor: Colors.transparent,
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        color: AppColors.marigoldDark, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your documents are under review. '
                        'You can re-submit if needed.',
                        style:
                            TextStyle(fontSize: 12.5, color: AppColors.marigoldDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _submit,
                icon: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(_uploading ? 'Uploading…' : 'Submit for Verification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _KycStatusRow extends StatelessWidget {
  final String kycStatus;
  const _KycStatusRow({required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (kycStatus) {
      case KycStatus.verified:
        color = AppColors.teal;
        label = 'KYC Verified ✓';
        icon  = Icons.verified_user;
        break;
      case KycStatus.submitted:
        color = AppColors.marigoldDark;
        label = 'KYC Under Review';
        icon  = Icons.hourglass_top_rounded;
        break;
      case KycStatus.rejected:
        color = AppColors.coral;
        label = 'KYC Rejected';
        icon  = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.mute;
        label = 'KYC Not Submitted';
        icon  = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text('KYC Status',
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const Spacer(),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _KycBanner extends StatelessWidget {
  final String kycStatus;
  final String rejectReason;
  const _KycBanner({required this.kycStatus, required this.rejectReason});

  @override
  Widget build(BuildContext context) {
    switch (kycStatus) {
      case KycStatus.verified:
        return const SizedBox.shrink();
      case KycStatus.submitted:
        return AppCard(
          bg: AppColors.tealLight,
          borderColor: Colors.transparent,
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.teal, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your KYC documents are being reviewed. '
                  'This usually takes up to 24 hours.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.teal),
                ),
              ),
            ],
          ),
        );
      case KycStatus.rejected:
        return AppCard(
          bg: AppColors.coralLight,
          borderColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.coral, size: 18),
                  SizedBox(width: 8),
                  Text('KYC Rejected',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.coral)),
                ],
              ),
              if (rejectReason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Reason: $rejectReason',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.coral)),
              ],
              const SizedBox(height: 6),
              const Text('Please re-upload correct documents below.',
                  style: TextStyle(fontSize: 12, color: AppColors.coral)),
            ],
          ),
        );
      default:
        return AppCard(
          bg: AppColors.warnBg,
          borderColor: Colors.transparent,
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.marigoldDark, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Submit your KYC to unlock the Trust Ring and '
                  'increase your visibility to employers.',
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.marigoldDark),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _UploadTile extends StatelessWidget {
  final IconData    icon;
  final String      title;
  final String      subtitle;
  final bool        picked;
  final bool        disabled;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.picked,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: picked ? AppColors.tealLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: picked ? AppColors.teal : AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: picked ? AppColors.teal : AppColors.mute, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: picked ? AppColors.teal : AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                ],
              ),
            ),
            Icon(
              picked ? Icons.check_circle_rounded : Icons.add_circle_outline,
              color: picked ? AppColors.teal : AppColors.mute,
            ),
          ],
        ),
      ),
    );
  }
}
