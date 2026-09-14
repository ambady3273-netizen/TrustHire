import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────
// LocationService
//
// Two responsibilities:
//   1. getCurrentPosition()  — one-shot for "Near Me" filter
//   2. startLiveTracking()   — streams seeker GPS to Firestore
//      so employer can watch in real-time.
//
// Firestore path for live location:
//   liveLocations/{applicationId}
//     seekerId, seekerName, lat, lng, updatedAt
// ─────────────────────────────────────────────────────────────

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _trackingSub;

  // ── Permission helper ──────────────────────────────────────

  Future<bool> requestPermission() async {
    // permission_handler for fine-grained control
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  // ── One-shot position ──────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  // ── Distance helper (metres) ───────────────────────────────

  double distanceBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  // ── Live tracking — seeker side ───────────────────────────

  /// Starts streaming the seeker's GPS position to Firestore every
  /// ~5 seconds so the employer can watch in real-time.
  ///
  /// Call [stopLiveTracking] when the seeker leaves the job screen.
  Future<bool> startLiveTracking({
    required String applicationId,
    required String seekerId,
    required String seekerName,
  }) async {
    final granted = await requestPermission();
    if (!granted) return false;

    await _trackingSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 metres moved
    );

    _trackingSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) {
      FirebaseFirestore.instance
          .collection('liveLocations')
          .doc(applicationId)
          .set({
        'seekerId':   seekerId,
        'seekerName': seekerName,
        'lat':        pos.latitude,
        'lng':        pos.longitude,
        'accuracy':   pos.accuracy,
        'updatedAt':  FieldValue.serverTimestamp(),
        'active':     true,
      }, SetOptions(merge: true));
    });

    debugPrint('[LocationService] Live tracking started for $applicationId');
    return true;
  }

  Future<void> stopLiveTracking(String applicationId) async {
    await _trackingSub?.cancel();
    _trackingSub = null;
    // Mark as inactive so employer UI knows seeker stopped sharing
    try {
      await FirebaseFirestore.instance
          .collection('liveLocations')
          .doc(applicationId)
          .set({'active': false}, SetOptions(merge: true));
    } catch (_) {}
    debugPrint('[LocationService] Live tracking stopped for $applicationId');
  }

  // ── Live location stream — employer side ──────────────────

  /// Returns a real-time stream of the seeker's location for an application.
  Stream<LiveLocation?> watchLiveLocation(String applicationId) {
    return FirebaseFirestore.instance
        .collection('liveLocations')
        .doc(applicationId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return LiveLocation.fromMap(snap.data()!);
    });
  }
}

// ─────────────────────────────────────────────────────────────
// LiveLocation model
// ─────────────────────────────────────────────────────────────

class LiveLocation {
  final String seekerId;
  final String seekerName;
  final double lat;
  final double lng;
  final double accuracy;
  final bool active;
  final DateTime? updatedAt;

  const LiveLocation({
    required this.seekerId,
    required this.seekerName,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.active,
    this.updatedAt,
  });

  factory LiveLocation.fromMap(Map<String, dynamic> map) {
    DateTime? updatedAt;
    final raw = map['updatedAt'];
    if (raw is Timestamp) updatedAt = raw.toDate();

    return LiveLocation(
      seekerId:   map['seekerId']   ?? '',
      seekerName: map['seekerName'] ?? '',
      lat:        (map['lat']       ?? 0).toDouble(),
      lng:        (map['lng']       ?? 0).toDouble(),
      accuracy:   (map['accuracy']  ?? 0).toDouble(),
      active:     map['active']     ?? false,
      updatedAt:  updatedAt,
    );
  }
}
