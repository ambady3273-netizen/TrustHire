import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/application_model.dart';
import '../providers/applications_provider.dart';
import '../theme.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('My Applications')),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load applications.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute)),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                        color: AppColors.tealLight, shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 30, color: AppColors.teal),
                  ),
                  const SizedBox(height: 16),
                  const Text('No applications yet',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  const Text('Browse jobs and tap "Apply now" to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.mute)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: apps.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) => _ApplicationTile(app: apps[i]),
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final ApplicationModel app;
  const _ApplicationTile({required this.app});

  Color _statusColor(String s) {
    switch (s) {
      case ApplicationStatus.accepted:
      case ApplicationStatus.completed:
        return AppColors.teal;
      case ApplicationStatus.shortlisted:
        return AppColors.marigoldDark;
      case ApplicationStatus.rejected:
      case ApplicationStatus.cancelled:
        return AppColors.coral;
      case ApplicationStatus.withdrawn:
        return AppColors.mute;
      default:
        return AppColors.ink;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case ApplicationStatus.accepted:
      case ApplicationStatus.completed:
        return Icons.verified_rounded;
      case ApplicationStatus.shortlisted:
        return Icons.star_rounded;
      case ApplicationStatus.rejected:
      case ApplicationStatus.cancelled:
        return Icons.cancel_rounded;
      case ApplicationStatus.withdrawn:
        return Icons.undo_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(app.status);
    final icon = _statusIcon(app.status);
    final label = ApplicationStatus.label(app.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.jobTitle,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(app.companyName,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.mute)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.mute),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
