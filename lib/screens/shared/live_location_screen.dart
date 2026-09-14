import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────
// Provider that holds the application whose location is tracked
// ─────────────────────────────────────────────────────────────
final selectedApplicationForLocationProvider =
    StateProvider<ApplicationModel?>((ref) => null);

// ─────────────────────────────────────────────────────────────
// LiveLocationScreen
//
// Employer side — watches seeker's real-time GPS.
// Shown as a map-like coordinate display with a live update clock.
// (No Google Maps API key needed — uses pure Flutter rendering.)
// ─────────────────────────────────────────────────────────────

class LiveLocationScreen extends ConsumerStatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  ConsumerState<LiveLocationScreen> createState() =>
      _LiveLocationScreenState();
}

class _LiveLocationScreenState extends ConsumerState<LiveLocationScreen> {
  Timer? _clock;
  int _secondsAgo = 0;

  @override
  void initState() {
    super.initState();
    // Refresh "X seconds ago" label every second
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsAgo++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Waiting…';
    final secs = DateTime.now().difference(dt).inSeconds;
    if (secs < 5)  return 'Just now';
    if (secs < 60) return '${secs}s ago';
    final mins = (secs / 60).floor();
    if (mins < 60) return '${mins}m ago';
    return '${(mins / 60).floor()}h ago';
  }

  String _openMapsUrl(double lat, double lng) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(selectedApplicationForLocationProvider);

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Location')),
        body: const Center(child: Text('No application selected.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Location',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(app.seekerName,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.mute)),
          ],
        ),
      ),
      body: StreamBuilder<LiveLocation?>(
        stream:
            LocationService.instance.watchLiveLocation(app.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loc = snap.data;

          // ── Seeker hasn't started sharing yet ──────────────
          if (loc == null) {
            return _NoLocationYet(seekerName: app.seekerName);
          }

          // ── Seeker stopped sharing ──────────────────────────
          if (!loc.active) {
            return _LocationStopped(seekerName: app.seekerName);
          }

          // Reset counter when new position arrives
          if (snap.hasData) _secondsAgo = 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status banner ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Row(
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.seekerName} is sharing live location',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.teal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Updated ${_timeAgo(loc.updatedAt)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.teal),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Coordinate card ────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Simple visual map placeholder
                      _MapPin(lat: loc.lat, lng: loc.lng),
                      const SizedBox(height: 20),
                      _CoordRow(
                          label: 'Latitude',
                          value: loc.lat.toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _CoordRow(
                          label: 'Longitude',
                          value: loc.lng.toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _CoordRow(
                          label: 'Accuracy',
                          value: '±${loc.accuracy.toStringAsFixed(0)} m'),
                      const SizedBox(height: 8),
                      _CoordRow(
                          label: 'Last update',
                          value: loc.updatedAt != null
                              ? DateFormat('h:mm:ss a')
                                  .format(loc.updatedAt!)
                              : '—'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Open in Google Maps ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url = _openMapsUrl(loc.lat, loc.lng);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          'Open in browser: $url',
                          style: const TextStyle(fontSize: 11),
                        ),
                        duration: const Duration(seconds: 6),
                        action: SnackBarAction(
                          label: 'Copy',
                          onPressed: () {},
                        ),
                      ));
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Info card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warnBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.marigoldDark, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location updates automatically every few seconds '
                          'as the worker moves. The map link always shows '
                          'the latest position.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.marigoldDark,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SeekerLiveLocationScreen — seeker starts/stops sharing
// ─────────────────────────────────────────────────────────────

class SeekerLiveLocationScreen extends ConsumerStatefulWidget {
  const SeekerLiveLocationScreen({super.key});

  @override
  ConsumerState<SeekerLiveLocationScreen> createState() =>
      _SeekerLiveLocationScreenState();
}

class _SeekerLiveLocationScreenState
    extends ConsumerState<SeekerLiveLocationScreen> {
  bool _tracking = false;
  bool _loading  = false;
  String? _error;

  Future<void> _toggle(ApplicationModel app, String seekerId,
      String seekerName) async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_tracking) {
        await LocationService.instance.stopLiveTracking(app.id);
        setState(() => _tracking = false);
      } else {
        final started = await LocationService.instance.startLiveTracking(
          applicationId: app.id,
          seekerId:      seekerId,
          seekerName:    seekerName,
        );
        if (!started) {
          setState(() =>
              _error = 'Location permission denied. Please enable it in Settings.');
        } else {
          setState(() => _tracking = true);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // Don't stop tracking on dispose — seeker may background the app.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(selectedApplicationForLocationProvider);
    final userModel = ref.watch(userProvider).valueOrNull;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Location')),
        body: const Center(child: Text('No active job selected.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Share Live Location')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Icon(
              _tracking
                  ? Icons.location_on
                  : Icons.location_off_outlined,
              size: 72,
              color: _tracking ? AppColors.teal : AppColors.mute,
            ),
            const SizedBox(height: 16),
            Text(
              _tracking
                  ? 'Sharing live location…'
                  : 'Location sharing is OFF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _tracking ? AppColors.teal : AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tracking
                  ? 'Your employer can see your real-time position.'
                  : 'Tap below to share your location with your employer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.coral, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _toggle(
                          app,
                          app.seekerId,
                          userModel?.fullName ?? app.seekerName,
                        ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_tracking
                        ? Icons.location_off
                        : Icons.my_location),
                label: Text(
                  _loading
                      ? 'Please wait…'
                      : _tracking
                          ? 'Stop Sharing'
                          : 'Start Sharing Location',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _tracking ? AppColors.coral : AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.teal, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only your employer for this job can see your location. '
                      'Sharing stops the moment you tap "Stop Sharing".',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.teal,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────

class _NoLocationYet extends StatelessWidget {
  final String seekerName;
  const _NoLocationYet({required this.seekerName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_searching,
                size: 64, color: AppColors.mute),
            const SizedBox(height: 16),
            Text(
              '$seekerName hasn\'t started sharing yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask them to open the app and tap\n"Start Sharing Location".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mute, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStopped extends StatelessWidget {
  final String seekerName;
  const _LocationStopped({required this.seekerName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 64, color: AppColors.coral),
            const SizedBox(height: 16),
            Text(
              '$seekerName stopped sharing location.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will update automatically if they start sharing again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mute, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;
  const _CoordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.mute)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ],
    );
  }
}

/// A simple animated pulsing green dot — "live" indicator.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.teal.withAlpha((_anim.value * 255).toInt()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Simple visual map pin drawn with Canvas — no API key needed.
class _MapPin extends StatelessWidget {
  final double lat;
  final double lng;
  const _MapPin({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines
          CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _GridPainter(),
          ),
          // Pin icon
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_pin,
                    color: Colors.white, size: 28),
              ),
              Container(
                width: 2,
                height: 12,
                color: AppColors.teal,
              ),
              Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(80),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          // Coordinate overlay bottom-left
          Positioned(
            bottom: 8,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4)
                ],
              ),
              child: Text(
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withAlpha(25)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ignore: unused_element
double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;
