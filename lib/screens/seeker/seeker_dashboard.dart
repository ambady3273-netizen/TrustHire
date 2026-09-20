import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../screens/seeker/saved_jobs_screen.dart'
    show bookmarkedIdsProvider;
import '../../services/location_service.dart';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire'),
          ],
        ),
        actions: [
          _NotifBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (route) => Navigator.pushNamed(context, route),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: '/savedJobs',
                child: Row(children: [
                  Icon(Icons.bookmark_outline, size: 18),
                  SizedBox(width: 10),
                  Text('Saved Jobs'),
                ]),
              ),
              PopupMenuItem(
                value: '/editProfile',
                child: Row(children: [
                  Icon(Icons.person_outline, size: 18),
                  SizedBox(width: 10),
                  Text('My Profile'),
                ]),
              ),
              PopupMenuItem(
                value: '/chats',
                child: Row(children: [
                  Icon(Icons.chat_bubble_outline, size: 18),
                  SizedBox(width: 10),
                  Text('Messages'),
                ]),
              ),
              PopupMenuItem(
                value: '/myApplications',
                child: Row(children: [
                  Icon(Icons.receipt_long_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('My Applications'),
                ]),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              // AuthGate automatically shows LoginScreen
              // when userProvider emits null — no navigation needed.
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
  bool   _nearMe = false;
  Position? _seekerPosition;
  bool _fetchingLocation = false;
  double _minSalary = 0;
  double _maxSalary = 150000;
  bool   _salaryFilterActive = false;

  static const double _nearMeRadiusMetres = 20000; // 20 km

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
    'Domestic Help',
    'Security Guard',
    'Driver',
    'AC Technician',
    'Plumber',
    'Electrician',
    'Salon Work',
    'Tailoring',
    'Construction',
    'Other',
  ];

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() { _nearMe = false; _seekerPosition = null; });
      return;
    }
    setState(() => _fetchingLocation = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      setState(() { _seekerPosition = pos; _nearMe = true; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Check permissions.'),
          backgroundColor: Color(0xFFE15B4F),
        ),
      );
    }
    setState(() => _fetchingLocation = false);
  }

  List<JobModel> _filter(List<JobModel> jobs) {
    return jobs.where((job) {
      final matchesSearch = _searchQuery.isEmpty ||
          job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' || job.category == _selectedCategory;

      bool matchesNearMe = true;
      if (_nearMe && _seekerPosition != null) {
        if (job.latitude != null && job.longitude != null) {
          final dist = Geolocator.distanceBetween(
            _seekerPosition!.latitude,
            _seekerPosition!.longitude,
            job.latitude!,
            job.longitude!,
          );
          matchesNearMe = dist <= _nearMeRadiusMetres;
        } else {
          matchesNearMe = false;
        }
      }

      final matchesSalary = !_salaryFilterActive ||
          (job.salary >= _minSalary && job.salary <= _maxSalary);

      return matchesSearch && matchesCategory && matchesNearMe && matchesSalary;
    }).toList();
  }

  void _showSalaryFilter() {
    double tmpMin = _minSalary;
    double tmpMax = _maxSalary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Salary Range',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setS(() { tmpMin = 0; tmpMax = 150000; });
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: AppColors.coral)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${(tmpMin / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal)),
                  Text('₹${(tmpMax / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal)),
                ],
              ),
              RangeSlider(
                values: RangeValues(tmpMin, tmpMax),
                min: 0,
                max: 150000,
                divisions: 30,
                activeColor: AppColors.teal,
                labels: RangeLabels(
                  '₹${(tmpMin / 1000).toStringAsFixed(0)}k',
                  '₹${(tmpMax / 1000).toStringAsFixed(0)}k',
                ),
                onChanged: (v) =>
                    setS(() { tmpMin = v.start; tmpMax = v.end; }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minSalary = tmpMin;
                      _maxSalary = tmpMax;
                      _salaryFilterActive =
                          !(tmpMin == 0 && tmpMax == 150000);
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filter',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

        // Near Me toggle + Salary filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _fetchingLocation ? null : _toggleNearMe,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _nearMe ? AppColors.teal : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            _nearMe ? AppColors.teal : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _fetchingLocation
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal),
                            )
                          : Icon(Icons.near_me,
                              size: 13,
                              color: _nearMe
                                  ? Colors.white
                                  : AppColors.mute),
                      const SizedBox(width: 5),
                      Text(
                        _nearMe ? 'Near Me ✓' : 'Near Me',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _nearMe
                              ? Colors.white
                              : AppColors.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showSalaryFilter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _salaryFilterActive
                        ? AppColors.marigoldDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _salaryFilterActive
                            ? AppColors.marigoldDark
                            : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.currency_rupee,
                          size: 13,
                          color: _salaryFilterActive
                              ? Colors.white
                              : AppColors.mute),
                      const SizedBox(width: 4),
                      Text(
                        _salaryFilterActive
                            ? '₹${(_minSalary / 1000).toStringAsFixed(0)}k–₹${(_maxSalary / 1000).toStringAsFixed(0)}k'
                            : 'Salary',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _salaryFilterActive
                              ? Colors.white
                              : AppColors.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

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
                    _JobCard(
                      job: filtered[i],
                      seekerPosition: _seekerPosition,
                    ),
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
  final Position? seekerPosition;
  const _JobCard({required this.job, this.seekerPosition});

  String? _distanceLabel() {
    if (seekerPosition == null) return null;
    if (job.latitude == null || job.longitude == null) return null;
    final metres = Geolocator.distanceBetween(
      seekerPosition!.latitude,
      seekerPosition!.longitude,
      job.latitude!,
      job.longitude!,
    );
    if (metres < 1000) return '${metres.toStringAsFixed(0)} m away';
    return '${(metres / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = job.status == 'approved' && job.riskScore < 31;
    final distLabel = _distanceLabel();
    final uid = ref.watch(authServiceProvider).currentUser?.uid ?? '';
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).valueOrNull ?? [];
    final isBookmarked = bookmarkedIds.contains(job.id);

    return InkWell(
      onTap: () {
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
                  type: isVerified ? BadgeType.verified : BadgeType.warn,
                ),
                Row(
                  children: [
                    if (distLabel != null) ...[
                      const Icon(Icons.near_me,
                          size: 11, color: AppColors.teal),
                      const SizedBox(width: 3),
                      Text(distLabel,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                    ],
                    Text(job.category,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.mute)),
                    const SizedBox(width: 4),
                    // Bookmark icon
                    GestureDetector(
                      onTap: () async {
                        if (uid.isEmpty) return;
                        final fs = ref.read(firestoreServiceProvider);
                        if (isBookmarked) {
                          await fs.removeBookmark(uid, job.id);
                        } else {
                          await fs.bookmarkJob(uid, job);
                        }
                      },
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 18,
                        color: isBookmarked
                            ? AppColors.marigoldDark
                            : AppColors.mute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('${job.companyName} · ${job.location}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.mute)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${job.salary.toStringAsFixed(0)}/mo',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink)),
                Row(
                  children: [
                    TrustRing(
                      percent: (100 - job.riskScore).clamp(0, 100),
                      size: 28,
                    ),
                    const SizedBox(width: 5),
                    const Text('Trust',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.mute)),
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

// ─────────────────────────────────────────────────────────────
// Bell icon with live unread badge
// ─────────────────────────────────────────────────────────────

class _NotifBell extends ConsumerWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
