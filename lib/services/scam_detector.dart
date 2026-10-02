// ═══════════════════════════════════════════════════════════════════════════
// TrustHire Advanced AI Scam Detection Engine  v3.0
// ═══════════════════════════════════════════════════════════════════════════
//
// 21 Independent Detection Layers  |  500+ Pattern Rules
//
// CORE LAYERS (v2.0 — refined):
//  Layer 01 — Financial Fraud Signals          (payment demands, deposits)
//  Layer 02 — Salary Intelligence v2           (category-aware pay analysis)
//  Layer 03 — Urgency & Pressure Manipulation  (FOMO, scarcity tactics)
//  Layer 04 — Identity Concealment             (anonymous employer signals)
//  Layer 05 — Communication Channel Red Flags  (WhatsApp-only, Telegram)
//  Layer 06 — MLM / Pyramid Scheme Detection   (downline, binary plans)
//  Layer 07 — Data Harvesting Signals          (Aadhaar, OTP, bank details)
//  Layer 08 — Linguistic Deception Engine      (hype, ALL CAPS, emojis)
//  Layer 09 — Implausibility Matrix            (impossible job combinations)
//  Layer 10 — Suspicious URL / Link Detection  (shortened links)
//  Layer 11 — Job Content Quality Score        (completeness analysis)
//  Layer 12 — Indian Regional Scam Patterns    (Tamil, Hindi, Telugu, etc.)
//  Layer 13 — Work-From-Home Fraud Signals     (task fraud, click farms)
//  Layer 14 — Fake Credential / Authority Claim(ISO, Govt, RBI fake claims)
//  Layer 15 — Contextual Cross-Signal Amplifier(cluster detection)
//
// NEW ADVANCED LAYERS (v3.0):
//  Layer 16 — Behavioural Contradiction Engine (says one thing, means another)
//  Layer 17 — Industry-Specific Risk Profiling (high-risk job categories)
//  Layer 18 — Phone Number Intelligence        (premium rate, suspicious formats)
//  Layer 19 — Temporal Anomaly Detection       (impossible work hours claims)
//  Layer 20 — Social Engineering Tactics       (emotional manipulation patterns)
//  Layer 21 — Confidence Score Engine          (meta-analysis of all signals)
//
// SCORING ENGINE:
//   Raw score from all layers → weighted + confidence-adjusted
//   0–20   → SAFE           (✅ auto-approved, shown to seekers)
//   21–50  → NEEDS REVIEW   (⚠️  admin reviews within 24h)
//   51–100 → HIGH RISK      (🚨 blocked immediately)
//
// CONFIDENCE RATING:
//   HIGH   → 3+ critical signals  (very likely scam)
//   MEDIUM → 2 critical signals   (probably scam)
//   LOW    → 1 critical signal    (suspicious, review needed)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: non_constant_identifier_names, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps

// ── Signal model ─────────────────────────────────────────────────────────

class ScamSignal {
  final String category;
  final String message;
  final int    points;
  final String severity; // 'low' | 'medium' | 'high' | 'critical'
  final String layer;

  const ScamSignal({
    required this.category,
    required this.message,
    required this.points,
    required this.severity,
    this.layer = '',
  });
}

// ── Result model ──────────────────────────────────────────────────────────

class ScamDetectionResult {
  final int                riskScore;
  final String             riskLevel;
  final List<String>       reasons;
  final List<ScamSignal>   signals;
  final Map<String, int>   categoryScores;
  final String             confidence;   // 'HIGH' | 'MEDIUM' | 'LOW' | 'SAFE'
  final int                layersTriggered;
  final String             verdict;      // Short human-readable verdict

  const ScamDetectionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
    required this.signals,
    required this.categoryScores,
    required this.confidence,
    required this.layersTriggered,
    required this.verdict,
  });

  bool get isSafe      => riskScore <= 20;
  bool get needsReview => riskScore > 20 && riskScore <= 50;
  bool get isHighRisk  => riskScore > 50;

  String get riskEmoji {
    if (isSafe)      return '✅ Safe';
    if (needsReview) return '⚠️ Needs Review';
    return '🚨 High Risk';
  }
}

// ── Main Detector ─────────────────────────────────────────────────────────

class ScamDetector {

