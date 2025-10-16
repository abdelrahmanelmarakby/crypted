import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class PollMessageWidget extends StatefulWidget {
  const PollMessageWidget({
    super.key,
    required this.message,
  });
  final PollMessage message;

  @override
  State<PollMessageWidget> createState() => _PollMessageWidgetState();
}

class _PollMessageWidgetState extends State<PollMessageWidget> {
  String? selectedOption;
  late List<int> votes;

  @override
  void initState() {
    super.initState();
    // مبدئيًا كل خيار عليه 0 تصويت
    votes = List.filled(widget.message.options.length, 0);
  }

  void handleVote(int index) {
    setState(() {
      // إذا كان نفس الخيار محدد بالفعل، قم بإلغاء التحديد
      if (selectedOption == widget.message.options[index]) {
        selectedOption = null;
        votes[index]--;
      } else {
        // إذا كان هناك خيار آخر محدد، قم بإلغاء التصويت عليه أولاً
        if (selectedOption != null) {
          final previousIndex = widget.message.options.indexOf(selectedOption!);
          if (previousIndex != -1) {
            votes[previousIndex]--;
          }
        }
        // ثم حدد الخيار الجديد
        selectedOption = widget.message.options[index];
        votes[index]++;
      }
    });
  }

  int get totalVotes => votes.fold(0, (a, b) => a + b);

  double getPercentage(int index) {
    final total = totalVotes;
    if (total == 0) return 0;
    return votes[index] / total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: MediaQuery.sizeOf(context).width * 0.68,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.question,
              style: StylesManager.regular(fontSize: FontSize.small),
            ),
            const SizedBox(height: Sizes.size4),
            Row(
              children: [
                SvgPicture.asset('assets/icons/Ico.svg'),
                const SizedBox(width: Sizes.size4),
                Text(
                  selectedOption != null
                      ? Constants.kChangeOption.tr
                      : Constants.kSelectOption.tr,
                  style: StylesManager.medium(
                    fontSize: FontSize.xSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.size20),
            ...List.generate(widget.message.options.length, (index) {
              final option = widget.message.options[index];
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => handleVote(index),
                    child: OptionTile(
                      label: option,
                      votes: votes[index],
                      percentage: getPercentage(index),
                      isSelected: selectedOption == option,
                    ),
                  ),
                  const SizedBox(height: Sizes.size16),
                ],
              );
            }),
            const Divider(color: ColorsManager.veryLightGrey),
            Align(
              alignment: Alignment.center,
              child: Text(
                Constants.kViewResults.tr,
                style: StylesManager.medium(
                  fontSize: FontSize.small,
                  color: ColorsManager.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final String label;
  final int votes;
  final double percentage;
  final bool isSelected;
  final String? voterImage;

  const OptionTile({
    super.key,
    required this.label,
    required this.votes,
    required this.percentage,
    required this.isSelected,
    this.voterImage,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ColorsManager.primary : ColorsManager.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
              size: Sizes.size20,
            ),
            SizedBox(width: Sizes.size4),
            Text(label, style: StylesManager.medium(fontSize: FontSize.small)),
            Spacer(),
            SizedBox(width: Sizes.size4),
            Text(votes.toString()),
          ],
        ),
        SizedBox(height: Sizes.size4),
        LinearProgressIndicator(
          borderRadius: BorderRadius.circular(Radiuss.xLarge),
          value: percentage,
          backgroundColor: ColorsManager.voiceProgressColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }
}
