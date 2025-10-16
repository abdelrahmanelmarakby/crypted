import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PollBottomSheet extends StatefulWidget {
  final ChatController controller;

  const PollBottomSheet({super.key, required this.controller});

  @override
  State<PollBottomSheet> createState() => _PollBottomSheetState();
}

class _PollBottomSheetState extends State<PollBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (optionControllers.length < 6) {
      setState(() {
        optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (optionControllers.length > 2) {
      setState(() {
        optionControllers[index].dispose();
        optionControllers.removeAt(index);
      });
    }
  }

  void _sendPoll() async {
    if (questionController.text.trim().isEmpty) {
      Get.snackbar(
        "",
        Constants.kEnterPollQuestion.tr,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    List<String> options = optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      Get.snackbar(
        "",
        Constants.kAtLeastTwoOptions.tr,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    try {
      final pollMessage = PollMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: ChatDataSources.getRoomId(
          widget.controller.sender?.uid ?? "",
          widget.controller.receiver?.uid ?? "",
        ),
        senderId: widget.controller.sender?.uid ?? "",
        timestamp: DateTime.now(),
        question: questionController.text.trim(),
        options: options,
      );

      await widget.controller.sendMessage(pollMessage);

      Get.back();
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Paddings.large,
                        vertical: Paddings.normal,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorsManager.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.chart_21,
                              color: ColorsManager.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Constants.kCreatePoll.tr,
                                  style: StylesManager.bold(
                                    fontSize: FontSize.large,
                                    color: ColorsManager.black,
                                  ),
                                ),
                                Text(
                                  Constants.kPollSubtitle.tr,
                                  style: StylesManager.regular(
                                    fontSize: FontSize.small,
                                    color: ColorsManager.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(
                              Icons.close,
                              color: ColorsManager.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Paddings.large),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question Section
                            Text(
                              Constants.kQuestion.tr,
                              style: StylesManager.semiBold(
                                fontSize: FontSize.medium,
                                color: ColorsManager.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                controller: questionController,
                                hint: Constants.kWhatIsYourQuestion.tr,
                                maxLines: 3,
                                fillColor: const Color(0xFFf8f9fa),
                                borderRadius: 16,
                                textColor: ColorsManager.black,
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsManager.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Iconsax.message_question,
                                    color: ColorsManager.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Options Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Constants.kOptions.tr,
                                  style: StylesManager.semiBold(
                                    fontSize: FontSize.medium,
                                    color: ColorsManager.black,
                                  ),
                                ),
                                Text(
                                  "${optionControllers.length}/6",
                                  style: StylesManager.regular(
                                    fontSize: FontSize.small,
                                    color: ColorsManager.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Options List
                            ...optionControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              TextEditingController controller = entry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CustomTextField(
                                  controller: controller,
                                  hint: "${Constants.kOptions.tr} ${index + 1}",
                                  fillColor: const Color(0xFFf8f9fa),
                                  borderRadius: 16,
                                  textColor: ColorsManager.black,
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: ColorsManager.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: StylesManager.bold(
                                        fontSize: FontSize.small,
                                        color: ColorsManager.primary,
                                      ),
                                    ),
                                  ),
                                  suffixIcon: optionControllers.length > 2
                                      ? IconButton(
                                          onPressed: () => _removeOption(index),
                                          icon: Icon(
                                            Iconsax.trash,
                                            color: Colors.red[400],
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }),

                            // Add Option Button
                            if (optionControllers.length < 6)
                              GestureDetector(
                                onTap: _addOption,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: ColorsManager.primary
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    color:
                                        ColorsManager.primary.withOpacity(0.05),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.add_circle,
                                        color: ColorsManager.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        Constants.kAddNewOption.tr,
                                        style: StylesManager.medium(
                                          fontSize: FontSize.medium,
                                          color: ColorsManager.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Buttons
                    Container(
                      padding: const EdgeInsets.all(Paddings.large),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              child: Text(
                                Constants.kCancel.tr,
                                style: StylesManager.medium(
                                  fontSize: FontSize.medium,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _sendPoll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorsManager.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.send_2,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Constants.kSubmitPoll.tr,
                                    style: StylesManager.medium(
                                      fontSize: FontSize.medium,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