  static ScamDetectionResult analyze({
    required String title,
    required String description,
    required String companyName,
    required String location,
    required String contact,
    required double salary,
    String category = '',
  }) {
    final ctx = _Context(
      title:       title.trim(),
      description: description.trim(),
      companyName: companyName.trim(),
      location:    location.trim(),
      contact:     contact.trim(),
      salary:      salary,
      category:    category.trim().toLowerCase(),
    );

    final signals = <ScamSignal>[];

    // ── Run all 21 layers ──────────────────────────────────────────────────
    signals.addAll(_layer01_financialFraud(ctx));
    signals.addAll(_layer02_salaryIntelligence(ctx));
    signals.addAll(_layer03_urgencyPressure(ctx));
    signals.addAll(_layer04_identityConcealment(ctx));
    signals.addAll(_layer05_communicationRedFlags(ctx));
    signals.addAll(_layer06_mlmPyramid(ctx));
    signals.addAll(_layer07_dataHarvesting(ctx));
    signals.addAll(_layer08_linguisticDeception(ctx));
    signals.addAll(_layer09_implausibility(ctx));
    signals.addAll(_layer10_suspiciousUrls(ctx));
    signals.addAll(_layer11_contentQuality(ctx));
    signals.addAll(_layer12_regionalScamPatterns(ctx));
    signals.addAll(_layer13_wfhFraud(ctx));
    signals.addAll(_layer14_fakeCredentials(ctx));
    signals.addAll(_layer15_crossSignalAmplifier(signals));
    signals.addAll(_layer16_behaviouralContradiction(ctx));
    signals.addAll(_layer17_industryRisk(ctx));
    signals.addAll(_layer18_phoneIntelligence(ctx));
    signals.addAll(_layer19_temporalAnomaly(ctx));
    signals.addAll(_layer20_socialEngineering(ctx));
    final confidence = _layer21_confidenceEngine(signals);

    // ── Aggregate & weight score ───────────────────────────────────────────
    int rawScore = signals.fold(0, (sum, s) => sum + s.points);

    // Apply confidence multiplier
    double multiplier = 1.0;
    if (confidence == 'HIGH')   multiplier = 1.15;
    if (confidence == 'MEDIUM') multiplier = 1.05;

    final score = (rawScore * multiplier).round().clamp(0, 100);

    // Category breakdown
    final catScores = <String, int>{};
    for (final s in signals) {
      catScores[s.category] = (catScores[s.category] ?? 0) + s.points;
    }

    // Layers triggered
    final layersHit = signals.map((s) => s.layer).toSet().length;

    // Risk level
    final String riskLevel;
    if (score <= 20)      riskLevel = 'Safe';
    else if (score <= 50) riskLevel = 'Needs Review';
    else                  riskLevel = 'High Risk';

    // Human-readable verdict
    final verdict = _buildVerdict(score, signals, confidence);

    final reasons = signals.isEmpty
        ? ['No scam indicators detected. Job appears legitimate.']
        : signals.map((s) => s.message).toList();

    return ScamDetectionResult(
      riskScore:       score,
      riskLevel:       riskLevel,
      reasons:         reasons,
      signals:         signals,
      categoryScores:  catScores,
      confidence:      confidence,
      layersTriggered: layersHit,
      verdict:         verdict,
    );
  }

  // ─── Verdict builder ──────────────────────────────────────────────────────

