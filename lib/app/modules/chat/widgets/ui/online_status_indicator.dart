import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/core/constants/chat_constants.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';

/// UI-001: Online Status Indicator
/// Displays real-time online status for users

class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final double size;
  final bool showBorder;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? ColorsManager.success : ColorsManager.grey,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: size / 6,
              )
            : null,
      ),
    );
  }
}

/// Live online status that updates from Firestore
class LiveOnlineStatus extends StatefulWidget {
  final String userId;
  final double size;
  final bool showLastSeen;
  final Widget Function(bool isOnline, DateTime? lastSeen)? builder;

  const LiveOnlineStatus({
    super.key,
    required this.userId,
    this.size = 12,
    this.showLastSeen = true,
    this.builder,
  });

  @override
  State<LiveOnlineStatus> createState() => _LiveOnlineStatusState();
}

class _LiveOnlineStatusState extends State<LiveOnlineStatus> {
  StreamSubscription? _subscription;
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  @override
  void didUpdateWidget(LiveOnlineStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _subscription?.cancel();
      _setupListener();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupListener() {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        final lastActive = data['lastActive'];

        DateTime? lastSeenTime;
        if (lastActive is Timestamp) {
          lastSeenTime = lastActive.toDate();
        } else if (lastActive is String) {
          lastSeenTime = DateTime.tryParse(lastActive);
        }

        // Consider online if active within threshold
        final isOnline = lastSeenTime != null &&
            DateTime.now().difference(lastSeenTime).inMinutes <
                ChatConstants.offlineThresholdMinutes;

        setState(() {
          _isOnline = isOnline;
          _lastSeen = lastSeenTime;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(_isOnline, _lastSeen);
    }

    return OnlineStatusIndicator(
      isOnline: _isOnline,
      lastSeen: _lastSeen,
      size: widget.size,
    );
  }
}

/// Online status text with last seen formatting
class OnlineStatusText extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final TextStyle? style;

  const OnlineStatusText({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _getStatusText(),
      style: style ??
          StylesManager.regular(
            fontSize: 13,
            color: isOnline ? ColorsManager.success : ColorsManager.grey,
          ),
    );
  }

  String _getStatusText() {
    if (isOnline) {
      return Constants.kOnline.tr;
    }

    if (lastSeen == null) {
      return Constants.kOffline.tr;
    }

    return _formatLastSeen(lastSeen!);
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} days ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}

/// Live online status with text
class LiveOnlineStatusText extends StatefulWidget {
  final String userId;
  final TextStyle? onlineStyle;
  final TextStyle? offlineStyle;

  const LiveOnlineStatusText({
    super.key,
    required this.userId,
    this.onlineStyle,
    this.offlineStyle,
  });

  @override
  State<LiveOnlineStatusText> createState() => _LiveOnlineStatusTextState();
}

class _LiveOnlineStatusTextState extends State<LiveOnlineStatusText> {
  StreamSubscription? _subscription;
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupListener() {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        final lastActive = data['lastActive'];

        DateTime? lastSeenTime;
        if (lastActive is Timestamp) {
          lastSeenTime = lastActive.toDate();
        }

        final isOnline = lastSeenTime != null &&
            DateTime.now().difference(lastSeenTime).inMinutes <
                ChatConstants.offlineThresholdMinutes;

        setState(() {
          _isOnline = isOnline;
          _lastSeen = lastSeenTime;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnlineStatusText(
      isOnline: _isOnline,
      lastSeen: _lastSeen,
      style: _isOnline ? widget.onlineStyle : widget.offlineStyle,
    );
  }
}

/// Combined status indicator with dot and text
class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnlineStatusIndicator(
          isOnline: isOnline,
          size: 8,
          showBorder: false,
        ),
        const SizedBox(width: 6),
        OnlineStatusText(
          isOnline: isOnline,
          lastSeen: lastSeen,
        ),
      ],
    );
  }
}

/// Avatar with online status overlay
class AvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final bool isOnline;
  final double size;
  final VoidCallback? onTap;

  const AvatarWithStatus({
    super.key,
    this.imageUrl,
    this.name,
    required this.isOnline,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorsManager.primary.withValues(alpha: 0.2),
              image: imageUrl != null && imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null || imageUrl!.isEmpty
                ? Center(
                    child: Text(
                      name?.substring(0, 1).toUpperCase() ?? '?',
                      style: StylesManager.bold(
                        fontSize: size * 0.4,
                        color: ColorsManager.primary,
                      ),
                    ),
                  )
                : null,
          ),

          // Online indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: OnlineStatusIndicator(
              isOnline: isOnline,
              size: size * 0.28,
            ),
          ),
        ],
      ),
    );
  }
}
