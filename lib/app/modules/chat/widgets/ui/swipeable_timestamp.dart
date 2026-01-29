import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';

/// Swipeable wrapper that reveals full timestamp on horizontal drag
///
/// **Behavior:**
/// - Swipe left to reveal timestamp (for sent messages on right)
/// - Swipe right to reveal timestamp (for received messages on left)
/// - Elastic snap-back animation when released
/// - Haptic feedback at reveal threshold
class SwipeableTimestamp extends StatefulWidget {
  final Widget child;
  final DateTime timestamp;
  final bool isMe;
  final double maxOffset;

  const SwipeableTimestamp({
    super.key,
    required this.child,
    required this.timestamp,
    required this.isMe,
    this.maxOffset = 80,
  });

  @override
  State<SwipeableTimestamp> createState() => _SwipeableTimestampState();
}

class _SwipeableTimestampState extends State<SwipeableTimestamp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _dragOffset = 0;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // For sent messages (right side), swipe left reveals timestamp
      // For received messages (left side), swipe right reveals timestamp
      if (widget.isMe) {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(-widget.maxOffset, 0);
      } else {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(0, widget.maxOffset);
      }

      // Haptic feedback at threshold
      final threshold = widget.maxOffset * 0.5;
      if (_dragOffset.abs() >= threshold && !_hasTriggeredHaptic) {
        HapticFeedback.selectionClick();
        _hasTriggeredHaptic = true;
      } else if (_dragOffset.abs() < threshold) {
        _hasTriggeredHaptic = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Animate back to original position
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward(from: 0);

    _animation.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  String _formatFullTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    String dateStr;
    if (messageDate == today) {
      dateStr = 'Today';
    } else if (messageDate == yesterday) {
      dateStr = 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      dateStr = _weekdayName(timestamp.weekday);
    } else {
      dateStr = '${_monthName(timestamp.month)} ${timestamp.day}';
      if (timestamp.year != now.year) {
        dateStr += ', ${timestamp.year}';
      }
    }

    final hour = timestamp.hour == 0
        ? 12
        : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:${timestamp.minute.toString().padLeft(2, '0')} $amPm';

    return '$dateStr, $timeStr';
  }

  String _weekdayName(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday];
  }

  String _monthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / widget.maxOffset).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // Timestamp revealed behind message
          Positioned(
            left: widget.isMe ? null : 8,
            right: widget.isMe ? 8 : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: progress,
              child: Transform.scale(
                scale: 0.8 + (0.2 * progress),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorsManager.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatFullTimestamp(widget.timestamp),
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Message content (slides to reveal timestamp)
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
