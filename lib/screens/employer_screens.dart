import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

/// Mock/demo PostJobScreen used in the prototype navigation flow.
/// The real Firebase-connected PostJobScreen lives at
/// screens/employer/post_job_screen.dart.
class MockPostJobScreen extends StatelessWidget {
  const MockPostJobScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.close),
        title: const Text('New job post'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: Text('1/2', style: TextStyle(fontSize: 11, color: AppColors.mute))))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          const LabelSmall('Job title'),
          const FieldBox('Weekend Store Assistant'),
          const LabelSmall('Category'),
          const FieldBox('Retail & Sales'),
          const LabelSmall('Pay rate'),
          const FieldBox('₹600 / day'),
          const LabelSmall('Location'),
          const FieldBox('Anna Nagar, Madurai', icon: Icons.location_on_outlined),
          const LabelSmall('Description'),
          const FieldBox('Assist customers, manage billing counter, restock shelves...', height: 70),
          AppCard(
            bg: AppColors.tealLight,
            borderColor: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.smart_toy_outlined, color: AppColors.teal, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AI pre-check', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
                      SizedBox(height: 2),
                      Text('Pay rate looks realistic for this category and city. No scam keywords detected.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF245957))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(label: 'Continue to review', onTap: () => Navigator.pushNamed(context, '/applicants')),
      ),
    );
  }
}

class ApplicantsScreen extends StatelessWidget {
  const ApplicantsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final applicants = [
      {'name': 'Priya S.', 'sub': '14 jobs completed · 4.9★', 'trust': 92, 'highlight': false, 'faded': false},
      {'name': 'Arun K.', 'sub': '3 jobs completed · 4.6★', 'trust': 68, 'highlight': false, 'faded': false},
      {'name': 'Divya M.', 'sub': '27 jobs completed · 5.0★', 'trust': 97, 'highlight': true, 'faded': false},
      {'name': 'New applicant', 'sub': '0 jobs completed', 'trust': 20, 'highlight': false, 'faded': true},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants (6)'), actions: const [Icon(Icons.more_horiz), SizedBox(width: 12)]),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        children: applicants.map((a) {
          return Opacity(
            opacity: (a['faded'] as bool) ? 0.55 : 1,
            child: AppCard(
              borderColor: (a['highlight'] as bool) ? AppColors.ink : null,
              borderWidth: (a['highlight'] as bool) ? 2 : 1,
              child: Row(
                children: [
                  const Avatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(a['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            if (a['highlight'] as bool) ...[
                              const SizedBox(width: 6),
                              const AppBadge('Top rated', type: BadgeType.verified),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(a['sub'] as String, style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
                      ],
                    ),
                  ),
                  TrustRing(percent: a['trust'] as int, size: 30),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: 'Select Divya M. & fund escrow',
          color: AppColors.marigold,
          textColor: AppColors.inkDark,
          onTap: () => Navigator.pushNamed(context, '/escrow'),
        ),
      ),
    );
  }
}

class EscrowScreen extends StatelessWidget {
  const EscrowScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: const [
                Icon(Icons.lock, size: 26, color: AppColors.ink),
                SizedBox(height: 6),
                Text('Amount to escrow', style: TextStyle(fontSize: 11, color: AppColors.mute)),
                Text('₹9,600', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: 4),
                Text('4 weekends × ₹2,400', style: TextStyle(fontSize: 10, color: AppColors.mute)),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('How escrow works'),
                Text(
                  '1. Funds leave your wallet now, held by TrustHire\n'
                  '2. Divya sees the job as escrow-funded\n'
                  '3. Released to her only after you confirm completion',
                  style: TextStyle(fontSize: 11.5, height: 1.6),
                ),
              ],
            ),
          ),
          const LabelSmall('Pay via'),
          const FieldBox('Razorpay · UPI / Card / Netbanking', icon: Icons.credit_card),
          const SizedBox(height: 60),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: 'Deposit ₹9,600 into escrow',
          onTap: () => Navigator.pushNamed(context, '/confirmRelease'),
        ),
      ),
    );
  }
}

class ConfirmReleaseScreen extends StatelessWidget {
  const ConfirmReleaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekend Store Assistant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EscrowLockBar(amountLabel: '₹2,400'),
          const SizedBox(height: 6),
          AppCard(
            child: Row(
              children: const [
                Avatar(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Divya M.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      SizedBox(height: 2),
                      Text("Marked this weekend's shift as done", style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('Before you release'),
                Text(
                  '☑ Work was completed as described\n☑ Hours match what was agreed\n☑ No safety or conduct issues',
                  style: TextStyle(fontSize: 11.5, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Not satisfied? You can raise a dispute instead.', style: TextStyle(fontSize: 10.5, color: AppColors.mute)),
          ),
          const SizedBox(height: 70),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Row(
          children: [
            Expanded(child: OutlineButton(label: 'Raise dispute', onTap: () {})),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Release ₹2,400',
                color: AppColors.teal,
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
