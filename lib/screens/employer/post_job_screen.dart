
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/firestore_service.dart';
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
        riskScore: _analysisResult!.riskScore,
        status: status,
        createdAt: DateTime.now(),
      );

      await FirestoreService.instance.createJob(
        job,
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
  // ANALYSIS CARD
  // ============================================================

  Widget _buildAnalysisCard(
    ScamDetectionResult result,
  ) {
    final Color color;

    if (result.isSafe) {
      color = Colors.green;
    } else if (result.needsReview) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    final IconData icon;

    if (result.isSafe) {
      icon = Icons.verified_user;
    } else if (result.needsReview) {
      icon = Icons.warning_amber_rounded;
    } else {
      icon = Icons.gpp_bad;
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TrustHire Safety Analysis',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Risk Score',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${result.riskScore}/100',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: result.riskScore / 100,
              minHeight: 8,
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                result.riskLevel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Detection Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...result.reasons.map(
              (reason) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 7,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        result.isSafe
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reason),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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