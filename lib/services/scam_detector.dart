// ═══════════════════════════════════════════════════════════════════════════
// TrustHire Advanced AI Scam Detection Engine  v2.0
//
// Multi-layer analysis system with 15 independent detection modules:
//
//  Layer 1  — Financial Fraud Signals          (payment demands, deposits)
//  Layer 2  — Salary Intelligence              (unrealistic pay analysis)
//  Layer 3  — Urgency & Pressure Manipulation  (FOMO, time pressure tactics)
//  Layer 4  — Identity Concealment             (anonymous, vague employer)
//  Layer 5  — Communication Channel Red Flags  (WhatsApp-only, Telegram)
//  Layer 6  — MLM / Pyramid Scheme Markers     (downline, referral income)
//  Layer 7  — Data Harvesting Signals          (Aadhaar upfront, OTP asks)
//  Layer 8  — Linguistic Deception Markers     (excessive hype, ALL CAPS)
//  Layer 9  — Implausibility Checks            (too-good-to-be-true combos)
//  Layer 10 — Suspicious URL / Link Detection  (short links, Telegram links)
//  Layer 11 — Job Content Quality              (description length, detail)
//  Layer 12 — Tamil / Regional Language Scam Patterns
//  Layer 13 — Work-from-Home Fraud Signals     (online task fraud)
//  Layer 14 — Fake Credential / Company Claims (ISO-certified, MNC claims)
//  Layer 15 — Contextual Cross-Signal Amplifier (multiple weak → strong)
//
// Scoring:
//   0–25   → SAFE      (green  — auto-approved)
//   26–55  → REVIEW    (yellow — admin checks)
//   56–100 → HIGH RISK (red    — blocked)
// ═══════════════════════════════════════════════════════════════════════════

// ignore_for_file: non_constant_identifier_names, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps

// ── Result model ─────────────────────────────────────────────────────────

class ScamSignal {
  final String category;
  final String message;
  final int    points;
  final String severity; // 'low' | 'medium' | 'high' | 'critical'

  const ScamSignal({
    required this.category,
    required this.message,
    required this.points,
    required this.severity,
  });
}

class ScamDetectionResult {
  final int               riskScore;
  final String            riskLevel;
  final List<String>      reasons;       // backward-compat display list
  final List<ScamSignal>  signals;       // detailed signals per layer
  final Map<String,int>   categoryScores; // per-category breakdown

  const ScamDetectionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
    required this.signals,
    required this.categoryScores,
  });

  bool get isSafe      => riskScore <= 25;
  bool get needsReview => riskScore > 25 && riskScore <= 55;
  bool get isHighRisk  => riskScore > 55;

  /// Human-readable colour label
  String get riskEmoji {
    if (isSafe)      return '✅ Safe';
    if (needsReview) return '⚠️ Needs Review';
    return '🚨 High Risk';
  }
}

// ── Main detector ─────────────────────────────────────────────────────────

class ScamDetector {

  // ──────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ──────────────────────────────────────────────────────────────

