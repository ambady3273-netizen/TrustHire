import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets.dart';

// ═══════════════════════════════════════════════════════════════
// SPLASH
// ═══════════════════════════════════════════════════════════════

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: AppColors.marigold, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.ink, size: 40),
              ),
              const SizedBox(height: 22),
              const Text('TrustHire',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Verified employers. Protected pay.\nReal part-time work, near you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFC9D2E6),
                    fontSize: 13.5,
                    height: 1.5),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Get started',
                color: AppColors.marigold,
                textColor: AppColors.inkDark,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.role),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('I already have an account', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROLE SELECT
// ═══════════════════════════════════════════════════════════════

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How will you use TrustHire?',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('You can add the other role later from Settings.',
                style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 22),
            AppCard(
              borderColor: AppColors.ink,
              borderWidth: 2,
              child: const _RoleRow(
                icon: Icons.person_outline,
                bg: AppColors.tealLight,
                fg: AppColors.teal,
                title: "I'm looking for work",
                subtitle: 'Find verified part-time jobs nearby',
              ),
            ),
            AppCard(
              child: const _RoleRow(
                icon: Icons.storefront_outlined,
                bg: AppColors.warnBg,
                fg: AppColors.marigoldDark,
                title: "I'm hiring",
                subtitle: 'Post jobs after business verification',
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Continue',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.kyc),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  const _RoleRow({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.mute)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KYC SCREEN — real image_picker + Firebase Storage upload
// ═══════════════════════════════════════════════════════════════

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  File? _idFile;
  File? _selfieFile;
  bool _uploading = false;
  String? _error;

  final _picker = ImagePicker();

  Future<void> _pickId() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _idFile = File(picked.path));
  }

  Future<void> _pickSelfie() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _selfieFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (_idFile == null || _selfieFile == null) {
      setState(() => _error = 'Please upload both your ID and selfie.');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final uid =
          ref.read(authProvider).whenOrNull(data: (u) => u?.uid);
      if (uid == null) throw Exception('Not logged in');

      final storage = FirebaseStorage.instance;

      // Upload government ID
      final idRef =
          storage.ref('kyc/$uid/government_id.jpg');
      await idRef.putFile(_idFile!);
      final idUrl = await idRef.getDownloadURL();

      // Upload selfie
      final selfieRef =
          storage.ref('kyc/$uid/selfie.jpg');
      await selfieRef.putFile(_selfieFile!);

      // Save ID URL to user profile; mark as pending review
      await FirestoreService.instance
          .updateProfileImage(uid, idUrl);

      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.trustIntro);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBadge('Step 2 of 3', type: BadgeType.ink),
            const SizedBox(height: 12),
            const Text(
                "Upload your ID and take a selfie. "
                "This unlocks your Trust Ring.",
                style:
                    TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 18),
            const LabelSmall('Government ID'),
            _UploadBox(
              icon: Icons.description_outlined,
              title: _idFile == null
                  ? 'Upload Aadhaar / PAN'
                  : '✓ ID selected',
              subtitle: 'JPG or PNG · under 5 MB',
              picked: _idFile != null,
              onTap: _uploading ? null : _pickId,
            ),
            const SizedBox(height: 14),
            const LabelSmall('Selfie match'),
            _UploadBox(
              icon: Icons.face_retouching_natural,
              title: _selfieFile == null
                  ? 'Take a live selfie'
                  : '✓ Selfie captured',
              subtitle: 'Camera · matched against your ID',
              picked: _selfieFile != null,
              onTap: _uploading ? null : _pickSelfie,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.coral, fontSize: 12)),
            ],
            const Spacer(),
            const Center(
              child: Text('Reviewed within 24 hours',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.mute)),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: _uploading
                  ? 'Uploading…'
                  : 'Submit for verification',
              onTap: _uploading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool picked;
  final VoidCallback? onTap;

  const _UploadBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.picked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: 22, horizontal: 14),
        decoration: BoxDecoration(
          color: picked
              ? AppColors.tealLight
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: picked ? AppColors.teal : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: picked ? AppColors.teal : AppColors.mute,
                size: 26),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: picked
                        ? AppColors.teal
                        : AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.mute)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRUST INTRO
// ═══════════════════════════════════════════════════════════════

class TrustIntroScreen extends StatelessWidget {
  const TrustIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("You're verified")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const AppBadge('✓ Identity confirmed',
                type: BadgeType.verified),
            const SizedBox(height: 18),
            const TrustRing(percent: 35, size: 92),
            const SizedBox(height: 16),
            const Text('This is your Trust Ring',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text(
              "It grows as you complete jobs, collect reviews, "
              "and stay complaint-free. Everyone you work with can see it.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.mute, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Ways to grow it',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  SizedBox(height: 8),
                  _GrowRow(label: '✓ ID verified', points: '+20'),
                  _GrowRow(
                      label: 'Complete your first job',
                      points: '+15'),
                  _GrowRow(
                      label: 'Get 5 reviews above 4★',
                      points: '+15'),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Find your first job',
              color: AppColors.marigold,
              textColor: AppColors.inkDark,
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.jobFeed, (r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowRow extends StatelessWidget {
  final String label;
  final String points;
  const _GrowRow({required this.label, required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.mute)),
          Text(points,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
