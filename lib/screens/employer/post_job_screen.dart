
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/job_model.dart';
import '../../services/firestore_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/location_service.dart';
import '../../services/scam_detector.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _companyController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _salaryController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _contactController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String? _selectedCategory;

  bool _isAnalyzing = false;
  bool _isPosting = false;
  bool _isPinningLocation = false;

  /// GPS coordinates pinned by the employer for the job site.
  Position? _pinnedPosition;

  ScamDetectionResult? _analysisResult;

  final List<String> _categories = [
    'Delivery',
    'Data Entry',
    'Tutoring',
    'Retail',
    'Restaurant',
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _contactController.dispose();

    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  String? _salaryValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Salary is required';
    }

    final salary = double.tryParse(
      value.trim(),
    );

    if (salary == null) {
      return 'Enter a valid salary';
    }

    if (salary <= 0) {
      return 'Salary must be greater than 0';
    }

    return null;
  }

  // ============================================================
  // PIN LOCATION
  // ============================================================

  Future<void> _pinLocation() async {
    setState(() => _isPinningLocation = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() => _pinnedPosition = pos);
        _showMessage(
          'Location pinned: ${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)}',
        );
      } else if (mounted) {
        _showMessage(
          'Could not get location. Check permissions.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isPinningLocation = false);
    }
  }

  // ============================================================
  // ANALYZE JOB
  // ============================================================

  void _analyzeJob() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showMessage(
        'Please select a job category.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final salary = double.parse(
      _salaryController.text.trim(),
    );

    final result = ScamDetector.analyze(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      companyName: _companyController.text.trim(),
      location: _locationController.text.trim(),
      contact: _contactController.text.trim(),
      salary: salary,
    );

    setState(() {
      _analysisResult = result;
      _isAnalyzing = false;
    });
  }

  // ============================================================
  // POST JOB
  // ============================================================

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showMessage(
        'Please select a job category.',
        isError: true,
      );

      return;
    }

    // Make sure AI analysis has been performed.
    if (_analysisResult == null) {
      _showMessage(
        'Please analyze the job before posting.',
        isError: true,
      );

      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to post a job.',
        isError: true,
      );

      return;
    }

    // High-risk jobs cannot be posted.
    if (_analysisResult!.isHighRisk) {
      _showHighRiskDialog();
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final double salary = double.parse(
        _salaryController.text.trim(),
      );

      String status;

      if (_analysisResult!.isSafe) {
        status = 'approved';
      } else {
        status = 'pending_review';
      }

      final job = JobModel(
        id: '',
        employerId: user.uid,
        companyName: _companyController.text.trim(),
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        salary: salary,
        contact: _contactController.text.trim(),
        latitude:  _pinnedPosition?.latitude,
        longitude: _pinnedPosition?.longitude,
        riskScore: _analysisResult!.riskScore,
        status: status,
        createdAt: DateTime.now(),
      );

      await FirestoreService.instance.createJob(
        job,
      );

      // ── Notify all job seekers about the new listing ──────
      // This writes an in-app notification for every seeker.
      // Their bell badge increments automatically.
      FirestoreService.instance.notifyAllSeekers(
        title: 'New Job Posted 🆕',
        body:
            '"${job.title}" at ${job.companyName} · ${job.location} — ₹${job.salary.toStringAsFixed(0)}/mo',
        actionRoute: '/seekerDashboard',
      );

      // ── Local OS popup on the employer's own device ───────
      LocalNotificationService.instance.show(
        title: status == 'approved' ? 'Job Published ✓' : 'Job Submitted for Review',
        body: status == 'approved'
            ? '"${job.title}" is now live for seekers.'
            : '"${job.title}" is under admin review.',
        payload: '/employerDashboard',
      );

      if (!mounted) return;

      setState(() {
        _isPosting = false;
      });

      _showSuccessDialog(
        status: status,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPosting = false;
      });

      _showMessage(
        'Failed to post job: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // HIGH RISK DIALOG
  // ============================================================

  void _showHighRiskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('High Risk Job'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Score: ${_analysisResult!.riskScore}/100',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This job contains indicators that may be associated with fraudulent job postings.',
              ),
              const SizedBox(height: 16),
              ..._analysisResult!.reasons
                  .take(5)
                  .map(
                    (reason) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(reason),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Edit Job'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog({
    required String status,
  }) {
    final bool approved =
        status == 'approved';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                approved
                    ? Icons.check_circle
                    : Icons.hourglass_top_rounded,
                color: approved
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                approved
                    ? 'Job Posted'
                    : 'Submitted for Review',
              ),
            ],
          ),
          content: Text(
            approved
                ? 'Your job passed the initial TrustHire safety check and has been published.'
                : 'Your job has been submitted successfully and is waiting for administrator review.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/employerDashboard',
                    (route) => false,
                  );
                }
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red : null,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post a Job',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Text(
                  'Create a Job',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Provide accurate information so job seekers can trust your listing.',
                  style:
                      theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // JOB TITLE
                // ==================================================

                _buildLabel(
                  'Job Title',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _titleController,
                  textInputAction:
                      TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Part-time Delivery Partner',
                    prefixIcon:
                        Icon(Icons.work_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _requiredValidator(
                    value,
                    'Job title',
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // COMPANY
                // ==================================================

                _buildLabel(
                  'Company Name',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _companyController,
                  textInputAction:
                      TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter company/business name',
                    prefixIcon:
                        Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _requiredValidator(
                    value,
                    'Company name',
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CATEGORY
                // ==================================================

                _buildLabel(
                  'Job Category',
                  required: true,
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text(
                    'Select category',
                  ),
                  items: _categories
                      .map(
                        (category) =>
                            DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a category';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                _buildLabel(
                  'Job Description',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _descriptionController,
                  minLines: 5,
                  maxLines: 10,
                  textInputAction:
                      TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe responsibilities, requirements, working hours and other important details.',
                    prefixIcon:
                        Padding(
                      padding:
                          EdgeInsets.only(
                        bottom: 80,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final error =
                        _requiredValidator(
                      value,
                      'Job description',
                    );

                    if (error != null) {
                      return error;
                    }

                    if (value!.trim().length < 20) {
                      return 'Please provide more details';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // SALARY
                // ==================================================

                _buildLabel(
                  'Salary',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _salaryController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction:
                      TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: 15000',
                    prefixText: '₹ ',
                    prefixIcon:
                        Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _salaryValidator,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // LOCATION
                // ==================================================

                _buildLabel(
                  'Job Location',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _locationController,
                  textInputAction:
                      TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Nagercoil',
                    prefixIcon:
                        Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _requiredValidator(
                    value,
                    'Location',
                  ),
                ),

                const SizedBox(height: 10),

                // ── GPS pin button ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isPinningLocation ? null : _pinLocation,
                    icon: _isPinningLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _pinnedPosition != null
                                ? Icons.location_on
                                : Icons.my_location,
                            color: _pinnedPosition != null
                                ? Colors.green
                                : null,
                          ),
                    label: Text(
                      _pinnedPosition != null
                          ? '✓ GPS Pinned  '
                              '(${_pinnedPosition!.latitude.toStringAsFixed(4)}, '
                              '${_pinnedPosition!.longitude.toStringAsFixed(4)})'
                          : 'Pin My GPS Location (optional)',
                      style: TextStyle(
                        color: _pinnedPosition != null ? Colors.green : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CONTACT
                // ==================================================

                _buildLabel(
                  'Contact Information',
                  required: true,
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _contactController,
                  keyboardType:
                      TextInputType.phone,
                  textInputAction:
                      TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText:
                        'Phone number or official contact',
                    prefixIcon:
                        Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _requiredValidator(
                    value,
                    'Contact information',
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // ANALYZE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isAnalyzing || _isPosting
                            ? null
                            : _analyzeJob,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.security,
                          ),
                    label: Text(
                      _isAnalyzing
                          ? 'Analyzing Job...'
                          : 'Analyze Job Safety',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // AI RESULT
                // ==================================================

                if (_analysisResult != null)
                  _buildAnalysisCard(
                    _analysisResult!,
                  ),

                const SizedBox(height: 20),

                // ==================================================
                // POST BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed:
                        _isPosting ||
                                _isAnalyzing
                            ? null
                            : _postJob,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.publish,
                          ),
                    label: Text(
                      _isPosting
                          ? 'Posting Job...'
                          : 'Post Job',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SAFETY INFORMATION
                // ==================================================

                _buildSafetyInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text, {
    bool required = false,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // ANALYSIS CARD — Advanced v2.0
  // ============================================================

  Widget _buildAnalysisCard(ScamDetectionResult result) {
    final Color primary;
    final Color bgColor;
    final IconData headerIcon;
    final String verdict;

    if (result.isSafe) {
      primary    = const Color(0xFF1AAE9F); // teal
      bgColor    = const Color(0xFFE6F7F6);
      headerIcon = Icons.verified_user_rounded;
      verdict    = '✅ This job looks safe to post';
    } else if (result.needsReview) {
      primary    = const Color(0xFFF0A500); // amber
      bgColor    = const Color(0xFFFFF8E1);
      headerIcon = Icons.policy_rounded;
      verdict    = '⚠️ Admin will review before publishing';
    } else {
      primary    = const Color(0xFFE15B4F); // coral
      bgColor    = const Color(0xFFFFEBEB);
      headerIcon = Icons.gpp_bad_rounded;
      verdict    = '🚨 High risk — job cannot be posted';
    }

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: primary.withAlpha(120), width: 2),
        boxShadow: [
          BoxShadow(
            color:      primary.withAlpha(30),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TrustHire AI Safety Report',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verdict,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Score meter ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Risk Score',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:        primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(color: primary),
                      ),
                      child: Text(
                        '${result.riskScore} / 100',
                        style: TextStyle(
                            color:      primary,
                            fontWeight: FontWeight.w800,
                            fontSize:   16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value:     result.riskScore / 100,
                    minHeight: 10,
                    backgroundColor: primary.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),

                // ── Threshold legend ─────────────────────────
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0 — Safe',
                        style: TextStyle(
                            fontSize: 9.5, color: Color(0xFF1AAE9F))),
                    Text('26 — Review',
                        style: TextStyle(
                            fontSize: 9.5, color: Color(0xFFF0A500))),
                    Text('56 — High Risk',
                        style: TextStyle(
                            fontSize: 9.5, color: Color(0xFFE15B4F))),
                  ],
                ),

                // ── Category breakdown ───────────────────────
                if (result.categoryScores.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Risk by Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...(() {
                    final entries = result.categoryScores.entries
                        .where((e) => e.value > 0)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    return entries.take(6).map((e) {
                      final catColor = _categoryColor(e.key);
                      final barWidth = (e.value / 50).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600)),
                                Text('+${e.value}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:      catColor,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:           barWidth,
                                minHeight:       5,
                                backgroundColor: catColor.withAlpha(30),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    catColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  })(),
                ],

                // ── Signals detail ───────────────────────────
                if (result.signals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Detection Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...result.signals.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                _severityIcon(s.severity),
                                size:  16,
                                color: _severityColor(s.severity),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _severityColor(s.severity)
                                          .withAlpha(20),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s.category.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: _severityColor(
                                              s.severity),
                                          letterSpacing: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(s.message,
                                      style: const TextStyle(
                                          fontSize: 12, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else ...[
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF1AAE9F), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No scam indicators detected. '
                          'Job looks legitimate.',
                          style: TextStyle(
                              color:    Color(0xFF1AAE9F),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Analysis summary footer ──────────────────
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_alt_outlined,
                          size: 16, color: Color(0xFF5B6478)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Analyzed by TrustHire AI v2.0 · '
                          '15 detection layers · '
                          '${result.signals.length} signal${result.signals.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                              fontSize: 10.5, color: Color(0xFF5B6478)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Financial Fraud':      return const Color(0xFFE15B4F);
      case 'MLM / Pyramid':        return const Color(0xFFD32F2F);
      case 'Data Harvesting':      return const Color(0xFF9C27B0);
      case 'Urgency / Pressure':   return const Color(0xFFFF6F00);
      case 'Communication':        return const Color(0xFF1565C0);
      case 'WFH / Online Fraud':   return const Color(0xFF00838F);
      case 'Linguistic Deception': return const Color(0xFFAD1457);
      case 'Fake Credentials':     return const Color(0xFF4E342E);
      case 'Salary Intelligence':  return const Color(0xFFF57F17);
      case 'Implausibility':       return const Color(0xFF283593);
      case 'Pattern Analysis':     return const Color(0xFF6A1B9A);
      default:                     return const Color(0xFF5B6478);
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return const Color(0xFFB71C1C);
      case 'high':     return const Color(0xFFE15B4F);
      case 'medium':   return const Color(0xFFF0A500);
      default:         return const Color(0xFF5B6478);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical': return Icons.dangerous_rounded;
      case 'high':     return Icons.warning_rounded;
      case 'medium':   return Icons.info_rounded;
      default:         return Icons.circle_outlined;
    }
  }

  // ============================================================
  // SAFETY INFO
  // ============================================================

  Widget _buildSafetyInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
              ),
              SizedBox(width: 8),
              Text(
                'TrustHire Safety Check',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Every job is analyzed for suspicious phrases, unrealistic salaries, payment requests, suspicious contact methods and other potential scam indicators.',
          ),
        ],
      ),
    );
  }
}