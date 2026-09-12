import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/routes/app_routes.dart';
import '../models/application_model.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../screens/employer/employer_jobs_screen.dart'
    show selectedEmployerJobProvider;
import '../theme.dart';
import '../widgets.dart';

// ─────────────────────────────────────────────────────────────
// Provider that holds the application selected for payment
// ─────────────────────────────────────────────────────────────
final selectedApplicationForEscrowProvider =
    StateProvider<ApplicationModel?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
// MOCK (legacy) — kept so nothing breaks if something still
// imports MockPostJobScreen.
// ═══════════════════════════════════════════════════════════════
class MockPostJobScreen extends StatelessWidget {
  const MockPostJobScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Use /postJob instead.')),
      );
}

// Legacy stub — real ApplicantsScreen is in employer/applicants_screen.dart
class ApplicantsScreen extends StatelessWidget {
  const ApplicantsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Use /applicants instead.')),
      );
}

// ═══════════════════════════════════════════════════════════════
// ESCROW SCREEN — real Razorpay payment
// ═══════════════════════════════════════════════════════════════

/// IMPORTANT: Replace this with your actual Razorpay KEY ID from
/// https://dashboard.razorpay.com/app/keys
/// Use 'rzp_test_...' for testing, 'rzp_live_...' for production.
///
/// HOW TO GET IT:
/// 1. Go to https://dashboard.razorpay.com/app/keys
/// 2. Click "Generate Key" under Test Mode
/// 3. Copy the Key ID (starts with rzp_test_)
/// 4. Paste it below replacing the placeholder
const _razorpayKey = 'rzp_test_REPLACE_WITH_YOUR_KEY';

class EscrowScreen extends ConsumerStatefulWidget {
  const EscrowScreen({super.key});

  @override
  ConsumerState<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends ConsumerState<EscrowScreen> {
  late Razorpay _razorpay;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onSuccess(PaymentSuccessResponse response) async {
    setState(() => _processing = true);
    try {
      final job = ref.read(selectedEmployerJobProvider);
      final app = ref.read(selectedApplicationForEscrowProvider);
      final uid = ref.read(currentFirebaseUserProvider)?.uid ?? '';

      if (job != null) {
        // Record escrow in Firestore
        await ref.read(firestoreServiceProvider).recordEscrow(
              jobId: job.id,
              applicationId: app?.id ?? '',
              employerId: uid,
              amount: (job.salary).toInt(),
              paymentId: response.paymentId ?? '',
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Escrow funded.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pushNamed(context, AppRoutes.confirmRelease);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment recorded but escrow save failed: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _onError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
      backgroundColor: AppColors.coral,
    ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('External wallet: ${response.walletName}'),
    ));
  }

  void _openRazorpay(int amountPaise, String jobTitle) {
    final options = {
      'key':          _razorpayKey,
      'amount':       amountPaise,           // Razorpay uses paise (₹1 = 100 paise)
      'name':         'TrustHire',
      'description':  'Escrow for: $jobTitle',
      'prefill': {
        'contact': '',
        'email':   ref.read(currentFirebaseUserProvider)?.email ?? '',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open payment: $e'),
        backgroundColor: AppColors.coral,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedEmployerJobProvider);
    final salary = job?.salary ?? 0;
    final amountPaise = (salary * 100).toInt();
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount card
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
                Text(job?.title ?? '—',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.mute)),
              ],
            ),
          ),

          // How escrow works
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('How escrow works'),
                Text(
                  '1. Funds leave your wallet now, held securely by TrustHire\n'
                  '2. Worker sees the job as escrow-funded and begins work\n'
                  '3. Funds released to them only after you confirm completion',
                  style: TextStyle(fontSize: 11.5, height: 1.6),
                ),
              ],
            ),
          ),

          // Payment methods info
          AppCard(
            bg: AppColors.tealLight,
            borderColor: Colors.transparent,
            child: const Row(
              children: [
                Icon(Icons.security, color: AppColors.teal, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Secured by Razorpay. Pay via UPI, credit/debit card, '
                    'net banking, or wallets.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.teal,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _processing || job == null
                ? null
                : () => _openRazorpay(amountPaise, job.title),
            icon: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_outline),
            label: Text(
              _processing
                  ? 'Processing…'
                  : 'Pay ₹${fmt.format(salary.toInt())} via Razorpay',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFIRM RELEASE SCREEN
// ═══════════════════════════════════════════════════════════════

class ConfirmReleaseScreen extends ConsumerStatefulWidget {
  const ConfirmReleaseScreen({super.key});

  @override
  ConsumerState<ConfirmReleaseScreen> createState() =>
      _ConfirmReleaseScreenState();
}

class _ConfirmReleaseScreenState extends ConsumerState<ConfirmReleaseScreen> {
  bool _releasing = false;

  Future<void> _release() async {
    final job = ref.read(selectedEmployerJobProvider);
    final app = ref.read(selectedApplicationForEscrowProvider);
    if (job == null) return;

    setState(() => _releasing = true);
    try {
      await ref.read(firestoreServiceProvider).releaseEscrow(
            jobId: job.id,
            applicationId: app?.id ?? '',
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment released successfully!'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pushNamed(context, AppRoutes.rateScreen);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedEmployerJobProvider);
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: Text(job?.title ?? 'Confirm Release')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EscrowLockBar(
            amountLabel:
                '₹${fmt.format((job?.salary ?? 0).toInt())}',
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlineButton(
                label: 'Raise Dispute',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Dispute raised. Our support team will contact you within 24 hours.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _releasing
                  ? const Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : PrimaryButton(
                      label: 'Release Payment',
                      color: AppColors.teal,
                      onTap: _release,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
