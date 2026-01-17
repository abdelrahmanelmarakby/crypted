import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Privacy shield icon indicator
/// Shows when content is protected or has restricted visibility
class PrivacyShieldIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String? tooltip;

  const PrivacyShieldIcon({
    super.key,
    this.size = 16,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.shield_outlined,
      size: size,
      color: color ?? Colors.grey.shade500,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: icon,
      );
    }

    return icon;
  }
}

/// Disappearing message timer indicator
class DisappearingMessageIndicator extends StatelessWidget {
  final DisappearingDuration duration;
  final double size;
  final bool compact;

  const DisappearingMessageIndicator({
    super.key,
    required this.duration,
    this.size = 16,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (duration == DisappearingDuration.off) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Icon(
        Icons.timer_outlined,
        size: size,
        color: ColorsManager.primary,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: size,
            color: ColorsManager.primary,
          ),
          const SizedBox(width: 4),
          Text(
            duration.displayName,
            style: TextStyle(
              color: ColorsManager.primary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// End-to-end encryption indicator
class E2EEncryptionIndicator extends StatelessWidget {
  final bool compact;
  final double iconSize;

  const E2EEncryptionIndicator({
    super.key,
    this.compact = false,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: 'End-to-end encrypted',
        child: Icon(
          Icons.lock_outline,
          size: iconSize,
          color: Colors.grey.shade500,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: iconSize,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'End-to-end encrypted',
            style: TextStyle(
              color: Colors.amber.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Privacy level indicator
class PrivacyLevelIndicator extends StatelessWidget {
  final VisibilityLevel level;
  final bool compact;
  final bool showLabel;

  const PrivacyLevelIndicator({
    super.key,
    required this.level,
    this.compact = false,
    this.showLabel = true,
  });

  Color get _color {
    switch (level) {
      case VisibilityLevel.everyone:
        return Colors.green;
      case VisibilityLevel.contacts:
      case VisibilityLevel.contactsExcept:
        return Colors.blue;
      case VisibilityLevel.nobody:
      case VisibilityLevel.nobodyExcept:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (level) {
      case VisibilityLevel.everyone:
        return Icons.public;
      case VisibilityLevel.contacts:
      case VisibilityLevel.contactsExcept:
        return Icons.people;
      case VisibilityLevel.nobody:
      case VisibilityLevel.nobodyExcept:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Icon(
        _icon,
        size: 16,
        color: _color.withValues(alpha: 0.7),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 14,
            color: _color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              level.displayName,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Read receipts off indicator
class ReadReceiptsOffIndicator extends StatelessWidget {
  final double size;

  const ReadReceiptsOffIndicator({
    super.key,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Read receipts are off',
      child: Icon(
        Icons.done_all,
        size: size,
        color: Colors.grey.shade400,
      ),
    );
  }
}

/// Screenshot protection indicator
class ScreenshotProtectionBanner extends StatelessWidget {
  final bool isProtected;

  const ScreenshotProtectionBanner({
    super.key,
    this.isProtected = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProtected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.purple.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screenshot_outlined,
            size: 16,
            color: Colors.purple.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Screenshots are blocked in this chat',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Forwarding restricted indicator on messages
class ForwardingRestrictedIndicator extends StatelessWidget {
  final bool compact;

  const ForwardingRestrictedIndicator({
    super.key,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: 'Forwarding is disabled',
        child: Icon(
          Icons.forward_to_inbox,
          size: 14,
          color: Colors.grey.shade400,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward_to_inbox,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            'No forwarding',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Privacy score indicator (circular progress)
class PrivacyScoreIndicator extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const PrivacyScoreIndicator({
    super.key,
    required this.score,
    this.size = 48,
    this.showLabel = true,
  });

  Color get _color {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Locked chat indicator
class LockedChatIndicator extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const LockedChatIndicator({
    super.key,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock,
            size: 14,
            color: ColorsManager.primary,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ColorsManager.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: ColorsManager.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Locked',
              style: TextStyle(
                color: ColorsManager.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Privacy status row (for profile/settings)
class PrivacyStatusRow extends StatelessWidget {
  final String label;
  final VisibilityLevel level;
  final VoidCallback? onTap;

  const PrivacyStatusRow({
    super.key,
    required this.label,
    required this.level,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            PrivacyLevelIndicator(level: level),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
