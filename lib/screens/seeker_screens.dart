import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class JobFeedScreen extends StatelessWidget {
  const JobFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final jobs = [
      {
        'badge': 'verified', 'title': 'Weekend Store Assistant', 'sub': 'Meenakshi Textiles · Anna Nagar',
        'dist': '0.8 km', 'pay': '₹600/day', 'trust': 81,
      },
      {
        'badge': 'warn', 'title': 'Delivery Partner — 2 wks', 'sub': 'QuickCart Services · Sellur',
        'dist': '2.1 km', 'pay': '₹9,000 total', 'trust': 40,
      },
      {
        'badge': 'verified', 'title': 'Event Setup Crew (5 needed)', 'sub': 'Sri Kalyanam Events · Goripalayam',
        'dist': '1.4 km', 'pay': '₹800/day', 'trust': 95,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire'),
          ],
        ),
        actions: [
          const Icon(Icons.notifications_none_rounded),
          const SizedBox(width: 12),
          const TrustRing(percent: 62, size: 30),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FieldBox('Search jobs near Madurai', icon: Icons.search),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                AppBadge('All', type: BadgeType.ink),
                SizedBox(width: 8),
                _FilterChip('Delivery'),
                SizedBox(width: 8),
                _FilterChip('Retail'),
                SizedBox(width: 8),
                _FilterChip('Events'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: jobs.length,
              itemBuilder: (context, i) {
                final j = jobs[i];
                return InkWell(
                  onTap: () => Navigator.pushNamed(context, '/jobDetails'),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppBadge(
                              j['badge'] == 'verified' ? '✓ AI-verified' : '⚠ Under review',
                              type: j['badge'] == 'verified' ? BadgeType.verified : BadgeType.warn,
                            ),
                            Text(j['dist'] as String, style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(j['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text(j['sub'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(j['pay'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink)),
                            Row(
                              children: [
                                TrustRing(percent: j['trust'] as int, size: 28),
                                const SizedBox(width: 5),
                                const Text('Employer', style: TextStyle(fontSize: 10, color: AppColors.mute)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Applications'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) Navigator.pushNamed(context, '/chat');
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job details'), actions: const [Icon(Icons.flag_outlined), SizedBox(width: 16)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          const AppBadge('✓ Passed AI fraud check', type: BadgeType.verified),
          const SizedBox(height: 10),
          const Text('Weekend Store Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Meenakshi Textiles · Anna Nagar, Madurai', style: TextStyle(fontSize: 12, color: AppColors.mute)),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                const Avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Meenakshi Textiles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      SizedBox(height: 2),
                      Text('Business verified · 3 yrs on TrustHire', style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                    ],
                  ),
                ),
                const TrustRing(percent: 81, size: 30),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelSmall('Pay & schedule'),
                _kv('Rate', '₹600 / day'),
                _kv('Duration', 'Sat–Sun, 4 weeks'),
                _kv('Payment', '🔒 Escrow protected', valueColor: AppColors.teal),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('Description'),
                Text(
                  'Assist customers, manage billing counter, restock shelves during weekend rush. Prior retail experience preferred but not required.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: 'Apply now',
          color: AppColors.marigold,
          textColor: AppColors.inkDark,
          onTap: () => Navigator.pushNamed(context, '/chat'),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {Color valueColor = AppColors.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Avatar(size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Meenakshi Textiles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('✓ Verified employer', style: TextStyle(fontSize: 10.5, color: AppColors.teal)),
                ],
              ),
            ),
          ],
        ),
        actions: const [Icon(Icons.call_outlined), SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          const EscrowLockBar(amountLabel: '₹2,400'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _bubble("Hi! You're selected for the weekend role. Can you start this Saturday, 10am?", mine: false),
                _bubble('Yes, that works for me!', mine: true),
                const SizedBox(height: 10),
                const Center(child: AppBadge('Payment locked in escrow ✓', type: BadgeType.verified)),
                const SizedBox(height: 10),
                _bubble('Great, see you Saturday at the Anna Nagar store.', mine: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(child: FieldBox('Message…')),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/rate'),
              child: const Text('Demo: mark job complete →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, {required bool mine}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 2),
            bottomRight: Radius.circular(mine ? 2 : 12),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(text, style: TextStyle(fontSize: 12.5, color: mine ? Colors.white : AppColors.text)),
      ),
    );
  }
}

class RateScreen extends StatelessWidget {
  const RateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job complete')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 6),
            const Text('Job completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('₹2,400 has been released to your wallet', style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Escrow released', style: TextStyle(fontSize: 12, color: AppColors.mute)),
                  Text('₹2,400.00', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('Rate Meenakshi Textiles', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => const Icon(Icons.star_rounded, color: AppColors.marigold, size: 30)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FieldBox('Add a note for other job seekers (optional)', height: 60),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Submit review',
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
