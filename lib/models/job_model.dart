import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String employerId;
  final String companyName;
  final String title;
  final String description;
  final String category;
  final String location;
  final double salary;
  final String contact;

  final int riskScore;
  final String status;

  final List<String> scamReasons;
  final bool aiAnalyzed;

  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.employerId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.salary,
    required this.contact,
    required this.riskScore,
    required this.status,
    this.scamReasons = const [],
    this.aiAnalyzed = false,
    required this.createdAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory JobModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime createdAt;

    final createdAtData = map['createdAt'];

    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return JobModel(
      id: docId,
      employerId: map['employerId'] ?? '',
      companyName: map['companyName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      salary: (map['salary'] ?? 0).toDouble(),
      contact: map['contact'] ?? '',
      riskScore: (map['riskScore'] ?? 0).toInt(),
      status: map['status'] ?? 'pending_review',

      scamReasons: List<String>.from(
        map['scamReasons'] ?? [],
      ),

      aiAnalyzed: map['aiAnalyzed'] ?? false,

      createdAt: createdAt,
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'salary': salary,
      'contact': contact,

      'riskScore': riskScore,
      'status': status,

      'scamReasons': scamReasons,
      'aiAnalyzed': aiAnalyzed,

      'createdAt': Timestamp.fromDate(
        createdAt,
      ),
    };
  }
}