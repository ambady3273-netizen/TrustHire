import 'package:flutter/material.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────
// TrustRing
// Circular reliability score indicator used on job cards.
// ─────────────────────────────────────────────────────────────

class TrustRing extends StatelessWidget {
  final int    percent; // 0-100
  final double size;
  const TrustRing({super.key, required this.percent, this.size = 40});

  Color get _color {
    if (percent >= 70) return AppColors.teal;
    if (percent >= 40) return AppColors.marigoldDark;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width:  size,
            height: size,
            child: CircularProgressIndicator(
              value:            percent / 100,
              strokeWidth:      size * 0.12,
              backgroundColor:  AppColors.border,
              valueColor:       AlwaysStoppedAnimation(_color),
              strokeCap:        StrokeCap.round,
            ),
          ),
          Text(
            '$percent',
            style: TextStyle(
              fontSize:   size * 0.28,
              fontWeight: FontWeight.w800,
              color:      _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBadge
// ─────────────────────────────────────────────────────────────

enum BadgeType { verified, warn, danger, ink }

class AppBadge extends StatelessWidget {
  final String    text;
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
        bg = AppColors.ink.withAlpha(14);
        fg = AppColors.ink;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppCard — elevated white card with subtle shadow
// ─────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget  child;
  final Color?  borderColor;
  final double  borderWidth;
  final Color?  bg;
  const AppCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: borderColor ?? AppColors.border,
            width: borderWidth),
        boxShadow: bg == null
            ? [
                BoxShadow(
                  color:      const Color(0xFF1B2A4A).withAlpha(10),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GradientCard — card with gradient background
// ─────────────────────────────────────────────────────────────

class GradientCard extends StatelessWidget {
  final Widget            child;
  final LinearGradient    gradient;
  final EdgeInsets        padding;
  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        gradient:     gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      gradient.colors.first.withAlpha(60),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EscrowLockBar
// ─────────────────────────────────────────────────────────────

class EscrowLockBar extends StatelessWidget {
  final String amountLabel;
  final String status;
  const EscrowLockBar({
    super.key,
    required this.amountLabel,
    this.status = 'Active',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient:     AppColors.gradientInk,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escrow: $amountLabel held securely',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   12.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppColors.marigold.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(
                  color:      AppColors.marigold,
                  fontSize:   11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PrimaryButton
// ─────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String     label;
  final VoidCallback? onTap;
  final Color      color;
  final Color      textColor;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.color    = AppColors.ink,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation:       0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OutlineButton
// ─────────────────────────────────────────────────────────────

class OutlineButton extends StatelessWidget {
  final String     label;
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
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LabelSmall — section headers
// ─────────────────────────────────────────────────────────────

class LabelSmall extends StatelessWidget {
  final String text;
  const LabelSmall(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w800,
          color:         AppColors.mute,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FieldBox — read-only display field
// ─────────────────────────────────────────────────────────────

class FieldBox extends StatelessWidget {
  final String   text;
  final IconData? icon;
  final double?  height;
  const FieldBox(this.text, {super.key, this.icon, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: height != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.mute),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar — circular initials avatar with gradient
// ─────────────────────────────────────────────────────────────

class Avatar extends StatelessWidget {
  final double  size;
  final String? name;
  const Avatar({super.key, this.size = 34, this.name});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true)
        ? name![0].toUpperCase()
        : null;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape:    BoxShape.circle,
        gradient: initial != null
            ? null
            : const LinearGradient(
                colors: [AppColors.marigold, AppColors.coral]),
        color: initial != null ? AppColors.ink.withAlpha(18) : null,
      ),
      child: initial != null
          ? Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize:   size * 0.4,
                  fontWeight: FontWeight.w800,
                  color:      AppColors.ink,
                ),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SectionHeader — consistent section title style
// ─────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w800,
                    color:      AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mute),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// StatChip — small inline stat display
// ─────────────────────────────────────────────────────────────

class StatChip extends StatelessWidget {
  final String  value;
  final String  label;
  final Color   color;
  final IconData? icon;
  const StatChip({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
          ],
          Text(value,
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                  color:      color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.mute),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
