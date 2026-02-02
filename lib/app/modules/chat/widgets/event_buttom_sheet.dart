import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

class EventBottomSheet extends StatefulWidget {
  final ChatController controller;

  const EventBottomSheet({
    super.key,
    required this.controller,
  });

  @override
  State<EventBottomSheet> createState() => _EventBottomSheetState();
}

class _EventBottomSheetState extends State<EventBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool isAllDay = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: ColorsManager.surfaceAdaptive(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radiuss.xLarge),
            topRight: Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Paddings.xXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: Sizes.size20),
              _buildEventTitleField(),
              const SizedBox(height: Sizes.size20),
              _buildDescriptionField(),
              const SizedBox(height: Sizes.size20),
              _buildDateTimeSection(),
              const SizedBox(height: Sizes.size38),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Paddings.normal),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Radiuss.normal),
          ),
          child: Icon(
            Iconsax.calendar_add,
            color: ColorsManager.primary,
            size: Sizes.size24,
          ),
        ),
        const SizedBox(width: Sizes.size16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Constants.kCreateNewEvent.tr,
                style: StylesManager.bold(
                  fontSize: FontSize.large,
                  color: ColorsManager.textPrimaryAdaptive(context),
                ),
              ),
              const SizedBox(height: Sizes.size4),
              Text(
                Constants.kEventNameRequiredPlease.tr,
                style: StylesManager.regular(
                  fontSize: FontSize.small,
                  color: Colors.grey[600]!,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(Paddings.xSmall),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(Radiuss.xSmall),
            ),
            child: const Icon(
              Icons.close,
              size: Sizes.size20,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Constants.kEventName.tr,
          style: StylesManager.medium(
            fontSize: FontSize.medium,
            color: ColorsManager.textPrimaryAdaptive(context),
          ),
        ),
        const SizedBox(height: Sizes.size8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radiuss.normal),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: Constants.kEventNameExample.tr,
              hintStyle: StylesManager.regular(
                fontSize: FontSize.small,
                color: Colors.grey[500]!,
              ),
              prefixIcon: Icon(
                Iconsax.edit,
                color: ColorsManager.primary,
                size: Sizes.size20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: StylesManager.medium(
              fontSize: FontSize.medium,
              color: ColorsManager.textPrimaryAdaptive(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Constants.kDescription.tr,
          style: StylesManager.medium(
            fontSize: FontSize.medium,
            color: ColorsManager.textPrimaryAdaptive(context),
          ),
        ),
        const SizedBox(height: Sizes.size8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radiuss.normal),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: Constants.kAddDescription.tr,
              hintStyle: StylesManager.regular(
                fontSize: FontSize.small,
                color: Colors.grey[500]!,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: Paddings.xSmall),
                child: Icon(
                  Iconsax.document_text,
                  color: ColorsManager.primary,
                  size: FontSize.xLarge,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.textPrimaryAdaptive(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Constants.kDateTime.tr,
          style: StylesManager.medium(
            fontSize: FontSize.medium,
            color: ColorsManager.textPrimaryAdaptive(context),
          ),
        ),
        const SizedBox(height: Sizes.size12),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(),
            ),
            const SizedBox(width: Sizes.size12),
            if (!isAllDay)
              Expanded(
                child: _buildTimeSelector(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: ColorsManager.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != selectedDate) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radiuss.normal),
          border: Border.all(color: Colors.grey[300]!),
          color: ColorsManager.surfaceAdaptive(context),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.calendar_1,
              color: ColorsManager.primary,
              size: Sizes.size20,
            ),
            const SizedBox(width: Sizes.size12),
            Expanded(
              child: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.textPrimaryAdaptive(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: ColorsManager.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != selectedTime) {
          setState(() {
            selectedTime = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radiuss.normal),
          border: Border.all(color: Colors.grey[300]!),
          color: ColorsManager.surfaceAdaptive(context),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.clock,
              color: ColorsManager.primary,
              size: Sizes.size20,
            ),
            const SizedBox(width: Sizes.size12),
            Expanded(
              child: Text(
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.textPrimaryAdaptive(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Paddings.large),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radiuss.normal),
                border: Border.all(color: Colors.grey[300]!),
                color: ColorsManager.surfaceAdaptive(context),
              ),
              child: Text(
                Constants.kCancel.tr,
                textAlign: TextAlign.center,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: Colors.grey[600]!,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Sizes.size16),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _sendEvent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Paddings.large),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radiuss.normal),
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary,
                    ColorsManager.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorsManager.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.send_2,
                    color: Colors.white,
                    size: Sizes.size20,
                  ),
                  const SizedBox(width: Sizes.size8),
                  Text(
                    Constants.kSendEvent.tr,
                    style: StylesManager.bold(
                      fontSize: FontSize.medium,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _sendEvent() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        "",
        Constants.kEventNameRequiredPlease.tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
      return;
    }

    try {
      final DateTime eventDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        isAllDay ? 0 : selectedTime.hour,
        isAllDay ? 0 : selectedTime.minute,
      );

      final eventMessage = EventMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: widget.controller.roomId,
        senderId: UserService.currentUser.value?.uid ?? "",
        timestamp: DateTime.now(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        eventDate: eventDateTime,
      );

      await widget.controller.sendMessage(eventMessage);

      Get.back();
    } catch (e) {
      print(e.toString());
    }
  }
}
