import 'package:cloud_firestore/cloud_firestore.dart';

/// KYC status constants — single source of truth.
class KycStatus {
  static const String none = 'none';
  static const String submitted = 'submitted';
  static const String verified = 'verified';
  static const String rejected = 'rejected';
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

  // ── KYC fields ─────────────────────────────────────────────
  /// One of: none | submitted | verified | rejected
  final String kycStatus;
  final String governmentIdUrl;
  final String selfieUrl;
  final Timestamp? kycSubmittedAt;
  final Timestamp? kycVerifiedAt;
  final String kycVerifiedBy;   // admin UID who verified/rejected
  final String kycRejectReason; // populated when kycStatus == rejected

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
    this.kycStatus = KycStatus.none,
    this.governmentIdUrl = '',
    this.selfieUrl = '',
    this.kycSubmittedAt,
    this.kycVerifiedAt,
    this.kycVerifiedBy = '',
    this.kycRejectReason = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'job_seeker',
      verified: map['verified'] ?? false,
      trustScore: (map['trustScore'] ?? 0).toDouble(),
      profileImage: map['profileImage'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastLogin: map['lastLogin'] ?? Timestamp.now(),
      kycStatus: map['kycStatus'] ?? KycStatus.none,
      governmentIdUrl: map['governmentIdUrl'] ?? '',
      selfieUrl: map['selfieUrl'] ?? '',
      kycSubmittedAt: map['kycSubmittedAt'] as Timestamp?,
      kycVerifiedAt: map['kycVerifiedAt'] as Timestamp?,
      kycVerifiedBy: map['kycVerifiedBy'] ?? '',
      kycRejectReason: map['kycRejectReason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'verified': verified,
      'trustScore': trustScore,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'kycStatus': kycStatus,
      'governmentIdUrl': governmentIdUrl,
      'selfieUrl': selfieUrl,
      'kycSubmittedAt': kycSubmittedAt,
      'kycVerifiedAt': kycVerifiedAt,
      'kycVerifiedBy': kycVerifiedBy,
      'kycRejectReason': kycRejectReason,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    bool? verified,
    double? trustScore,
    String? profileImage,
    Timestamp? createdAt,
    Timestamp? lastLogin,
    String? kycStatus,
    String? governmentIdUrl,
    String? selfieUrl,
    Timestamp? kycSubmittedAt,
    Timestamp? kycVerifiedAt,
    String? kycVerifiedBy,
    String? kycRejectReason,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      verified: verified ?? this.verified,
      trustScore: trustScore ?? this.trustScore,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      kycStatus: kycStatus ?? this.kycStatus,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      kycSubmittedAt: kycSubmittedAt ?? this.kycSubmittedAt,
      kycVerifiedAt: kycVerifiedAt ?? this.kycVerifiedAt,
      kycVerifiedBy: kycVerifiedBy ?? this.kycVerifiedBy,
      kycRejectReason: kycRejectReason ?? this.kycRejectReason,
    );
  }
}
