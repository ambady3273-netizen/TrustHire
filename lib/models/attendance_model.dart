import 'package:cloud_firestore/cloud_firestore.dart';

/// Geofence attendance log entry.
/// Created when seeker enters or exits job location geofence.
class AttendanceModel {
  final String   id;
  final String   applicationId;
  final String   seekerId;
  final String   seekerName;
  final String   jobId;
  final String   jobTitle;
  final String   event;       // 'clock_in' | 'clock_out'
  final double   lat;
  final double   lng;
  final DateTime timestamp;

  const AttendanceModel({
    required this.id,
    required this.applicationId,
    required this.seekerId,
    required this.seekerName,
    required this.jobId,
    required this.jobTitle,
    required this.event,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  bool get isClockIn  => event == 'clock_in';
  bool get isClockOut => event == 'clock_out';

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime ts;
    final raw = map['timestamp'];
    ts = raw is Timestamp ? raw.toDate() : DateTime.now();
    return AttendanceModel(
      id:            docId,
      applicationId: map['applicationId'] ?? '',
      seekerId:      map['seekerId']      ?? '',
      seekerName:    map['seekerName']    ?? '',
      jobId:         map['jobId']         ?? '',
      jobTitle:      map['jobTitle']      ?? '',
      event:         map['event']         ?? 'clock_in',
      lat:           (map['lat']          ?? 0).toDouble(),
      lng:           (map['lng']          ?? 0).toDouble(),
      timestamp:     ts,
    );
  }

  Map<String, dynamic> toMap() => {
    'applicationId': applicationId,
    'seekerId':      seekerId,
    'seekerName':    seekerName,
    'jobId':         jobId,
    'jobTitle':      jobTitle,
    'event':         event,
    'lat':           lat,
    'lng':           lng,
    'timestamp':     Timestamp.fromDate(timestamp),
  };
}