  static ScamDetectionResult analyze({
    required String title,
    required String description,
    required String companyName,
    required String location,
    required String contact,
    required double salary,
  }) {
    final ctx = _Context(
      title:       title.trim(),
      description: description.trim(),
      companyName: companyName.trim(),
      location:    location.trim(),
      contact:     contact.trim(),
      salary:      salary,
    );

    final signals = <ScamSignal>[];

    // Run all 15 layers
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

    // Aggregate score
    int rawScore = signals.fold(0, (sum, s) => sum + s.points);
    final int score = rawScore.clamp(0, 100);

    // Category breakdown
    final Map<String, int> catScores = {};
    for (final s in signals) {
      catScores[s.category] = (catScores[s.category] ?? 0) + s.points;
    }

    // Risk level
    final String riskLevel;
    if (score <= 25)      riskLevel = 'Safe';
    else if (score <= 55) riskLevel = 'Needs Review';
    else                  riskLevel = 'High Risk';

    // Build backward-compat reasons list
    final List<String> reasons = signals.isEmpty
        ? ['No scam indicators detected. Job looks legitimate.']
        : signals.map((s) => s.message).toList();

    return ScamDetectionResult(
      riskScore:      score,
      riskLevel:      riskLevel,
      reasons:        reasons,
      signals:        signals,
      categoryScores: catScores,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 1 — Financial Fraud Signals
  // Detects any demand for money FROM the applicant
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer01_financialFraud(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Financial Fraud';

    final criticalTerms = {
      'registration fee':   40, 'registration fees': 40,
      'joining fee':        40, 'joining fees':       40,
      'security deposit':   45, 'deposit required':   45,
      'pay first':          45, 'advance payment':    45,
      'processing fee':     38, 'processing fees':    38,
      'training fee':       35, 'training fees':      35,
      'investment required':50, 'invest to earn':     50,
      'send money':         45, 'pay to work':        50,
      'pay and earn':       50, 'money back guarantee':35,
      'refundable deposit': 40, 'caution deposit':    40,
      'kyc fee':            45, 'kyc charge':         45,
      'document charge':    40, 'verification fee':   40,
      'activation fee':     40, 'starter kit fee':    40,
      'kit fee':            35, 'uniform fee':        30,
    };

    for (final e in criticalTerms.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Demands money from applicant: "${e.key}" — '
                    'Legitimate employers NEVER charge workers.',
          points:   e.value,
          severity: e.value >= 45 ? 'critical' : 'high',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 2 — Salary Intelligence
  // Context-aware salary analysis by job category
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer02_salaryIntelligence(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Salary Intelligence';

    if (c.salary <= 0) {
      out.add(const ScamSignal(
        category: cat,
        message:  'No salary mentioned — could be used to lure applicants '
                  'with vague promises.',
        points:   10,
        severity: 'low',
      ));
      return out;
    }

    // Unrealistically high
    if (c.salary > 150000) {
      out.add(ScamSignal(
        category: cat,
        message:  'Salary ₹${c.salary.toStringAsFixed(0)}/mo is extremely '
                  'unrealistic for a part-time job. Scammers use high '
                  'salaries to attract victims.',
        points:   40,
        severity: 'critical',
      ));
    } else if (c.salary > 80000) {
      out.add(ScamSignal(
        category: cat,
        message:  'Salary ₹${c.salary.toStringAsFixed(0)}/mo is very high '
                  'for a part-time role. Verify this claim carefully.',
        points:   25,
        severity: 'high',
      ));
    } else if (c.salary > 50000) {
      out.add(ScamSignal(
        category: cat,
        message:  'Salary ₹${c.salary.toStringAsFixed(0)}/mo is above '
                  'typical range for part-time work.',
        points:   12,
        severity: 'medium',
      ));
    }

    // Unrealistically low (possible exploitation)
    if (c.salary > 0 && c.salary < 3000) {
      out.add(ScamSignal(
        category: cat,
        message:  'Salary ₹${c.salary.toStringAsFixed(0)}/mo is below '
                  'minimum wage — possible labour exploitation.',
        points:   15,
        severity: 'medium',
      ));
    }

    // Suspiciously round / fake-looking numbers
    if (c.salary == 99999 || c.salary == 100000 ||
        c.salary == 50000 || c.salary == 75000) {
      // Only flag if combined with other issues (cross-signal)
    }

    // "Daily income" language with salary mismatch
    if ((c.full.contains('per day') || c.full.contains('daily income') ||
         c.full.contains('daily earn')) && c.salary > 30000) {
      out.add(ScamSignal(
        category: cat,
        message:  'Claims "daily income/earnings" with high monthly salary — '
                  'inconsistent and a common scam tactic.',
        points:   20,
        severity: 'high',
      ));
    }

    // Guaranteed income phrasing
    final guaranteePhrases = [
      'guaranteed income', 'guaranteed salary', 'guaranteed earnings',
      'guaranteed ₹', 'guaranteed rs', 'guaranteed payment',
      'fixed income guaranteed', '100% guaranteed',
    ];
    for (final p in guaranteePhrases) {
      if (c.full.contains(p)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Claims "guaranteed income/salary" — no legitimate '
                    'employer can guarantee exact earnings.',
          points:   20,
          severity: 'high',
        ));
        break;
      }
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 3 — Urgency & Pressure Manipulation
  // FOMO tactics, artificial deadlines, pressure language
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer03_urgencyPressure(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Urgency / Pressure';

    final urgencyPhrases = {
      'limited seats':        15, 'limited vacancies':    15,
      'only few seats':       15, 'hurry':                10,
      'apply immediately':    10, 'apply now':             5,
      'last chance':          15, 'closing soon':         12,
      'today only':           20, 'this week only':       15,
      'first come first':     10, 'urgent hiring':        10,
      'immediate joining':    12, 'join today':           15,
      'dont miss':            12, "don't miss":           12,
      'offer expires':        15, 'limited time offer':   20,
      'act fast':             15, 'respond quickly':      10,
      'walk in interview':     5, 'instant offer':        15,
      'no waiting':           10, 'direct joining':       10,
    };

    int urgencyHits = 0;
    for (final e in urgencyPhrases.entries) {
      if (c.full.contains(e.key)) {
        urgencyHits++;
        if (urgencyHits <= 2) { // cap to avoid double-counting
          out.add(ScamSignal(
            category: cat,
            message:  'Urgency tactic detected: "${e.key}" — '
                      'scammers use pressure to prevent careful thinking.',
            points:   e.value,
            severity: e.value >= 15 ? 'high' : 'medium',
          ));
        }
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 4 — Identity Concealment
  // Anonymous employers, vague company info
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer04_identityConcealment(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Identity / Company';

    // Missing company name
    if (c.companyName.isEmpty || c.companyName.length < 3) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Company name is missing or too vague — legitimate '
                  'employers always disclose their company name.',
        points:   18,
        severity: 'high',
      ));
    }

    // Generic/fake company name patterns
    final genericNames = [
      'private limited', 'pvt ltd', 'company', 'firm',
      'enterprise', 'associates', 'group', 'services',
    ];
    final compLower = c.companyName.toLowerCase();
    if (genericNames.any((g) => compLower == g || compLower.trim() == g)) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Company name is suspiciously generic with no specific '
                  'identity.',
        points:   12,
        severity: 'medium',
      ));
    }

    // No location
    if (c.location.isEmpty) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Job location is not specified — legitimate jobs always '
                  'state where the work takes place.',
        points:   12,
        severity: 'medium',
      ));
    }

    // "Anywhere" / "remote" for in-person job types
    final inPersonCategories = ['delivery', 'retail', 'restaurant',
        'event work', 'office work'];
    final isInPerson = inPersonCategories.any(
        (cat) => c.full.contains(cat));
    if (isInPerson &&
        (c.full.contains('work from home') ||
         c.full.contains('remote') ||
         c.full.contains('anywhere'))) {
      out.add(const ScamSignal(
        category: 'Implausibility',
        message:  'Claims remote/work-from-home for a job type that '
                  'requires physical presence.',
        points:   20,
        severity: 'high',
      ));
    }

    // No contact info
    if (c.contact.isEmpty) {
      out.add(const ScamSignal(
        category: cat,
        message:  'No contact information provided.',
        points:   8,
        severity: 'low',
      ));
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 5 — Communication Channel Red Flags
  // WhatsApp-only, Telegram-only, non-official channels
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer05_communicationRedFlags(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Communication';

    final channelFlags = {
      'whatsapp only':               20,
      'contact on whatsapp':         18,
      'whatsapp me':                 15,
      'wa.me':                       18,
      'telegram only':               25,
      'contact on telegram':         22,
      't.me/':                       22,
      'telegram.me':                 22,
      'no calls':                    15,
      'sms only':                    12,
      'message only':                10,
      'dm for details':              15,
      'inbox for details':           15,
      'contact via instagram':       18,
      'contact via facebook':        15,
      'google form':                 10,
      'fill the form below':         8,
    };

    for (final e in channelFlags.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Suspicious contact channel: "${e.key}" — '
                    'legitimate employers use official email/phone.',
          points:   e.value,
          severity: e.value >= 20 ? 'high' : 'medium',
        ));
      }
    }

    // Phone number analysis
    final phoneRegex = RegExp(r'\b[6-9]\d{9}\b');
    final phones = phoneRegex.allMatches(c.full).length;
    if (phones >= 3) {
      out.add(ScamSignal(
        category: cat,
        message:  'Contains ${phones} phone numbers — unusual for a '
                  'legitimate posting.',
        points:   12,
        severity: 'medium',
      ));
    }

    // Email domain check
    final emailRegex = RegExp(r'[\w.+-]+@([\w-]+\.)+[\w-]+');
    final emails = emailRegex.allMatches(c.full);
    for (final m in emails) {
      final domain = m.group(1)?.toLowerCase() ?? '';
      if (['gmail', 'yahoo', 'hotmail', 'outlook', 'rediffmail']
          .any((d) => domain.contains(d))) {
        // Personal email — flag only if company claims to be large
        if (c.full.contains('mnc') || c.full.contains('multinational') ||
            c.full.contains('international') || c.full.contains('global')) {
          out.add(ScamSignal(
            category: cat,
            message:  'Claims to be MNC/international but uses personal '
                      'email (${m.group(0)}).',
            points:   18,
            severity: 'high',
          ));
          break;
        }
      }
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 6 — MLM / Pyramid Scheme Markers
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer06_mlmPyramid(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'MLM / Pyramid';

    final mlmPhrases = {
      'refer and earn':       25, 'referral income':      25,
      'referral bonus':       20, 'bring more people':    30,
      'recruit members':      30, 'downline':             35,
      'network marketing':    25, 'multi level':          30,
      'multilevel':           30, 'chain marketing':      35,
      'pyramid':              35, 'team building income': 25,
      'passive income':       15, 'residual income':      20,
      'binary income':        35, 'matrix plan':          35,
      'franchise fee':        20, 'dealership fee':       20,
      'distributorship':      15, 'direct selling':       12,
      'earn through others':  30, 'earn per referral':    25,
      'build your team':      20, 'grow your network':    20,
    };

    for (final e in mlmPhrases.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'MLM/pyramid scheme marker: "${e.key}" — '
                    'income based on recruiting others is a red flag.',
          points:   e.value,
          severity: e.value >= 30 ? 'critical' : 'high',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 7 — Data Harvesting Signals
  // Aadhaar/PAN upfront, OTP requests, bank details early
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer07_dataHarvesting(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Data Harvesting';

    final dataFlags = {
      'send aadhaar':          40, 'share aadhaar':        40,
      'aadhaar number':        35, 'aadhaar card':         30,
      'send pan':              35, 'pan card number':      30,
      'bank account number':   40, 'account details':      35,
      'send bank details':     40, 'otp':                  25,
      'share otp':             40, 'verify otp':           30,
      'send photo':            15, 'send your photo':      20,
      'passport copy':         25, 'id proof required':    15,
      'submit documents':      10, 'upload aadhaar':       35,
      'credit card':           40, 'debit card':           40,
      'card number':           40, 'cvv':                  45,
    };

    for (final e in dataFlags.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Requests sensitive personal data: "${e.key}" — '
                    'never share ID/banking data during job applications.',
          points:   e.value,
          severity: e.value >= 35 ? 'critical' : 'high',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 8 — Linguistic Deception Markers
  // Excessive hype, ALL CAPS abuse, grammar issues
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer08_linguisticDeception(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Linguistic Deception';

    // ALL CAPS word ratio
    final words = c.rawFull.split(RegExp(r'\s+'));
    if (words.length > 5) {
      final capsWords = words.where(
        (w) => w.length > 3 && w == w.toUpperCase() &&
               RegExp(r'^[A-Z]+$').hasMatch(w),
      ).length;
      final capsRatio = capsWords / words.length;
      if (capsRatio > 0.25) {
        out.add(ScamSignal(
          category: cat,
          message:  '${(capsRatio * 100).toStringAsFixed(0)}% of words are '
                    'in ALL CAPS — aggressive promotional language.',
          points:   15,
          severity: 'medium',
        ));
      }
    }

    // Excessive exclamation marks
    final excl = '!'.allMatches(c.rawFull).length;
    if (excl >= 3) {
      out.add(ScamSignal(
        category: cat,
        message:  'Contains $excl exclamation marks — over-hyped writing '
                  'is a common scam trait.',
        points:   excl >= 6 ? 15 : 8,
        severity: excl >= 6 ? 'medium' : 'low',
      ));
    }

    // Emoji abuse in job description
    final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
        unicode: true);
    final emojiCount = emojiRegex.allMatches(c.rawFull).length;
    if (emojiCount >= 5) {
      out.add(ScamSignal(
        category: cat,
        message:  'Excessive use of emojis ($emojiCount) — unprofessional '
                  'and common in scam postings.',
        points:   10,
        severity: 'low',
      ));
    }

    // Hype phrases
    final hypePhrases = {
      'earn lakhs':     25, 'earn crores':       30,
      'be your own boss': 15, 'financial freedom': 15,
      'dream job':       8, 'life changing':      12,
      'once in a lifetime': 15, 'golden opportunity': 15,
      'life time opportunity': 18, 'god gifted':    12,
      '100% profit':    20, '200% return':         25,
      'double your money': 35, 'triple your income': 35,
      'zero risk':       20, 'risk free':           18,
      'no target':       10, 'no pressure':         8,
    };

    for (final e in hypePhrases.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Hype language: "${e.key}" — exaggerated claims '
                    'are used to lower victim\'s guard.',
          points:   e.value,
          severity: e.value >= 20 ? 'high' : 'medium',
        ));
      }
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 9 — Implausibility Checks
  // Combinations that are logically impossible
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer09_implausibility(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Implausibility';

    // High salary + no experience
    if (c.salary > 40000 &&
        (c.full.contains('no experience') ||
         c.full.contains('freshers') ||
         c.full.contains('no qualification'))) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Offers very high salary for no-experience/fresher role — '
                  'implausible combination used to attract victims.',
        points:   22,
        severity: 'high',
      ));
    }

    // Part-time + extremely high pay
    if ((c.full.contains('part time') || c.full.contains('part-time') ||
         c.full.contains('parttime')) && c.salary > 60000) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Part-time role with salary over ₹60,000 — '
                  'extremely rare and suspicious.',
        points:   20,
        severity: 'high',
      ));
    }

    // "Work 2 hours" + high salary
    final shortHoursRegex = RegExp(
        r'(work|only|just)\s+(1|2|3|one|two|three)\s+hour');
    if (shortHoursRegex.hasMatch(c.full) && c.salary > 20000) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Claims high salary for just 1-3 hours of work per day — '
                  'classic "too good to be true" scam bait.',
        points:   25,
        severity: 'high',
      ));
    }

    // Hiring hundreds of people at once
    final massHireRegex = RegExp(r'(hiring|recruit|need|want)\s+\d{3,}');
    if (massHireRegex.hasMatch(c.full)) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Claims to hire hundreds of people — mass hiring without '
                  'specifics is a scam indicator.',
        points:   15,
        severity: 'medium',
      ));
    }

    // "Earn ₹XXXX per day" calculations
    final perDayRegex = RegExp(r'(earn|get|receive)\s+[₹rs\.]?\s*\d+\s*per\s*day');
    if (perDayRegex.hasMatch(c.full)) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Promises specific daily earnings — legitimate salaries '
                  'are monthly, not daily.',
        points:   18,
        severity: 'high',
      ));
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 10 — Suspicious URLs and Links
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer10_suspiciousUrls(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Suspicious Links';

    final suspiciousPatterns = {
      'bit.ly':        20, 'tinyurl.com':   20,
      'shorturl.at':   20, 'ow.ly':         18,
      'goo.gl':        15, 'rb.gy':         20,
      'cutt.ly':       18, 'is.gd':         18,
      't.me/':         25, 'telegram.me':   25,
      'wa.me':         20, 'click here':    10,
      'apply here':     8, 'form link':     10,
      'google form':   12, 'docs.google':   10,
    };

    for (final e in suspiciousPatterns.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Suspicious link detected: "${e.key}" — '
                    'link shorteners are used to hide malicious destinations.',
          points:   e.value,
          severity: e.value >= 20 ? 'high' : 'medium',
        ));
      }
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 11 — Job Content Quality
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer11_contentQuality(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Content Quality';

    // Very short description
    if (c.description.length < 30) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Job description is dangerously short — legitimate jobs '
                  'explain responsibilities clearly.',
        points:   15,
        severity: 'medium',
      ));
    } else if (c.description.length < 80) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Job description is too brief — more details expected '
                  'for a legitimate posting.',
        points:   8,
        severity: 'low',
      ));
    }

    // Very short title
    if (c.title.length < 5) {
      out.add(const ScamSignal(
        category: cat,
        message:  'Job title is too short to be meaningful.',
        points:   8,
        severity: 'low',
      ));
    }

    // Repeated words (copy-paste spam)
    final wordList = c.full.split(RegExp(r'\s+'));
    if (wordList.length > 10) {
      final wordFreq = <String, int>{};
      for (final w in wordList) {
        if (w.length > 4) wordFreq[w] = (wordFreq[w] ?? 0) + 1;
      }
      final maxFreq = wordFreq.values.fold(0, (a, b) => a > b ? a : b);
      if (maxFreq > 8) {
        out.add(ScamSignal(
          category: cat,
          message:  'Description contains heavy word repetition — '
                    'suggests copy-paste spam content.',
          points:   10,
          severity: 'medium',
        ));
      }
    }

    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 12 — Tamil / Regional Language Scam Patterns
  // Common scam phrases in Tamil/transliterated form
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer12_regionalScamPatterns(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Regional Scam Patterns';

    final regionalPhrases = {
      // Tamil transliterations
      'velai illama':       15, // "without work"
      'easy velai':         18,
      'salary guarantee':   20,
      'income guarantee':   20,
      'panam tharum':       25, // "will give money"
      'fees kattu':         35, // "pay fees"
      'registration pattu': 35, // "registration pay"
      'amount pattu':       35, // "pay amount"
      'thadai illai':       15, // "no restriction"
      // Hindi transliterations
      'paise kamao':        15, // "earn money"
      'ghar baithe':        12, // "sitting at home"
      'registration karo':  30,
      'fees bharo':         35,
      'guaranteed kamai':   25,
      'direct paisa':       20,
      // Common English-Tamil mix
      'monthly salary guarantee': 25,
      'fixed salary guarantee':   25,
      'age no bar':               10,
      'qualification no bar':     12,
      'caste no bar':              5,
    };

    for (final e in regionalPhrases.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Regional scam phrase detected: "${e.key}".',
          points:   e.value,
          severity: e.value >= 30 ? 'critical' : 'high',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 13 — Work-From-Home Fraud Signals
  // Online task fraud, product review fraud
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer13_wfhFraud(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'WFH / Online Fraud';

    final wfhScamPhrases = {
      'product review':      20, 'like and subscribe':    20,
      'youtube task':        25, 'amazon task':           25,
      'flipkart task':       25, 'online task':           18,
      'data entry from home':12, 'copy paste job':        20,
      'typing job from home':15, 'ad posting':            20,
      'advertisement posting':20,'form filling':          18,
      'captcha work':        20, 'survey job':            15,
      'click ads':           25, 'click and earn':        25,
      'watch videos and earn':25,'follow and earn':       20,
      'instagram task':      22, 'facebook task':         20,
      'simple task':         10, 'easy task':             10,
      'mobile job':          12, 'work on mobile':        12,
      'work from phone':     12, 'recharge task':         25,
      'reselling':           10, 'dropshipping from home':12,
    };

    for (final e in wfhScamPhrases.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'WFH fraud indicator: "${e.key}" — '
                    'online task jobs are frequently used to defraud workers.',
          points:   e.value,
          severity: e.value >= 20 ? 'high' : 'medium',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 14 — Fake Credential / Company Claims
  // ISO certifications, MNC, government linkage
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer14_fakeCredentials(_Context c) {
    final out = <ScamSignal>[];
    const cat = 'Fake Credentials';

    final fakeClaims = {
      'iso certified':         15, 'iso 9001':              12,
      'government approved':   25, 'government registered': 20,
      'rbi approved':          30, 'sebi registered':       25,
      'income tax approved':   30, 'ministry approved':     30,
      'award winning':         10, 'no. 1 company':         12,
      'top rated company':     10, 'verified company':      10,
      'trusted company':        8, 'reputed company':        8,
      '100% genuine':          15, 'genuine company':       10,
      'real company':          12, 'legit company':         12,
      'not a scam':            20, 'no fraud':              18,
      'we are not fraud':      25, 'genuine work':          12,
      'mnc company':           10, 'fortune 500':           15,
    };

    for (final e in fakeClaims.entries) {
      if (c.full.contains(e.key)) {
        out.add(ScamSignal(
          category: cat,
          message:  'Unverifiable claim: "${e.key}" — scammers often make '
                    'false authority claims to appear legitimate.',
          points:   e.value,
          severity: e.value >= 20 ? 'high' : 'medium',
        ));
      }
    }
    return out;
  }

  // ──────────────────────────────────────────────────────────────
  // LAYER 15 — Cross-Signal Amplifier
  // Multiple weak signals together = stronger risk
  // ──────────────────────────────────────────────────────────────

  static List<ScamSignal> _layer15_crossSignalAmplifier(
      List<ScamSignal> existing) {
    final out = <ScamSignal>[];
    const cat = 'Pattern Analysis';

    final categories = existing.map((s) => s.category).toSet();
    final totalSignals = existing.length;

    // 3+ different categories triggered
    if (categories.length >= 3 && totalSignals >= 4) {
      out.add(ScamSignal(
        category: cat,
        message:  'Multiple suspicious patterns detected across '
                  '${categories.length} different risk categories — '
                  'combined indicators significantly increase fraud risk.',
        points:   15,
        severity: 'high',
      ));
    }

    // 5+ total signals
    if (totalSignals >= 5) {
      out.add(ScamSignal(
        category: cat,
        message:  '$totalSignals individual risk signals detected — '
                  'high signal count is a strong predictor of fraud.',
        points:   10,
        severity: 'high',
      ));
    }

    // Financial + Data harvesting together = very dangerous combo
    final hasFinancial = existing.any((s) => s.category == 'Financial Fraud');
    final hasData      = existing.any((s) => s.category == 'Data Harvesting');
    if (hasFinancial && hasData) {
      out.add(const ScamSignal(
        category: cat,
        message:  'CRITICAL: Combination of financial demands AND personal '
                  'data requests — this is a high-confidence scam profile.',
        points:   20,
        severity: 'critical',
      ));
    }

    // MLM + Urgency = pyramid scheme with pressure tactics
    final hasMlm     = existing.any((s) => s.category == 'MLM / Pyramid');
    final hasUrgency = existing.any((s) => s.category == 'Urgency / Pressure');
    if (hasMlm && hasUrgency) {
      out.add(const ScamSignal(
        category: cat,
        message:  'MLM scheme combined with urgency pressure — '
                  'a textbook pyramid scheme recruitment tactic.',
        points:   15,
        severity: 'critical',
      ));
    }

    return out;
  }
}

// ── Internal context object ───────────────────────────────────────────────

class _Context {
  final String title;
  final String description;
  final String companyName;
  final String location;
  final String contact;
  final double salary;

  /// Lowercased concatenation of all text fields
  late final String full;

  /// Original-case concatenation (for caps analysis)
  late final String rawFull;

  _Context({
    required this.title,
    required this.description,
    required this.companyName,
    required this.location,
    required this.contact,
    required this.salary,
  }) {
    rawFull = [title, description, companyName, location, contact].join(' ');
    full    = rawFull.toLowerCase();
  }
}
