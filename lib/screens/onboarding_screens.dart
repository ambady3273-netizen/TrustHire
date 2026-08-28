import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

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
                decoration: const BoxDecoration(color: AppColors.marigold, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.ink, size: 40),
              ),
              const SizedBox(height: 22),
              const Text('TrustHire',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Verified employers. Protected pay.\nReal part-time work, near you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC9D2E6), fontSize: 13.5, height: 1.5),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Get started',
                color: AppColors.marigold,
                textColor: AppColors.inkDark,
                onTap: () => Navigator.pushNamed(context, '/role'),
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
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('You can add the other role later from Settings.',
                style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 22),
            AppCard(
              borderColor: AppColors.ink,
              borderWidth: 2,
              child: _RoleRow(
                icon: Icons.person_outline,
                bg: AppColors.tealLight,
                fg: AppColors.teal,
                title: "I'm looking for work",
                subtitle: 'Find verified part-time jobs nearby',
              ),
            ),
            AppCard(
              child: _RoleRow(
                icon: Icons.storefront_outlined,
                bg: AppColors.warnBg,
                fg: AppColors.marigoldDark,
                title: "I'm hiring",
                subtitle: 'Post jobs after business verification',
              ),
            ),
            const Spacer(),
            PrimaryButton(label: 'Continue', onTap: () => Navigator.pushNamed(context, '/kyc')),
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
  const _RoleRow({required this.icon, required this.bg, required this.fg, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
            ],
          ),
        ),
      ],
    );
  }
}

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});
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
            const Text('This unlocks your Trust Ring and lets employers see you\'re real.',
                style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 18),
            const LabelSmall('Government ID'),
            _uploadBox(Icons.description_outlined, 'Upload Aadhaar / PAN', 'JPG, PNG or PDF · under 5MB'),
            const SizedBox(height: 14),
            const LabelSmall('Selfie match'),
            _uploadBox(Icons.face_retouching_natural, 'Take a live selfie', 'Matched automatically against your ID'),
            const Spacer(),
            const Center(
              child: Text('Reviewed within 24 hours', style: TextStyle(fontSize: 11, color: AppColors.mute)),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Submit for verification',
              onTap: () => Navigator.pushNamed(context, '/trustIntro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadBox(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.mute, size: 26),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.mute)),
        ],
      ),
    );
  }
}

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
            const AppBadge('✓ Identity confirmed', type: BadgeType.verified),
            const SizedBox(height: 18),
            const TrustRing(percent: 35, size: 92),
            const SizedBox(height: 16),
            const Text('This is your Trust Ring',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text(
              "It grows as you complete jobs, collect reviews, and stay complaint-free. Everyone you work with can see it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.mute, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Ways to grow it', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(height: 8),
                  _GrowRow(label: '✓ ID verified', points: '+20'),
                  _GrowRow(label: 'Complete your first job', points: '+15'),
                  _GrowRow(label: 'Get 5 reviews above 4★', points: '+15'),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Find your first job',
              color: AppColors.marigold,
              textColor: AppColors.inkDark,
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/jobFeed', (r) => r.isFirst),
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
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
          Text(points, style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
