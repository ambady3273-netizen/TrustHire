class ScamDetectionResult {
  final int riskScore;
  final String riskLevel;
  final List<String> reasons;

  const ScamDetectionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
  });

  bool get isSafe => riskScore < 31;
  bool get needsReview => riskScore >= 31 && riskScore <= 60;
  bool get isHighRisk => riskScore > 60;
}

class ScamDetector {
  // Suspicious phrases commonly found in fake job postings.
  static const Map<String, int> suspiciousKeywords = {
    'registration fee': 30,
    'registration fees': 30,
    'processing fee': 30,
    'processing fees': 30,
    'joining fee': 30,
    'joining fees': 30,
    'security deposit': 35,
    'deposit required': 35,
    'pay first': 35,
    'payment required': 30,
    'training fee': 25,
    'training fees': 25,
    'advance payment': 35,
    'investment required': 40,
    'money required': 35,
    'send money': 35,
    'pay money': 35,
    'guaranteed income': 20,
    'guaranteed salary': 20,
    'guaranteed earnings': 20,
    'earn money fast': 20,
    'earn quickly': 15,
    'work from home and earn': 10,
    'no experience required': 10,
    'unlimited income': 15,
    'unlimited earnings': 15,
    'get rich': 20,
    'easy money': 20,
    'instant income': 20,
    'instant joining': 15,
    'whatsapp only': 15,
    'telegram only': 20,
    'contact only on whatsapp': 15,
    'contact only on telegram': 20,
  };

  static const List<String> suspiciousUrlPatterns = [
    'bit.ly',
    'tinyurl.com',
    'shorturl.at',
    't.me/',
    'telegram.me/',
  ];

  /// Analyze a complete job posting.
  static ScamDetectionResult analyze({
    required String title,
    required String description,
    required String companyName,
    required String location,
    required String contact,
    required double salary,
  }) {
    int score = 0;
    final List<String> reasons = [];

    final String fullText = [
      title,
      description,
      companyName,
      location,
      contact,
    ].join(' ').toLowerCase();

    // ---------------------------------------------------------
    // 1. Suspicious keyword detection
    // ---------------------------------------------------------

    for (final entry in suspiciousKeywords.entries) {
      if (fullText.contains(entry.key)) {
        score += entry.value;

        reasons.add(
          'Suspicious phrase detected: "${entry.key}"',
        );
      }
    }

    // ---------------------------------------------------------
    // 2. URL detection
    // ---------------------------------------------------------

    for (final pattern in suspiciousUrlPatterns) {
      if (fullText.contains(pattern)) {
        score += 15;

        reasons.add(
          'Potentially suspicious link/contact method detected.',
        );

        break;
      }
    }

    // ---------------------------------------------------------
    // 3. Very short job description
    // ---------------------------------------------------------

    final String cleanDescription = description.trim();

    if (cleanDescription.length < 50) {
      score += 10;

      reasons.add(
        'Job description is unusually short.',
      );
    }

    // ---------------------------------------------------------
    // 4. Extremely short title
    // ---------------------------------------------------------

    if (title.trim().length < 5) {
      score += 5;

      reasons.add(
        'Job title contains very little information.',
      );
    }

    // ---------------------------------------------------------
    // 5. Missing company information
    // ---------------------------------------------------------

    if (companyName.trim().isEmpty) {
      score += 15;

      reasons.add(
        'Company information is missing.',
      );
    }

    // ---------------------------------------------------------
    // 6. Missing location
    // ---------------------------------------------------------

    if (location.trim().isEmpty) {
      score += 10;

      reasons.add(
        'Job location is missing.',
      );
    }

    // ---------------------------------------------------------
    // 7. Missing contact information
    // ---------------------------------------------------------

    if (contact.trim().isEmpty) {
      score += 5;

      reasons.add(
        'Employer contact information is missing.',
      );
    }

    // ---------------------------------------------------------
    // 8. Unrealistic salary detection
    // ---------------------------------------------------------

    if (salary > 100000) {
      score += 30;

      reasons.add(
        'Salary appears unusually high for a part-time job.',
      );
    } else if (salary > 50000) {
      score += 20;

      reasons.add(
        'Salary is unusually high and should be verified.',
      );
    }

    // ---------------------------------------------------------
    // 9. Excessive punctuation / hype detection
    // ---------------------------------------------------------

    final int exclamationCount =
        RegExp(r'!').allMatches(fullText).length;

    if (exclamationCount >= 5) {
      score += 10;

      reasons.add(
        'Job description contains excessive promotional language.',
      );
    }

    // ---------------------------------------------------------
    // 10. Phone/contact-only wording
    // ---------------------------------------------------------

    if (fullText.contains('only whatsapp') ||
        fullText.contains('only telegram') ||
        fullText.contains('whatsapp only') ||
        fullText.contains('telegram only')) {
      score += 15;

      reasons.add(
        'Employer relies heavily on external messaging platforms.',
      );
    }

    // ---------------------------------------------------------
    // Limit score to 100
    // ---------------------------------------------------------

    if (score > 100) {
      score = 100;
    }

    // ---------------------------------------------------------
    // Determine risk level
    // ---------------------------------------------------------

    String riskLevel;

    if (score <= 30) {
      riskLevel = 'Safe';
    } else if (score <= 60) {
      riskLevel = 'Needs Review';
    } else {
      riskLevel = 'High Risk';
    }

    // ---------------------------------------------------------
    // If no problems were found
    // ---------------------------------------------------------

    if (reasons.isEmpty) {
      reasons.add(
        'No major scam indicators were detected.',
      );
    }

    return ScamDetectionResult(
      riskScore: score,
      riskLevel: riskLevel,
      reasons: reasons,
    );
  }
}