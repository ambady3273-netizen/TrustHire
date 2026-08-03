import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
  }
}