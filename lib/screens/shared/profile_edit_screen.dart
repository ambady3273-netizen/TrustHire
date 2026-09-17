import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Profile Edit + KYC Submission Screen
// Accessible from all 3 roles via the person icon in the AppBar.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    _tabs = TabController(length: 3, vsync: this);
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
            Tab(icon: Icon(Icons.work_outline), text: 'CV'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProfileTab(user: user),
          _KycTab(user: user),
          _CvTab(user: user),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 1 â€” Profile Edit
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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

            // â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

            // â”€â”€ Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

            // â”€â”€ Read-only info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  value: user.verified ? 'Verified âœ“' : 'Not Verified',
                  valueColor:
                      user.verified ? AppColors.teal : AppColors.marigoldDark),
              const SizedBox(height: 8),
              _KycStatusRow(kycStatus: user.kycStatus),
            ],

            const SizedBox(height: 32),

            // â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

            const SizedBox(height: 20),

            // â”€â”€ Quick links â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _ProfileLink(
              icon:  Icons.work_history_outlined,
              label: 'Work History',
              color: AppColors.teal,
              onTap: () => Navigator.pushNamed(context, '/workHistory'),
            ),
            const SizedBox(height: 10),
            _ProfileLink(
              icon:  Icons.people_alt_outlined,
              label: 'Refer a Friend',
              color: AppColors.marigoldDark,
              onTap: () => Navigator.pushNamed(context, '/referral'),
            ),
            const SizedBox(height: 10),
            _ProfileLink(
              icon:  Icons.translate,
              label: 'Language / à®®à¯Šà®´à®¿ / à¤­à¤¾à¤·à¤¾',
              color: AppColors.ink,
              onTap: () => Navigator.pushNamed(context, '/language'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mute),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 2 â€” KYC Submission
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
          // â”€â”€ Status banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _KycBanner(kycStatus: kycStatus, rejectReason: user?.kycRejectReason ?? ''),
          const SizedBox(height: 24),

          // â”€â”€ Already verified â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (kycStatus == KycStatus.verified) ...[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_user, size: 72, color: AppColors.teal),
                  SizedBox(height: 12),
                  Text(
                    'Your identity is verified âœ“',
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
            // â”€â”€ Instructions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

            // â”€â”€ Government ID â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Text('Government ID',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            _UploadTile(
              icon: Icons.badge_outlined,
              title: _idFile != null ? 'âœ“ ID selected' : 'Upload Aadhaar / PAN',
              subtitle: 'JPG or PNG Â· max 5 MB',
              picked: _idFile != null,
              disabled: _uploading,
              onTap: _pickId,
            ),
            const SizedBox(height: 16),

            // â”€â”€ Selfie â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Text('Live Selfie',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            _UploadTile(
              icon: Icons.face_retouching_natural,
              title: _selfieFile != null ? 'âœ“ Selfie captured' : 'Take a live selfie',
              subtitle: 'Camera Â· matched against your ID',
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
                label: Text(_uploading ? 'Uploadingâ€¦' : 'Submit for Verification'),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Shared helper widgets
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        label = 'KYC Verified âœ“';
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 3 â€” CV / Skills  (Professional redesign with file upload)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _CvTab extends ConsumerStatefulWidget {
  final UserModel? user;
  const _CvTab({required this.user});

  @override
  ConsumerState<_CvTab> createState() => _CvTabState();
}

class _CvTabState extends ConsumerState<_CvTab> {
  final _bioCtrl        = TextEditingController();
  final _skillsCtrl     = TextEditingController();
  final _experienceCtrl = TextEditingController();
  bool   _saving      = false;
  bool   _initialized = false;
  bool   _uploadingCv = false;
  String? _pickedFileName;

  @override
  void dispose() {
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _init(UserModel u) {
    if (_initialized) return;
    _bioCtrl.text        = u.bio;
    _skillsCtrl.text     = u.skills;
    _experienceCtrl.text = u.experience;
    _initialized = true;
  }

  Future<void> _pickAndUploadCv() async {
    final result = await FilePicker.platform.pickFiles(
      type:             FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() { _uploadingCv = true; _pickedFileName = file.name; });
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final storageRef = FirebaseStorage.instance
          .ref('cvs/$uid/${file.name}');
      await storageRef.putFile(File(file.path!));
      final url = await storageRef.getDownloadURL();

      await ref.read(firestoreServiceProvider).updateCv(
            uid:        uid,
            bio:        _bioCtrl.text.trim(),
            skills:     _skillsCtrl.text.trim(),
            experience: _experienceCtrl.text.trim(),
            cvFileUrl:  url,
            cvFileName: file.name,
          );

      ref.invalidate(userProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CV uploaded successfully!'),
        backgroundColor: AppColors.teal,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _uploadingCv = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');
      await ref.read(firestoreServiceProvider).updateCv(
            uid:        uid,
            bio:        _bioCtrl.text.trim(),
            skills:     _skillsCtrl.text.trim(),
            experience: _experienceCtrl.text.trim(),
          );
      ref.invalidate(userProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CV saved!'),
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
    if (user != null) _init(user);

    final hasSkills = user != null && user.skills.isNotEmpty;
    final hasCvFile = user != null && user.cvFileUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // â”€â”€ Completeness bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (user != null) _CvCompletionBar(user: user),
          const SizedBox(height: 20),

          // â•â•â• SECTION 1: About Me â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _SectionCard(
            icon: Icons.person_outline,
            title: 'About Me',
            subtitle: 'Tell employers who you are',
            child: TextField(
              controller: _bioCtrl,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'e.g. "Hardworking and reliable delivery partner '
                    'with 2 years of experience in Nagercoil. '
                    'Punctual, honest, and always on time."',
                hintStyle: const TextStyle(
                    fontSize: 12.5, color: AppColors.mute),
                filled:    true,
                fillColor: AppColors.paper,
                border:    OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // â•â•â• SECTION 2: Skills â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _SectionCard(
            icon: Icons.bolt_outlined,
            title: 'Skills',
            subtitle: 'Separate multiple skills with commas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _skillsCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Driving, Cooking, MS Excel, Customer Service',
                    hintStyle: const TextStyle(
                        fontSize: 12.5, color: AppColors.mute),
                    prefixIcon: const Icon(Icons.label_outline, size: 18),
                    filled:    true,
                    fillColor: AppColors.paper,
                    border:    OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:   BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:   BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                // Live skill chips preview
                if (hasSkills || _skillsCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (_skillsCtrl.text.isNotEmpty
                            ? _skillsCtrl.text
                            : user?.skills ?? '')
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.teal.withAlpha(80)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // â•â•â• SECTION 3: Work Experience â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          _SectionCard(
            icon: Icons.work_history_outlined,
            title: 'Work Experience',
            subtitle: 'List your past jobs and duration',
            child: TextField(
              controller: _experienceCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'e.g.\nâ€¢ Swiggy Delivery â€” 2 years (2022â€“2024)\n'
                    'â€¢ Retail Assistant at D-Mart â€” 1 year (2021â€“2022)\n'
                    'â€¢ Freelance AC repair â€” 6 months',
                hintStyle: const TextStyle(
                    fontSize: 12, color: AppColors.mute),
                filled:    true,
                fillColor: AppColors.paper,
                border:    OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // â•â•â• SECTION 4: CV File Upload â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:        AppColors.ink.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: AppColors.ink, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resume / CV File',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.ink)),
                          Text('PDF, DOC, or image â€” max 5 MB',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.mute)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Existing file indicator
                if (hasCvFile) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.cvFileName.isNotEmpty
                                ? user.cvFileName
                                : 'CV uploaded',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Uploaded âœ“',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.teal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_pickedFileName != null && !_uploadingCv) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded,
                            color: AppColors.teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickedFileName!,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _uploadingCv ? null : _pickAndUploadCv,
                    icon: _uploadingCv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.ink))
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      _uploadingCv
                          ? 'Uploadingâ€¦'
                          : hasCvFile
                              ? 'Replace CV File'
                              : 'Upload CV / Resume',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_saving || _uploadingCv) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving ? 'Savingâ€¦' : 'Save CV',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Employers see your CV when reviewing your application.',
              style: TextStyle(fontSize: 11.5, color: AppColors.mute),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CV Completion progress bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CvCompletionBar extends StatelessWidget {
  final UserModel user;
  const _CvCompletionBar({required this.user});

  @override
  Widget build(BuildContext context) {
    int filled = 0;
    if (user.bio.isNotEmpty)        filled++;
    if (user.skills.isNotEmpty)     filled++;
    if (user.experience.isNotEmpty) filled++;
    if (user.cvFileUrl.isNotEmpty)  filled++;
    const total = 4;
    final pct = filled / total;

    final color = pct >= 1.0
        ? AppColors.teal
        : pct >= 0.5
            ? AppColors.marigoldDark
            : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CV Completeness',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color),
              ),
              Text(
                '$filled / $total sections',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:           pct,
              minHeight:       8,
              backgroundColor: color.withAlpha(30),
              valueColor:      AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Pill(label: 'Bio',        done: user.bio.isNotEmpty),
              _Pill(label: 'Skills',     done: user.skills.isNotEmpty),
              _Pill(label: 'Experience', done: user.experience.isNotEmpty),
              _Pill(label: 'CV File',    done: user.cvFileUrl.isNotEmpty),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool   done;
  const _Pill({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        done
            ? AppColors.teal.withAlpha(20)
            : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? AppColors.teal.withAlpha(80)
              : Colors.grey.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size:  12,
            color: done ? AppColors.teal : AppColors.mute,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize:   10.5,
                  color:      done ? AppColors.teal : AppColors.mute,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Reusable section card for CV sections
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Widget   child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        AppColors.teal.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.mute)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
