import 'package:cloud_firestore/cloud_firestore.dart';

/// KYC status constants — single source of truth.
class KycStatus {
  static const String none      = 'none';
  static const String submitted = 'submitted';
  static const String verified  = 'verified';
  static const String rejected  = 'rejected';
}

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool verified;
  final double trustScore;
  final String profileImage;
  final Timestamp createdAt;
  final Timestamp lastLogin;

  // ── KYC ────────────────────────────────────────────────────
  final String kycStatus;
  final String governmentIdUrl;
  final String selfieUrl;
  final Timestamp? kycSubmittedAt;
  final Timestamp? kycVerifiedAt;
  final String kycVerifiedBy;
  final String kycRejectReason;

  // ── Suspension ─────────────────────────────────────────────
  /// true = account is suspended; user sees SuspendedScreen after login.
  final bool suspended;
  /// Human-readable reason shown to the suspended user.
  final String suspendedReason;
  /// UID of the admin who suspended the account.
  final String suspendedBy;

  // ── Referral ────────────────────────────────────────────────
  /// Unique referral code for this user (generated on registration).
  final String referralCode;
  /// UID of the user who referred this account (empty if organic).
  final String referredBy;

  // ── CV / Skills ─────────────────────────────────────────────
  /// Short bio shown to employers on the applicant card.
  final String bio;
  /// Comma-separated skills list e.g. "Driving, Cooking, Excel"
  final String skills;
  /// Work experience summary e.g. "2 years delivery, 1 year retail"
  final String experience;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.verified,
    required this.trustScore,
    required this.profileImage,
    required this.createdAt,
    required this.lastLogin,
    this.kycStatus        = KycStatus.none,
    this.governmentIdUrl  = '',
    this.selfieUrl        = '',
    this.kycSubmittedAt,
    this.kycVerifiedAt,
    this.kycVerifiedBy    = '',
    this.kycRejectReason  = '',
    this.suspended        = false,
    this.suspendedReason  = '',
    this.suspendedBy      = '',
    this.referralCode     = '',
    this.referredBy       = '',
    this.bio              = '',
    this.skills           = '',
    this.experience       = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid:             map['uid']          ?? '',
      fullName:        map['fullName']     ?? '',
      email:           map['email']        ?? '',
      role:            map['role']         ?? 'job_seeker',
      verified:        map['verified']     ?? false,
      trustScore:      (map['trustScore']  ?? 0).toDouble(),
      profileImage:    map['profileImage'] ?? '',
      createdAt:       map['createdAt']    ?? Timestamp.now(),
      lastLogin:       map['lastLogin']    ?? Timestamp.now(),
      kycStatus:       map['kycStatus']    ?? KycStatus.none,
      governmentIdUrl: map['governmentIdUrl'] ?? '',
      selfieUrl:       map['selfieUrl']    ?? '',
      kycSubmittedAt:  map['kycSubmittedAt']  as Timestamp?,
      kycVerifiedAt:   map['kycVerifiedAt']   as Timestamp?,
      kycVerifiedBy:   map['kycVerifiedBy']   ?? '',
      kycRejectReason: map['kycRejectReason'] ?? '',
      suspended:       map['suspended']       ?? false,
      suspendedReason: map['suspendedReason'] ?? '',
      suspendedBy:     map['suspendedBy']     ?? '',
      referralCode:    map['referralCode']    ?? '',
      referredBy:      map['referredBy']      ?? '',
      bio:             map['bio']             ?? '',
      skills:          map['skills']          ?? '',
      experience:      map['experience']      ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid':             uid,
      'fullName':        fullName,
      'email':           email,
      'role':            role,
      'verified':        verified,
      'trustScore':      trustScore,
      'profileImage':    profileImage,
      'createdAt':       createdAt,
      'lastLogin':       lastLogin,
      'kycStatus':       kycStatus,
      'governmentIdUrl': governmentIdUrl,
      'selfieUrl':       selfieUrl,
      'kycSubmittedAt':  kycSubmittedAt,
      'kycVerifiedAt':   kycVerifiedAt,
      'kycVerifiedBy':   kycVerifiedBy,
      'kycRejectReason': kycRejectReason,
      'suspended':       suspended,
      'suspendedReason': suspendedReason,
      'suspendedBy':     suspendedBy,
      'referralCode':    referralCode,
      'referredBy':      referredBy,
      'bio':             bio,
      'skills':          skills,
      'experience':      experience,
    };
  }

  UserModel copyWith({
    String?    uid,
    String?    fullName,
    String?    email,
    String?    role,
    bool?      verified,
    double?    trustScore,
    String?    profileImage,
    Timestamp? createdAt,
    Timestamp? lastLogin,
    String?    kycStatus,
    String?    governmentIdUrl,
    String?    selfieUrl,
    Timestamp? kycSubmittedAt,
    Timestamp? kycVerifiedAt,
    String?    kycVerifiedBy,
    String?    kycRejectReason,
    bool?      suspended,
    String?    suspendedReason,
    String?    suspendedBy,
    String?    referralCode,
    String?    referredBy,
    String?    bio,
    String?    skills,
    String?    experience,
  }) {
    return UserModel(
      uid:             uid             ?? this.uid,
      fullName:        fullName        ?? this.fullName,
      email:           email           ?? this.email,
      role:            role            ?? this.role,
      verified:        verified        ?? this.verified,
      trustScore:      trustScore      ?? this.trustScore,
      profileImage:    profileImage    ?? this.profileImage,
      createdAt:       createdAt       ?? this.createdAt,
      lastLogin:       lastLogin       ?? this.lastLogin,
      kycStatus:       kycStatus       ?? this.kycStatus,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      selfieUrl:       selfieUrl       ?? this.selfieUrl,
      kycSubmittedAt:  kycSubmittedAt  ?? this.kycSubmittedAt,
      kycVerifiedAt:   kycVerifiedAt   ?? this.kycVerifiedAt,
      kycVerifiedBy:   kycVerifiedBy   ?? this.kycVerifiedBy,
      kycRejectReason: kycRejectReason ?? this.kycRejectReason,
      suspended:       suspended       ?? this.suspended,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      suspendedBy:     suspendedBy     ?? this.suspendedBy,
      referralCode:    referralCode    ?? this.referralCode,
      referredBy:      referredBy      ?? this.referredBy,
      bio:             bio             ?? this.bio,
      skills:          skills          ?? this.skills,
      experience:      experience      ?? this.experience,
    );
  }
}
