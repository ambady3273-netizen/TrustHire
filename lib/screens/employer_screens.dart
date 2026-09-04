import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/job_provider.dart';
import '../theme.dart';
import '../widgets.dart';

// ═══════════════════════════════════════════════════════════════
// ESCROW SCREEN
// ═══════════════════════════════════════════════════════════════

class EscrowScreen extends ConsumerWidget {
  const EscrowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);
    final salary = job?.salary ?? 0;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: const Text('Secure payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.lock, size: 26, color: AppColors.ink),
                const SizedBox(height: 6),
                const Text('Amount to escrow',
                    style: TextStyle(fontSize: 11, color: AppColors.mute)),
                Text(
                  '₹${fmt.format(salary.toInt())}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(job?.title ?? '',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.mute)),
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
                  '2. Worker sees the job as escrow-funded\n'
                  '3. Released to them only after you confirm completion',
                  style: TextStyle(fontSize: 11.5, height: 1.6),
                ),
              ],
            ),
          ),
          const LabelSmall('Pay via'),
          const FieldBox('Razorpay · UPI / Card / Netbanking',
              icon: Icons.credit_card),
          const SizedBox(height: 60),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: 'Deposit ₹${fmt.format(salary.toInt())} into escrow',
          onTap: () => Navigator.pushNamed(context, '/confirmRelease'),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFIRM RELEASE SCREEN
// ═══════════════════════════════════════════════════════════════

class ConfirmReleaseScreen extends ConsumerWidget {
  const ConfirmReleaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);

    return Scaffold(
      appBar: AppBar(title: Text(job?.title ?? 'Confirm Release')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EscrowLockBar(
            amountLabel:
                '₹${NumberFormat('#,##0', 'en_IN').format((job?.salary ?? 0).toInt())}',
          ),
          const SizedBox(height: 6),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('Before you release'),
                Text(
                  '☑ Work was completed as described\n'
                  '☑ Hours match what was agreed\n'
                  '☑ No safety or conduct issues',
                  style: TextStyle(fontSize: 11.5, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Not satisfied? You can raise a dispute instead.',
              style: TextStyle(fontSize: 10.5, color: AppColors.mute),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Row(
          children: [
            Expanded(
                child: OutlineButton(label: 'Raise dispute', onTap: () {})),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Release payment',
                color: AppColors.teal,
                onTap: () => Navigator.pushNamed(context, '/rate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
