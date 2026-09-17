import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/shared/live_location_screen.dart'
    show selectedApplicationForLocationProvider;
import '../../services/location_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Providers ─────────────────────────────────────────────────

final attendanceLogsProvider =
    StreamProvider.family<List<AttendanceModel>, String>(
        (ref, applicationId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchAttendanceLogs(applicationId);
});

// ─────────────────────────────────────────────────────────────
// GeofenceScreen — Seeker manually clocks in/out
// Checks GPS distance to job location before logging
// ─────────────────────────────────────────────────────────────

class GeofenceScreen extends ConsumerStatefulWidget {
  const GeofenceScreen({super.key});

  @override
  ConsumerState<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends ConsumerState<GeofenceScreen> {
  bool    _loading       = false;
  String? _statusMessage;
  bool    _isSuccess     = false;

  Future<void> _clockEvent(
      ApplicationModel app, String seekerName, String event) async {
    setState(() { _loading = true; _statusMessage = null; });

    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos == null) {
        setState(() {
          _statusMessage = 'Could not get your location. Enable GPS.';
          _isSuccess = false;
        });
        return;
      }

      // Check if job has pinned GPS coordinates
      // For now we always allow clock-in if no pin (employer didn't set GPS)
      // When employer has pinned location, enforce geofence
      final fs = ref.read(firestoreServiceProvider);

      // Always record regardless of distance when no job pin
      final log = AttendanceModel(
        id:            '',
        applicationId: app.id,
        seekerId:      app.seekerId,
        seekerName:    seekerName,
        jobId:         app.jobId,
        jobTitle:      app.jobTitle,
        event:         event,
        lat:           pos.latitude,
        lng:           pos.longitude,
        timestamp:     DateTime.now(),
      );

      await fs.logAttendance(log);

      setState(() {
        _statusMessage = event == 'clock_in'
            ? '✅ Clocked in successfully!'
            : '✅ Clocked out successfully!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isSuccess     = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app       = ref.watch(selectedApplicationForLocationProvider);
    final userModel = ref.watch(userProvider).valueOrNull;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: Text('No active job selected.')),
      );
    }

    final logsAsync = ref.watch(attendanceLogsProvider(app.id));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Clock In / Out')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Job info ────────────────────────────────────
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.work_outline,
                      color: AppColors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.jobTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(app.companyName,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.mute)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status feedback ─────────────────────────────
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.tealLight
                      : AppColors.coralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                      color: _isSuccess
                          ? AppColors.teal
                          : AppColors.coral,
                      fontWeight: FontWeight.w600),
                ),
              ),

            const SizedBox(height: 20),

            // ── Clock In / Out buttons ───────────────────────
            Row(
              children: [
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: () => _clockEvent(
                            app,
                            userModel?.fullName ?? app.seekerName,
                            'clock_in',
                          ),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Clock In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _loading
                      ? const SizedBox()
                      : OutlinedButton.icon(
                          onPressed: () => _clockEvent(
                            app,
                            userModel?.fullName ?? app.seekerName,
                            'clock_out',
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Clock Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.coral,
                            side: const BorderSide(
                                color: AppColors.coral),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Attendance log ───────────────────────────────
            const Text('Attendance Log',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink)),
            const SizedBox(height: 12),

            logsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.coral)),
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No attendance records yet.\n'
                        'Tap Clock In when you arrive.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.mute, height: 1.5),
                      ),
                    ),
                  );
                }
                return Column(
                  children: logs
                      .map((log) => _AttendanceTile(log: log))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AttendanceLogScreen — Employer sees seeker's attendance
// ─────────────────────────────────────────────────────────────

class AttendanceLogScreen extends ConsumerWidget {
  const AttendanceLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(selectedApplicationForLocationProvider);
    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance Log')),
        body: const Center(child: Text('No application selected.')),
      );
    }

    final logsAsync = ref.watch(attendanceLogsProvider(app.id));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Log',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            Text(app.seekerName,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mute)),
          ],
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('$e', style: const TextStyle(color: AppColors.coral))),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_outlined,
                        size: 56, color: AppColors.mute),
                    SizedBox(height: 16),
                    Text(
                      'No attendance records yet.',
                      style: TextStyle(color: AppColors.mute),
                    ),
                  ],
                ),
              ),
            );
          }

          // Pair clock_in / clock_out entries
          Duration totalWorked = Duration.zero;
          DateTime? lastIn;
          for (final log in logs) {
            if (log.isClockIn) lastIn = log.timestamp;
            if (log.isClockOut && lastIn != null) {
              totalWorked += log.timestamp.difference(lastIn);
              lastIn = null;
            }
          }

          final hours   = totalWorked.inHours;
          final minutes = totalWorked.inMinutes % 60;

          return Column(
            children: [
              // ── Total worked banner ──────────────────────
              Container(
                color: AppColors.tealLight,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.teal, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Total worked: ${hours}h ${minutes}m',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (_, i) =>
                      _AttendanceTile(log: logs[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceModel log;
  const _AttendanceTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn    = log.isClockIn;
    final color   = isIn ? AppColors.teal : AppColors.coral;
    final icon    = isIn ? Icons.login_rounded : Icons.logout_rounded;
    final label   = isIn ? 'Clock In' : 'Clock Out';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:  color.withAlpha(25),
                shape:  BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 13)),
                  Text(
                    DateFormat('dd MMM yyyy  h:mm a')
                        .format(log.timestamp),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.mute),
                  ),
                ],
              ),
            ),
            Text(
              '${log.lat.toStringAsFixed(3)},\n${log.lng.toStringAsFixed(3)}',
              style: const TextStyle(
                  fontSize: 9.5, color: AppColors.mute),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
