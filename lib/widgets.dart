import 'package:flutter/material.dart';
import 'theme.dart';

/// The signature element of the app: a circular "Trust Ring" that shows a
/// verification/reliability score. Used identically on job cards, employer
/// cards, profiles, and chat headers so trust is legible at a glance.
class TrustRing extends StatelessWidget {
  final int percent; // 0-100
  final double size;
  const TrustRing({super.key, required this.percent, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: size * 0.12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
          Text(
            '$percent',
            style: TextStyle(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeType { verified, warn, danger, ink }

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  const AppBadge(this.text, {super.key, this.type = BadgeType.ink});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (type) {
      case BadgeType.verified:
        bg = AppColors.tealLight;
        fg = AppColors.teal;
        break;
      case BadgeType.warn:
        bg = AppColors.warnBg;
        fg = AppColors.marigoldDark;
        break;
      case BadgeType.danger:
        bg = AppColors.coralLight;
        fg = AppColors.coral;
        break;
      case BadgeType.ink:
        bg = AppColors.ink;
        fg = Colors.white;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final Color? bg;
  const AppCard({super.key, required this.child, this.borderColor, this.borderWidth = 1, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg ?? AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.border, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// The escrow "money is locked" banner used in chat and job-progress screens.
class EscrowLockBar extends StatelessWidget {
  final String amountLabel;
  final String status;
  const EscrowLockBar({super.key, required this.amountLabel, this.status = 'Active'});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Escrow: $amountLabel held',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          Text(status, style: const TextStyle(color: AppColors.marigold, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.ink,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const OutlineButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class LabelSmall extends StatelessWidget {
  final String text;
  const LabelSmall(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mute, letterSpacing: 0.5),
      ),
    );
  }
}

class FieldBox extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double? height;
  const FieldBox(this.text, {super.key, this.icon, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: height != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: AppColors.mute), const SizedBox(width: 6)],
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.text))),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final double size;
  const Avatar({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.marigold, AppColors.coral]),
      ),
    );
  }
}