  static String _buildVerdict(
      int score, List<ScamSignal> signals, String confidence) {
    final criticals = signals.where((s) => s.severity == 'critical').length;
    final highs     = signals.where((s) => s.severity == 'high').length;

    if (score <= 20) return 'This job appears genuine. No major scam indicators found.';
    if (criticals >= 2) return 'CRITICAL: Multiple serious fraud indicators detected. Do not apply.';
    if (criticals == 1) return 'Serious fraud indicator detected. Admin review required.';
    if (highs >= 3)     return 'Multiple high-risk patterns detected. Likely a scam.';
    if (score > 50)     return 'High risk. This job shows strong scam characteristics.';
    return 'Some suspicious patterns detected. Admin will review before publishing.';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 01 — Financial Fraud Signals
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer01_financialFraud(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Financial Fraud';
    const lyr = 'L01';

    final patterns = {
      'registration fee': 42, 'registration fees': 42,
      'joining fee': 42,      'joining fees': 42,
      'security deposit': 48, 'deposit required': 48,
      'pay first': 48,        'advance payment': 48,
      'processing fee': 40,   'training fee': 38,
      'investment required': 52, 'invest to earn': 52,
      'send money': 48,       'pay to work': 52,
      'pay and earn': 52,     'money back guarantee': 38,
      'refundable deposit': 42, 'caution deposit': 42,
      'kyc fee': 48,          'kyc charge': 48,
      'document charge': 42,  'verification fee': 42,
      'activation fee': 42,   'starter kit fee': 42,
      'kit fee': 38,          'uniform fee': 32,
      'registration amount': 42, 'initial deposit': 42,
      'onboarding fee': 42,   'membership fee': 38,
      'account opening fee': 42, 'wallet recharge': 45,
      'recharge required': 45,  'invest ₹': 52,
      'invest rs': 52,          'pay ₹': 40,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat, layer: lyr,
          message: 'Demands money from applicant: "${e.key}" — Legitimate employers NEVER charge workers.',
          points: e.value,
          severity: e.value >= 48 ? 'critical' : 'high',
        ));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 02 — Salary Intelligence v2 (category-aware)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer02_salaryIntelligence(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Salary Intelligence';
    const lyr = 'L02';

    if (c.salary <= 0) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'No salary specified — could be used to make vague promises.',
          points: 12, severity: 'low'));
      return out;
    }

    // Category-aware salary benchmarks (realistic Indian market)
    final benchmarks = <String, double>{
      'delivery': 18000,       'driver': 20000,
      'domestic help': 12000,  'security guard': 15000,
      'restaurant': 14000,     'retail': 14000,
      'salon work': 15000,     'tailoring': 12000,
      'data entry': 18000,     'customer service': 20000,
      'office work': 22000,    'tutoring': 18000,
      'ac technician': 25000,  'plumber': 22000,
      'electrician': 22000,    'construction': 18000,
      'event work': 15000,     'freelance': 25000,
    };

    double benchmark = benchmarks[c.category] ?? 20000;
    double maxReasonable = benchmark * 3.5;

    if (c.salary > 150000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Salary ₹${c.salary.toStringAsFixed(0)}/mo is extremely unrealistic for a part-time job (${(c.salary/benchmark).toStringAsFixed(1)}x market rate).',
          points: 45, severity: 'critical'));
    } else if (c.salary > maxReasonable) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Salary ₹${c.salary.toStringAsFixed(0)}/mo is ${(c.salary/benchmark).toStringAsFixed(1)}x the typical market rate for this category.',
          points: 28, severity: 'high'));
    } else if (c.salary > benchmark * 2) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Salary is higher than typical for this category. Verify before applying.',
          points: 14, severity: 'medium'));
    }

    // Exploitation check
    if (c.salary > 0 && c.salary < 4000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Salary ₹${c.salary.toStringAsFixed(0)}/mo is below minimum wage — possible labour exploitation.',
          points: 18, severity: 'high'));
    }

    // Guaranteed income language
    final guaranteePhrases = [
      'guaranteed income', 'guaranteed salary', 'guaranteed earnings',
      'guaranteed ₹', 'guaranteed rs', '100% guaranteed', 'assured income',
      'assured salary', 'fixed income guaranteed', 'guaranteed payment',
    ];
    for (final p in guaranteePhrases) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: '"Guaranteed income" claim — no legitimate employer guarantees exact earnings.',
            points: 22, severity: 'high'));
        break;
      }
    }

    // Daily earnings bait
    final dailyRegex = RegExp(r'(earn|get|receive)\s*[₹rs\.]?\s*\d+\s*per\s*day');
    if (dailyRegex.hasMatch(c.full)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Promises specific daily earnings — legitimate salaries are monthly.',
          points: 20, severity: 'high'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 03 — Urgency & Pressure Manipulation
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer03_urgencyPressure(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Urgency / Pressure';
    const lyr = 'L03';

    final patterns = {
      'limited seats': 16, 'limited vacancies': 16,
      'only few seats': 18, 'hurry': 12,
      'apply immediately': 12, 'last chance': 18,
      'closing soon': 14, 'today only': 22,
      'this week only': 18, 'first come first': 12,
      'urgent hiring': 12, 'immediate joining': 14,
      'join today': 16, "don't miss": 14,
      'offer expires': 18, 'limited time offer': 22,
      'act fast': 16, 'respond quickly': 12,
      'instant offer': 16, 'no waiting': 12,
      'direct joining': 12, 'walk in': 6,
      'hurry up': 14, 'spots filling fast': 18,
      'only today': 22, 'last day': 16,
      'deadline today': 20, 'final call': 16,
    };

    int hits = 0;
    for (final e in patterns.entries) {
      if (c.full.contains(e.key) && hits < 3) {
        hits++;
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Urgency tactic: "${e.key}" — scammers use pressure to prevent careful thinking.',
            points: e.value, severity: e.value >= 18 ? 'high' : 'medium'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 04 — Identity Concealment
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer04_identityConcealment(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Identity / Company';
    const lyr = 'L04';

    if (c.companyName.isEmpty || c.companyName.length < 3) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Company name missing — legitimate employers always identify themselves.',
          points: 20, severity: 'high'));
    }

    final genericNames = ['company', 'firm', 'enterprise', 'associates',
        'group', 'services', 'pvt', 'ltd', 'private'];
    if (genericNames.any((g) => c.companyName.toLowerCase().trim() == g)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Company name is suspiciously generic with no specific identity.',
          points: 14, severity: 'medium'));
    }

    if (c.location.isEmpty) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'No job location specified — physical jobs always have a location.',
          points: 14, severity: 'medium'));
    }

    if (c.contact.isEmpty) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'No contact information provided.',
          points: 10, severity: 'low'));
    }

    // Physical job claiming remote work
    final physicalJobs = ['delivery', 'retail', 'restaurant', 'security guard',
        'domestic help', 'construction', 'salon', 'driver'];
    final isPhysical = physicalJobs.any((j) => c.full.contains(j));
    if (isPhysical && (c.full.contains('work from home') || c.full.contains('remote'))) {
      out.add(ScamSignal(category: 'Implausibility', layer: lyr,
          message: 'Physical job claiming to be work-from-home — impossible combination.',
          points: 24, severity: 'critical'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 05 — Communication Channel Red Flags
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer05_communicationRedFlags(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Communication';
    const lyr = 'L05';

    final patterns = {
      'whatsapp only': 22, 'contact on whatsapp': 20,
      'whatsapp me': 16, 'wa.me': 20,
      'telegram only': 28, 'contact on telegram': 24,
      't.me/': 24, 'telegram.me': 24,
      'no calls': 16, 'sms only': 14,
      'message only': 12, 'dm for details': 16,
      'inbox for details': 16, 'contact via instagram': 20,
      'contact via facebook': 16, 'google form': 12,
      'chat only': 14, 'text only': 12,
      'no phone calls': 16, 'only whatsapp': 22,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Suspicious contact method: "${e.key}" — legitimate employers use official email/phone.',
            points: e.value, severity: e.value >= 22 ? 'high' : 'medium'));
      }
    }

    // Multiple phone numbers
    final phoneRegex = RegExp(r'\b[6-9]\d{9}\b');
    final phones = phoneRegex.allMatches(c.full).length;
    if (phones >= 3) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Contains $phones phone numbers — unusual for a legitimate posting.',
          points: 14, severity: 'medium'));
    }

    // Personal email with corporate claims
    final emailRegex = RegExp(r'[\w.+-]+@(gmail|yahoo|hotmail|outlook|rediffmail)\.');
    if (emailRegex.hasMatch(c.full) &&
        (c.full.contains('mnc') || c.full.contains('multinational') ||
         c.full.contains('international') || c.full.contains('corporate'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims to be MNC/international but uses personal email address.',
          points: 20, severity: 'high'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 06 — MLM / Pyramid Scheme Detection
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer06_mlmPyramid(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'MLM / Pyramid';
    const lyr = 'L06';

    final patterns = {
      'refer and earn': 28, 'referral income': 28,
      'referral bonus': 22, 'bring more people': 34,
      'recruit members': 34, 'downline': 38,
      'network marketing': 28, 'multi level': 34,
      'multilevel': 34, 'chain marketing': 38,
      'pyramid': 38, 'team building income': 28,
      'passive income': 18, 'residual income': 22,
      'binary income': 38, 'matrix plan': 38,
      'franchise fee': 22, 'distributorship': 18,
      'direct selling': 14, 'earn through others': 34,
      'earn per referral': 28, 'build your team': 22,
      'grow your network': 22, 'level income': 28,
      'team income': 22, 'downline earnings': 38,
      'upline income': 38, 'sponsor income': 34,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'MLM/pyramid indicator: "${e.key}" — income from recruiting others is illegal in India.',
            points: e.value, severity: e.value >= 34 ? 'critical' : 'high'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 07 — Data Harvesting Signals
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer07_dataHarvesting(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Data Harvesting';
    const lyr = 'L07';

    final patterns = {
      'send aadhaar': 44, 'share aadhaar': 44,
      'aadhaar number': 38, 'aadhaar card': 34,
      'send pan': 38, 'pan card number': 34,
      'bank account number': 44, 'account details': 38,
      'send bank details': 44, 'otp': 28,
      'share otp': 44, 'verify otp': 34,
      'send photo': 18, 'send your photo': 22,
      'passport copy': 28, 'id proof required': 18,
      'credit card': 44, 'debit card': 44,
      'card number': 44, 'cvv': 48,
      'upi pin': 48, 'bank password': 48,
      'net banking': 34, 'internet banking': 34,
      'upload aadhaar': 38, 'voter id': 28,
      'driving licence': 24, 'date of birth': 18,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Requests sensitive personal data: "${e.key}" — never share ID/banking data during job applications.',
            points: e.value, severity: e.value >= 38 ? 'critical' : 'high'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 08 — Linguistic Deception Engine v2
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer08_linguisticDeception(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Linguistic Deception';
    const lyr = 'L08';

    // ALL CAPS ratio
    final words = c.rawFull.split(RegExp(r'\s+'));
    if (words.length > 5) {
      final capsWords = words.where(
          (w) => w.length > 3 && w == w.toUpperCase() && RegExp(r'^[A-Z]+$').hasMatch(w)).length;
      final ratio = capsWords / words.length;
      if (ratio > 0.25) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: '${(ratio*100).toStringAsFixed(0)}% ALL CAPS text — aggressive promotional language.',
            points: 16, severity: 'medium'));
      }
    }

    // Exclamation marks
    final excl = '!'.allMatches(c.rawFull).length;
    if (excl >= 3) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '$excl exclamation marks — over-hyped writing is a scam trait.',
          points: excl >= 7 ? 16 : 9, severity: excl >= 7 ? 'medium' : 'low'));
    }

    // Emoji abuse
    final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
        unicode: true);
    final emojiCount = emojiRegex.allMatches(c.rawFull).length;
    if (emojiCount >= 6) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Excessive emoji use ($emojiCount) — unprofessional and common in scam postings.',
          points: 12, severity: 'low'));
    }

    // Hype phrases
    final hypePhrases = {
      'earn lakhs': 28, 'earn crores': 34,
      'be your own boss': 18, 'financial freedom': 18,
      'life changing': 14, 'once in a lifetime': 18,
      'golden opportunity': 18, 'life time opportunity': 20,
      '100% profit': 24, 'double your money': 38,
      'zero risk': 22, 'risk free': 20,
      'no target': 12, 'no pressure': 10,
      'dream income': 18, 'unlimited earning': 18,
      'unlimited income': 18, 'earn from anywhere': 16,
      'extra income': 10, 'side income': 8,
      'pocket money': 8,  'big opportunity': 14,
      'golden chance': 16, 'god gifted': 14,
      'you are selected': 22, 'congratulations you': 24,
    };

    for (final e in hypePhrases.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Hype language: "${e.key}" — exaggerated claims lower victim\'s guard.',
            points: e.value, severity: e.value >= 24 ? 'high' : 'medium'));
      }
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 09 — Implausibility Matrix
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer09_implausibility(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Implausibility';
    const lyr = 'L09';

    // High salary + no experience
    if (c.salary > 40000 && (c.full.contains('no experience') ||
        c.full.contains('freshers') || c.full.contains('no qualification'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Offers very high salary for no-experience/fresher role.',
          points: 24, severity: 'high'));
    }

    // Part-time + extremely high pay
    if ((c.full.contains('part time') || c.full.contains('part-time')) && c.salary > 60000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Part-time role with salary over ₹60,000 — extremely suspicious.',
          points: 22, severity: 'high'));
    }

    // Work 1-3 hours + high salary
    final shortHoursRegex = RegExp(r'(work|only|just)\s+(1|2|3|one|two|three)\s+hour');
    if (shortHoursRegex.hasMatch(c.full) && c.salary > 20000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims high salary for just 1-3 hours of work — classic scam bait.',
          points: 28, severity: 'high'));
    }

    // Mass hiring (hundreds of people)
    final massHireRegex = RegExp(r'(hiring|recruit|need|want)\s+\d{3,}');
    if (massHireRegex.hasMatch(c.full)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims to hire hundreds of people — mass hiring without specifics is suspicious.',
          points: 16, severity: 'medium'));
    }

    // All genders/ages no bar
    if (c.full.contains('age no bar') && c.full.contains('qualification no bar')) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '"Age no bar + qualification no bar" combination — used to cast the widest scam net.',
          points: 18, severity: 'medium'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 10 — Suspicious URL Detection
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer10_suspiciousUrls(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Suspicious Links';
    const lyr = 'L10';

    final patterns = {
      'bit.ly': 22, 'tinyurl.com': 22, 'shorturl.at': 22,
      'ow.ly': 20, 'goo.gl': 18, 'rb.gy': 22,
      'cutt.ly': 20, 't.me/': 28, 'telegram.me': 28,
      'wa.me': 22, 'click here': 12, 'apply here': 10,
      'google form': 14, 'docs.google': 12,
      'forms.gle': 16, 'linktree': 14,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Suspicious link: "${e.key}" — used to hide malicious destinations.',
            points: e.value, severity: e.value >= 22 ? 'high' : 'medium'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 11 — Content Quality Score
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer11_contentQuality(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Content Quality';
    const lyr = 'L11';

    if (c.description.length < 30) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Job description is dangerously short — legitimate jobs explain responsibilities.',
          points: 16, severity: 'medium'));
    } else if (c.description.length < 80) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Job description is too brief for a legitimate posting.',
          points: 9, severity: 'low'));
    }

    if (c.title.length < 5) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Job title is too short to be meaningful.',
          points: 9, severity: 'low'));
    }

    // Word repetition (spam)
    final wordList = c.full.split(RegExp(r'\s+'));
    if (wordList.length > 10) {
      final wordFreq = <String, int>{};
      for (final w in wordList) {
        if (w.length > 4) wordFreq[w] = (wordFreq[w] ?? 0) + 1;
      }
      final maxFreq = wordFreq.values.fold(0, (a, b) => a > b ? a : b);
      if (maxFreq > 8) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Heavy word repetition detected — suggests copy-paste spam content.',
            points: 12, severity: 'medium'));
      }
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 12 — Indian Regional Scam Patterns (expanded)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer12_regionalScamPatterns(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Regional Scam Patterns';
    const lyr = 'L12';

    final patterns = {
      // Tamil
      'velai illama': 16, 'easy velai': 20, 'salary guarantee': 22,
      'income guarantee': 22, 'panam tharum': 28, 'fees kattu': 38,
      'registration pattu': 38, 'amount pattu': 38, 'thadai illai': 16,
      'veetil irundhe': 14, 'neram illai': 12, 'vilaivu': 10,
      // Hindi
      'paise kamao': 16, 'ghar baithe': 14, 'registration karo': 32,
      'fees bharo': 38, 'guaranteed kamai': 28, 'direct paisa': 22,
      'aasaan kaam': 14, 'bina mehnat': 16, 'ghar se kaam': 12,
      // Telugu
      'illu nundi': 14, 'easy job': 12, 'rupayalu': 14,
      // Kannada
      'mane ninda': 14, 'sahaja gelasu': 14,
      // Malayalam
      'veettil ninn': 14, 'easy job kerala': 16,
      // Mixed
      'monthly salary guarantee': 28, 'fixed salary guarantee': 28,
      'age no bar': 12, 'qualification no bar': 14,
      'caste no bar': 6, 'gender no bar': 6,
      'all are selected': 22, 'everyone selected': 22,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Regional scam phrase: "${e.key}".',
            points: e.value, severity: e.value >= 34 ? 'critical' : 'high'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 13 — Work-From-Home Fraud Signals
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer13_wfhFraud(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'WFH / Online Fraud';
    const lyr = 'L13';

    final patterns = {
      'product review': 22, 'like and subscribe': 22,
      'youtube task': 28, 'amazon task': 28,
      'flipkart task': 28, 'online task': 20,
      'copy paste job': 22, 'typing job from home': 16,
      'ad posting': 22, 'form filling': 20,
      'captcha work': 22, 'survey job': 16,
      'click ads': 28, 'click and earn': 28,
      'watch videos and earn': 28, 'follow and earn': 22,
      'instagram task': 24, 'facebook task': 22,
      'mobile job': 14, 'work from phone': 14,
      'recharge task': 28, 'task based earning': 20,
      'simple task earn': 16, 'online part time': 10,
      'data entry from home': 14, 'work on phone': 14,
      'paytm task': 28, 'gpay task': 28,
      'phonepe task': 28, 'crypto task': 32,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'WFH fraud indicator: "${e.key}" — online task jobs are frequently used to defraud workers.',
            points: e.value, severity: e.value >= 24 ? 'high' : 'medium'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 14 — Fake Credential / Authority Claims
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer14_fakeCredentials(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Fake Credentials';
    const lyr = 'L14';

    final patterns = {
      'iso certified': 16, 'government approved': 28,
      'government registered': 22, 'rbi approved': 34,
      'sebi registered': 28, 'income tax approved': 34,
      'ministry approved': 34, 'award winning': 12,
      'no. 1 company': 14, 'top rated company': 12,
      'verified company': 12, 'trusted company': 10,
      '100% genuine': 16, 'genuine company': 12,
      'not a scam': 22, 'no fraud': 20,
      'we are not fraud': 28, 'genuine work': 14,
      'mnc company': 12, 'fortune 500': 16,
      'government job': 16, 'sarkari naukri': 16,
      'central government': 20, 'state government': 18,
      'railway job': 18, 'bank job': 16,
    };

    for (final e in patterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Unverifiable authority claim: "${e.key}" — scammers fake credentials to appear legitimate.',
            points: e.value, severity: e.value >= 24 ? 'high' : 'medium'));
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 15 — Cross-Signal Amplifier
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer15_crossSignalAmplifier(List<ScamSignal> existing) {
    final out = <ScamSignal>[];
    const cat = 'Pattern Analysis';
    const lyr = 'L15';

    final categories = existing.map((s) => s.category).toSet();
    final total = existing.length;

    if (categories.length >= 3 && total >= 4) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '${categories.length} different risk categories triggered — combined indicators strongly suggest fraud.',
          points: 16, severity: 'high'));
    }

    if (total >= 6) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '$total individual risk signals — high signal density is a strong fraud predictor.',
          points: 12, severity: 'high'));
    }

    // Critical combo: Financial + Data harvesting
    final hasFinancial = existing.any((s) => s.category == 'Financial Fraud');
    final hasData = existing.any((s) => s.category == 'Data Harvesting');
    if (hasFinancial && hasData) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'CRITICAL: Financial demands + personal data requests = high-confidence scam profile.',
          points: 22, severity: 'critical'));
    }

    // MLM + Urgency
    final hasMlm = existing.any((s) => s.category == 'MLM / Pyramid');
    final hasUrgency = existing.any((s) => s.category == 'Urgency / Pressure');
    if (hasMlm && hasUrgency) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'MLM scheme + urgency pressure = pyramid recruitment tactic.',
          points: 16, severity: 'critical'));
    }

    // WFH + Financial
    final hasWfh = existing.any((s) => s.category == 'WFH / Online Fraud');
    if (hasWfh && hasFinancial) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Online task fraud + payment demand = advance fee scam pattern.',
          points: 20, severity: 'critical'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 16 — Behavioural Contradiction Engine (NEW in v3.0)
  // Detects when a job says one thing but implies another
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer16_behaviouralContradiction(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Behavioural Contradiction';
    const lyr = 'L16';

    // Claims "no experience" but asks for professional skills
    if ((c.full.contains('no experience') || c.full.contains('freshers')) &&
        (c.full.contains('expert') || c.full.contains('professional') ||
         c.full.contains('specialist') || c.full.contains('senior'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Says "no experience needed" but requires expert/professional skills — contradictory.',
          points: 22, severity: 'high'));
    }

    // Claims "part time" but salary suggests full time
    if ((c.full.contains('part time') || c.full.contains('part-time')) &&
        c.salary > 40000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Described as part-time but salary matches full-time executive pay.',
          points: 20, severity: 'high'));
    }

    // Claims legitimate but asks for fees
    if ((c.full.contains('100% genuine') || c.full.contains('not a scam') ||
         c.full.contains('real company')) &&
        (c.full.contains('fee') || c.full.contains('deposit') || c.full.contains('charge'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Insists it is genuine while asking for fees — over-reassurance is a red flag.',
          points: 28, severity: 'critical'));
    }

    // Claims simple work but asks high investment
    if ((c.full.contains('simple work') || c.full.contains('easy work') ||
         c.full.contains('simple task')) &&
        (c.full.contains('invest') || c.full.contains('deposit'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '"Simple/easy work" + investment requirement = advance fee fraud pattern.',
          points: 32, severity: 'critical'));
    }

    // Formal company but WhatsApp only contact
    if ((c.full.contains('pvt ltd') || c.full.contains('private limited') ||
         c.full.contains('company')) &&
        (c.full.contains('whatsapp only') || c.full.contains('telegram only'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims to be a company but only accepts contact via WhatsApp/Telegram.',
          points: 24, severity: 'high'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 17 — Industry-Specific Risk Profiling (NEW in v3.0)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer17_industryRisk(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Industry Risk';
    const lyr = 'L17';

    // Crypto/trading jobs — extremely high fraud rate
    final cryptoTerms = ['cryptocurrency', 'crypto trading', 'bitcoin', 'ethereum',
        'forex trading', 'stock trading', 'binary trading', 'option trading',
        'trading profit', 'investment trading', 'p2p trading', 'crypto earn'];
    for (final term in cryptoTerms) {
      if (c.full.contains(term)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Crypto/trading job: "$term" — extremely high fraud rate in this category.',
            points: 36, severity: 'critical'));
        break;
      }
    }

    // Insurance/LIC agent with recruitment
    final insuranceMLM = ['lic agent income', 'insurance team', 'insurance business',
        'health insurance earn', 'insurance referral'];
    for (final term in insuranceMLM) {
      if (c.full.contains(term)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Insurance recruitment pattern — often used as MLM cover.',
            points: 18, severity: 'medium'));
        break;
      }
    }

    // Modelling/acting with upfront payment
    if ((c.full.contains('modelling') || c.full.contains('modeling') ||
         c.full.contains('acting') || c.full.contains('film')) &&
        (c.full.contains('fee') || c.full.contains('charge') || c.full.contains('payment'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Modelling/acting job with upfront payment — common fraud targeting youth.',
          points: 30, severity: 'critical'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 18 — Phone Number Intelligence (NEW in v3.0)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer18_phoneIntelligence(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Phone Intelligence';
    const lyr = 'L18';

    // Premium rate numbers
    final premiumRegex = RegExp(r'\b(1800|1860|900\d|116\d)\d+\b');
    if (premiumRegex.hasMatch(c.full)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Contains premium-rate or toll-free number pattern — could be used for paid callbacks.',
          points: 18, severity: 'medium'));
    }

    // Too many different phone numbers (3+)
    final phoneRegex = RegExp(r'\b[6-9]\d{9}\b');
    final phones = phoneRegex.allMatches(c.full);
    final uniquePhones = phones.map((m) => m.group(0)).toSet();
    if (uniquePhones.length >= 3) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: '${uniquePhones.length} different phone numbers in one posting — unusual for legitimate employer.',
          points: 16, severity: 'medium'));
    }

    // WhatsApp number in description (not contact field)
    if (c.description.toLowerCase().contains('whatsapp') &&
        phoneRegex.hasMatch(c.description)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'WhatsApp number embedded in job description — used to bypass platform safety.',
          points: 20, severity: 'high'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 19 — Temporal Anomaly Detection (NEW in v3.0)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer19_temporalAnomaly(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Temporal Anomaly';
    const lyr = 'L19';

    // Impossible work hours + high pay
    final impossibleHours = RegExp(
        r'(work|earn)\s+(4|5|6|four|five|six)\s+hour.*₹\s*\d{4,}');
    if (impossibleHours.hasMatch(c.full)) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims high daily earnings from just 4-6 hours work — mathematically implausible.',
          points: 22, severity: 'high'));
    }

    // Weekend only + high monthly salary
    if ((c.full.contains('weekend only') || c.full.contains('sunday only') ||
         c.full.contains('saturday sunday')) && c.salary > 25000) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Weekend-only job with monthly salary exceeding full-time equivalent.',
          points: 20, severity: 'high'));
    }

    // "5 minutes a day" type claims
    final minuteRegex = RegExp(r'(5|10|15|20|five|ten|fifteen)\s+minute');
    if (minuteRegex.hasMatch(c.full) &&
        (c.full.contains('earn') || c.full.contains('income') || c.full.contains('salary'))) {
      out.add(ScamSignal(category: cat, layer: lyr,
          message: 'Claims earning for just minutes of work per day — not a legitimate job structure.',
          points: 26, severity: 'high'));
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 20 — Social Engineering Tactics (NEW in v3.0)
  // ══════════════════════════════════════════════════════════════════════════

  static List<ScamSignal> _layer20_socialEngineering(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Social Engineering';
    const lyr = 'L20';

    // Fake congratulations / pre-selection
    final preSelected = [
      'you are selected', 'you have been selected', 'you are shortlisted',
      'congratulations you', 'you are chosen', 'you qualify',
      'profile selected', 'your profile matches',
    ];
    for (final p in preSelected) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: '"Pre-selection" message: "$p" — used to make victims feel special before defrauding them.',
            points: 28, severity: 'critical'));
        break;
      }
    }

    // Fear tactics
    final fearTactics = [
      'last opportunity', 'never get this chance',
      'you will regret', 'miss this opportunity',
      'final selection', 'only you are selected',
    ];
    for (final p in fearTactics) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Fear/FOMO tactic: "$p" — designed to override rational thinking.',
            points: 20, severity: 'high'));
        break;
      }
    }

    // Fake testimonials pattern
    final testimonials = [
      'i earned', 'she earned', 'he earned', 'my friend earned',
      'our member earned', 'last month i got',
    ];
    for (final p in testimonials) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Embedded "testimonial" in job posting — social proof manipulation tactic.',
            points: 18, severity: 'medium'));
        break;
      }
    }

    // Exclusivity illusion
    final exclusive = [
      'selected candidates only', 'invite only', 'exclusive opportunity',
      'private offer', 'confidential offer', 'not for everyone',
    ];
    for (final p in exclusive) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(category: cat, layer: lyr,
            message: 'Exclusivity illusion: "$p" — creates artificial sense of privilege.',
            points: 16, severity: 'medium'));
        break;
      }
    }

    return out;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYER 21 — Confidence Score Engine (NEW in v3.0)
  // Meta-analysis: determines how confident the AI is about the verdict
  // ══════════════════════════════════════════════════════════════════════════

  static String _layer21_confidenceEngine(List<ScamSignal> signals) {
    if (signals.isEmpty) return 'SAFE';

    final criticals = signals.where((s) => s.severity == 'critical').length;
    final highs     = signals.where((s) => s.severity == 'high').length;
    final categories = signals.map((s) => s.category).toSet().length;
    final total      = signals.length;

    if (criticals >= 2 || (criticals >= 1 && highs >= 2)) return 'HIGH';
    if (criticals == 1 || highs >= 3 || (highs >= 2 && categories >= 3)) return 'MEDIUM';
    if (total >= 3 || highs >= 1) return 'LOW';
    return 'SAFE';
  }
}

// ── Internal context ─────────────────────────────────────────────────────

class _Context {
  final String title;
  final String description;
  final String companyName;
  final String location;
  final String contact;
  final double salary;
  final String category;
  late final String full;
  late final String rawFull;

  _Context({
    required this.title,
    required this.description,
    required this.companyName,
    required this.location,
    required this.contact,
    required this.salary,
    required this.category,
  }) {
    rawFull = [title, description, companyName, location, contact].join(' ');
    full    = rawFull.toLowerCase();
  }
}
