import 'package:crypted_app/app/widgets/custom_dvider.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:intl/intl.dart';

class EventMessageWidget extends StatelessWidget {
  final EventMessage eventMessage;
  final bool isMe;

  const EventMessageWidget({
    super.key,
    required this.eventMessage,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: Sizes.size280,
        width: Sizes.size250,
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.all(
            const Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeaderEventWidget(
              isMe: isMe,
              title: eventMessage.title ?? 'No Title',
            ),
            buildDivider(),
            buildEventDetailsWidget(
              description: eventMessage.description ?? '',
              eventDate: eventMessage.eventDate ?? DateTime.now(),
            ),
            buildDivider(),
            BuildFooterEventWidget(
              isMe: isMe,
              eventMessage: eventMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class buildEventDetailsWidget extends StatelessWidget {
  const buildEventDetailsWidget({
    super.key,
    required this.description,
    required this.eventDate,
  });
  final String description;
  final DateTime eventDate;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Paddings.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            _buildDetailRow(
              Iconsax.document_text_1_copy,
              Constants.kDescription.tr,
              description,
            ),
          ],
          const SizedBox(height: Sizes.size16),
          _buildDetailRow(
            Iconsax.calendar_1_copy,
            Constants.kDateTime.tr,
            _formatDate(eventDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: Sizes.size16,
          color: ColorsManager.primary,
        ),
        const SizedBox(width: Sizes.size8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: Sizes.size2),
              Text(
                value,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(date.year, date.month, date.day);

    String dateText;
    if (eventDay == today) {
      dateText = Constants.kToday.tr;
    } else if (eventDay == tomorrow) {
      dateText = Constants.kTomorrow.tr;
    } else {
      dateText = DateFormat('dd/MM/yyyy', 'ar').format(date);
    }

    // إضافة الوقت إذا كان الوقت مختلف عن 00:00
    if (date.hour != 0 || date.minute != 0) {
      final timeText = DateFormat('HH:mm', 'ar').format(date);
      return '$dateText \t \t \t \t _ \t \t \t \t $timeText';
    }

    return dateText;
  }
}

class buildHeaderEventWidget extends StatelessWidget {
  const buildHeaderEventWidget({
    super.key,
    required this.isMe,
    required this.title,
  });

  final bool isMe;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.large),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Radiuss.xLarge),
          topRight: Radius.circular(Radiuss.xLarge),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 0,
        leading: Padding(
          padding: const EdgeInsets.all(Paddings.xSmall),
          child: CircleAvatar(
            backgroundColor: ColorsManager.backgroundIconSetting,
            radius: Radiuss.xLarge22,
            child: SvgPicture.asset('assets/icons/fi_3861532.svg'),
          ),
        ),
        title: Text(
          Constants.kEvent.tr,
          style: StylesManager.medium(
              fontSize: FontSize.xSmall, color: Colors.black),
        ),
        subtitle: Text(
          title,
          style: StylesManager.bold(
            fontSize: FontSize.medium,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class BuildFooterEventWidget extends StatelessWidget {
  const BuildFooterEventWidget({
    super.key,
    required this.isMe,
    required this.eventMessage,
  });
  final bool isMe;
  final EventMessage eventMessage;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(Radiuss.xLarge),
          bottomRight: Radius.circular(Radiuss.xLarge),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.clock_copy,
                size: Sizes.size12,
                color: ColorsManager.primary,
              ),
              const SizedBox(width: Sizes.size4),
              Text(
                _formatMessageTime(eventMessage.timestamp),
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return Constants.kNow.tr;
    } else if (difference.inHours < 1) {
      return '${Constants.kAgo.tr} ${difference.inMinutes} ${Constants.kMinutes.tr}';
    } else if (difference.inDays < 1) {
      return '${Constants.kAgo.tr} ${difference.inHours} ${Constants.kHours.tr}';
    } else {
      return DateFormat('dd/MM HH:mm', 'ar').format(time);
    }
  }
}
