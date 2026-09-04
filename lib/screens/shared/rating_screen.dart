import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/application_model.dart';
import '../../models/rating_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Allows a user to rate the other party after a completed job.
/// Pass [application] via [selectedApplicationForRatingProvider].
final selectedApplicationForRatingProvider =
    StateProvider<ApplicationModel?>((ref) => null);

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _alreadyRated = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAlreadyRated();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyRated() async {
    final app = ref.read(selectedApplicationForRatingProvider);
    final uid = ref.read(currentFirebaseUserProvider)?.uid;
    if (app == null || uid == null) {
      setState(() => _checking = false);
      return;
    }
    final rated = await ref.read(firestoreServiceProvider).hasRated(
          applicationId: app.id,
          reviewerId: uid,
        );
    if (mounted) setState(() { _alreadyRated = rated; _checking = false; });
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final app = ref.read(selectedApplicationForRatingProvider);
    final userModel = ref.read(userProvider).valueOrNull;
    final uid = ref.read(currentFirebaseUserProvider)?.uid;

    if (app == null || uid == null || userModel == null) return;

    // Extra client-side guard: only participants can rate.
    if (uid != app.seekerId && uid != app.employerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not a participant in this application.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    // Determine reviewer/reviewee before self-rating check.
    final isSeeker = uid == app.seekerId;
    final revieweeId = isSeeker ? app.employerId : app.seekerId;
    final revieweeName = isSeeker ? app.companyName : app.seekerName;

    // Prevent self-rating.
    if (uid == revieweeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot rate yourself.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final rating = RatingModel(
        id: '',
        applicationId: app.id,
        jobId: app.jobId,
        jobTitle: app.jobTitle,
        reviewerId: uid,
        reviewerName: userModel.fullName,
        revieweeId: revieweeId,
        revieweeName: revieweeName,
        stars: _stars,
        comment: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).submitRating(rating);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted! Thank you.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(selectedApplicationForRatingProvider);
    final uid = ref.watch(currentFirebaseUserProvider)?.uid;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate')),
        body: const Center(child: Text('No application selected.')),
      );
    }

    final isSeeker = uid == app.seekerId;
    final revieweeName = isSeeker ? app.companyName : app.seekerName;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Leave a Review')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : _alreadyRated
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 64, color: AppColors.teal),
                        const SizedBox(height: 16),
                        Text('You have already rated $revieweeName.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.ink)),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Back',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job info
                      Text(app.jobTitle,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text('Rating $revieweeName',
                          style: const TextStyle(
                              color: AppColors.mute, fontSize: 13)),
                      const SizedBox(height: 32),

                      // Stars
                      const Text('Your Rating',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < _stars;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _stars = i + 1),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: filled
                                    ? AppColors.marigold
                                    : AppColors.border,
                                size: 44,
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_stars > 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            ['', 'Poor', 'Fair', 'Good', 'Very Good',
                                'Excellent'][_stars],
                            style: const TextStyle(
                                color: AppColors.marigoldDark,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Comment
                      const Text('Comment (optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Share your experience…',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.marigold,
                            foregroundColor: AppColors.inkDark,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.inkDark))
                              : const Text('Submit Review',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
