import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Job Seeker Dashboard — streams approved jobs live from Firestore.
class SeekerDashboard extends ConsumerWidget {
  const SeekerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final displayName = userAsync.maybeWhen(
      data: (u) => u?.fullName ?? 'Job Seeker',
      orElse: () => 'Job Seeker',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Applications',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, '/myApplications'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _SeekerBody(displayName: displayName),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body — live Firestore job feed
// ─────────────────────────────────────────────────────────────

class _SeekerBody extends ConsumerStatefulWidget {
  final String displayName;
  const _SeekerBody({required this.displayName});

  @override
  ConsumerState<_SeekerBody> createState() => _SeekerBodyState();
}

class _SeekerBodyState extends ConsumerState<_SeekerBody> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Delivery',
    'Retail',
    'Restaurant',
    'Data Entry',
    'Tutoring',
    'Customer Service',
    'Freelance',
    'Office Work',
    'Event Work',
    'Other',
  ];

  List<JobModel> _filter(List<JobModel> jobs) {
    return jobs.where((job) {
      final matchesSearch = _searchQuery.isEmpty ||
          job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || job.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(approvedJobsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome + search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Welcome, ${widget.displayName} 👋',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search jobs by title, company or location…',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected ? AppColors.ink : AppColors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.mute,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        // Job list
        Expanded(
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(approvedJobsProvider),
            ),
            data: (jobs) {
              final filtered = _filter(jobs);
              if (filtered.isEmpty) {
                return _EmptyView(
                  searchActive: _searchQuery.isNotEmpty ||
                      _selectedCategory != 'All',
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (context, i) =>
                    _JobCard(job: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual job card
// ─────────────────────────────────────────────────────────────

class _JobCard extends ConsumerWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = job.status == 'approved' && job.riskScore < 31;

    return InkWell(
      onTap: () {
        // Store selected job so JobDetailsScreen can read it.
        ref.read(selectedJobProvider.notifier).state = job;
        Navigator.pushNamed(context, '/jobDetails');
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(
                  isVerified ? '✓ AI-verified' : '⚠ Under review',
                  type: isVerified
                      ? BadgeType.verified
                      : BadgeType.warn,
                ),
                Text(
                  job.category,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${job.companyName} · ${job.location}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.mute,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${job.salary.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.ink,
                  ),
                ),
                Row(
                  children: [
                    TrustRing(
                      percent: (100 - job.riskScore).clamp(0, 100),
                      size: 28,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Trust',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.mute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty / Error views
// ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool searchActive;
  const _EmptyView({required this.searchActive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive
                  ? Icons.search_off
                  : Icons.work_off_outlined,
              size: 64,
              color: AppColors.mute,
            ),
            const SizedBox(height: 16),
            Text(
              searchActive
                  ? 'No jobs match your search.'
                  : 'No approved jobs yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mute,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.coral),
            const SizedBox(height: 16),
            Text(
              'Failed to load jobs.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
