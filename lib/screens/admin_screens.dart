import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminFraudScreen extends StatelessWidget {
  const AdminFraudScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Fraud')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _statTile('23', 'Flagged today', AppColors.coral)),
                const SizedBox(width: 8),
                Expanded(child: _statTile('7', 'Pending KYC', AppColors.marigoldDark)),
                const SizedBox(width: 8),
                Expanded(child: _statTile('318', 'Auto-cleared', AppColors.teal)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 0), child: LabelSmall('Needs review')),
          AppCard(
            borderColor: AppColors.coral,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(child: Text('"Earn ₹5000/day, no exp."', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                    AppBadge('92% risk', type: BadgeType.danger),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Unrealistic salary · scam keywords · duplicate of 3 posts',
                    style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlineButton(label: 'Approve', onTap: () {})),
                    const SizedBox(width: 8),
                    Expanded(child: PrimaryButton(label: 'Remove', color: AppColors.coral, onTap: () {})),
                  ],
                ),
              ],
            ),
          ),
          AppCard(
            borderColor: AppColors.marigold,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Part-time Data Entry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    AppBadge('54% risk', type: BadgeType.warn),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('New employer account, no business docs yet',
                    style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlineButton(label: 'Approve', onTap: () {})),
                    const SizedBox(width: 8),
                    Expanded(child: PrimaryButton(label: 'Remove', color: AppColors.coral, onTap: () {})),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.warning_amber_rounded), label: 'Fraud'),
          NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'Verify'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) Navigator.pushNamed(context, '/adminVerification');
        },
      ),
    );
  }

  Widget _statTile(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.mute), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Verification')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('QuickCart Services', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    AppBadge('Pending', type: BadgeType.warn),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('GST certificate · Owner Aadhaar · Shop photo', style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _docTile(Icons.description_outlined)),
                    const SizedBox(width: 6),
                    Expanded(child: _docTile(Icons.badge_outlined)),
                    const SizedBox(width: 6),
                    Expanded(child: _docTile(Icons.storefront_outlined)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlineButton(label: 'Request more info', onTap: () {})),
                    const SizedBox(width: 8),
                    Expanded(child: PrimaryButton(label: 'Verify', color: AppColors.teal, onTap: () {})),
                  ],
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 10, 16, 0), child: LabelSmall('Disputes needing a decision')),
          AppCard(
            borderColor: AppColors.ink,
            borderWidth: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('₹2,400 escrow dispute', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    Text('#TH-1042', style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Employer: work incomplete · Worker: shift covered fully',
                    style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                const SizedBox(height: 8),
                OutlineButton(label: 'Open case & chat log', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(IconData icon) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 18, color: AppColors.mute),
    );
  }
}
