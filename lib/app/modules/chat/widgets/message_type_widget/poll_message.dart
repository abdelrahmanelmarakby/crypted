import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
  final ChatDataSources _chatDataSources = ChatDataSources();
  bool _isVoting = false;

  Future<void> handleVote(int index) async {
    final userId = UserService.currentUserValue?.uid;
    if (userId == null) {
      Get.snackbar(
        'Error',
        'Please login to vote',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: Colors.white,
      );
      return;
    }

    // Check if poll is closed
    if (widget.message.isClosed) {
      Get.snackbar(
        'Poll Closed',
        'This poll has ended',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: Colors.white,
        icon: Icon(Iconsax.info_circle_copy, color: Colors.white),
      );
      return;
    }

    if (_isVoting) return; // Prevent duplicate votes

    setState(() {
      _isVoting = true;
    });

    try {
      await _chatDataSources.votePoll(
        roomId: widget.message.roomId,
        messageId: widget.message.id,
        optionIndex: index,
        userId: userId,
        allowMultipleVotes: widget.message.allowMultipleVotes,
      );
      // State will update automatically via the message stream
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record vote: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = UserService.currentUserValue?.uid ?? '';
    final userVote = widget.message.getUserVote(userId);
    final totalVotes = widget.message.totalVotes;
    final isClosed = widget.message.isClosed;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        minWidth: MediaQuery.sizeOf(context).width * 0.65,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClosed
              ? ColorsManager.grey.withValues(alpha: 0.3)
              : ColorsManager.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poll Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isClosed ? ColorsManager.grey : ColorsManager.primary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isClosed ? Iconsax.archive_minus_copy : Iconsax.chart_copy,
                    color:
                        isClosed ? ColorsManager.grey : ColorsManager.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isClosed ? 'Poll (Closed)' : 'Poll',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color:
                          isClosed ? ColorsManager.grey : ColorsManager.primary,
                    ),
                  ),
                ),
                if (totalVotes > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorsManager.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.people_copy,
                          size: 14,
                          color: ColorsManager.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                          style: StylesManager.semiBold(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Question
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.message_question_copy,
                    size: 18,
                    color: ColorsManager.textPrimaryAdaptive(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message.question,
                      style: StylesManager.medium(
                        fontSize: FontSize.medium,
                        color: ColorsManager.textPrimaryAdaptive(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Selection hint
            Row(
              children: [
                Icon(
                  userVote != null
                      ? Iconsax.tick_circle_copy
                      : (isClosed
                          ? Iconsax.lock_copy
                          : Iconsax.information_copy),
                  size: 16,
                  color: userVote != null
                      ? ColorsManager.success
                      : (isClosed ? ColorsManager.grey : ColorsManager.grey),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isClosed
                        ? 'Poll has ended'
                        : (userVote != null
                            ? Constants.kChangeOption.tr
                            : Constants.kSelectOption.tr),
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: userVote != null
                          ? ColorsManager.success
                          : (isClosed
                              ? ColorsManager.grey
                              : ColorsManager.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            ...List.generate(widget.message.options.length, (index) {
              final option = widget.message.options[index];
              final voteCount = widget.message.getVoteCount(index);
              final percentage = widget.message.getVotePercentage(index);
              final isSelected = userVote == option;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: isClosed || _isVoting ? null : () => handleVote(index),
                  child: Opacity(
                    opacity: (isClosed || _isVoting) ? 0.6 : 1.0,
                    child: OptionTile(
                      label: option,
                      votes: voteCount,
                      percentage: percentage,
                      isSelected: isSelected,
                      optionIndex: index + 1,
                      totalOptions: widget.message.options.length,
                      isDisabled: isClosed || _isVoting,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // View Results Button
            InkWell(
              onTap: () => _showDetailedResults(context, widget.message),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: ColorsManager.dividerAdaptive(context),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.chart_1_copy,
                      size: 16,
                      color: ColorsManager.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Constants.kViewResults.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.small,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedResults(BuildContext context, PollMessage message) {
    final totalVotes = message.totalVotes;
    final userId = UserService.currentUserValue?.uid ?? '';

    Get.bottomSheet(
      Builder(
        builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.surfaceAdaptive(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorsManager.dividerAdaptive(context),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.chart_copy,
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
                          'Poll Results',
                          style: StylesManager.bold(
                            fontSize: FontSize.large,
                            color: ColorsManager.textPrimaryAdaptive(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.question,
                          style: StylesManager.regular(
                            fontSize: FontSize.small,
                            color: ColorsManager.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: ColorsManager.grey),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Poll Statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Iconsax.people_copy,
                    label: 'Total Votes',
                    value: '$totalVotes',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: ColorsManager.dividerAdaptive(context),
                  ),
                  _buildStatItem(
                    icon: Iconsax.chart_1_copy,
                    label: 'Options',
                    value: '${message.options.length}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: ColorsManager.dividerAdaptive(context),
                  ),
                  _buildStatItem(
                    icon: message.isClosed
                        ? Iconsax.lock_copy
                        : Iconsax.tick_circle_copy,
                    label: 'Status',
                    value: message.isClosed ? 'Closed' : 'Active',
                    valueColor: message.isClosed
                        ? ColorsManager.error
                        : ColorsManager.success,
                  ),
                ],
              ),
            ),

            // Options Results
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemCount: message.options.length,
                itemBuilder: (context, index) {
                  final option = message.options[index];
                  final votes = message.votes[index] ?? [];
                  final voteCount = votes.length;
                  final percentage = totalVotes > 0
                      ? (voteCount / totalVotes * 100).toStringAsFixed(1)
                      : '0.0';
                  final userVoted = votes.contains(userId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: userVoted
                          ? ColorsManager.primary.withValues(alpha: 0.1)
                          : ColorsManager.surfaceAdaptive(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: userVoted
                            ? ColorsManager.primary
                            : ColorsManager.dividerAdaptive(context),
                        width: userVoted ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Option title and vote count
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: StylesManager.semiBold(
                                  fontSize: FontSize.medium,
                                  color: ColorsManager.textPrimaryAdaptive(context),
                                ),
                              ),
                            ),
                            if (userVoted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorsManager.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.tick_circle_copy,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Your Vote',
                                      style: StylesManager.semiBold(
                                        fontSize: FontSize.xSmall,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalVotes > 0 ? voteCount / totalVotes : 0,
                            backgroundColor: ColorsManager.navbarColor
                                .withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              userVoted
                                  ? ColorsManager.primary
                                  : ColorsManager.grey,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.people_copy,
                                  size: 16,
                                  color: ColorsManager.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$voteCount ${voteCount == 1 ? "vote" : "votes"}',
                                  style: StylesManager.regular(
                                    fontSize: FontSize.small,
                                    color: ColorsManager.grey,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$percentage%',
                              style: StylesManager.bold(
                                fontSize: FontSize.medium,
                                color: userVoted
                                    ? ColorsManager.primary
                                    : ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer with poll info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ColorsManager.navbarColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle_copy,
                    size: 16,
                    color: ColorsManager.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.allowMultipleVotes
                          ? 'Multiple votes allowed'
                          : 'Single vote only',
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: ColorsManager.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: StylesManager.bold(
            fontSize: FontSize.large,
            color: valueColor ?? ColorsManager.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: StylesManager.regular(
            fontSize: FontSize.xSmall,
            color: ColorsManager.grey,
          ),
        ),
      ],
    );
  }
}

class OptionTile extends StatelessWidget {
  final String label;
  final int votes;
  final double percentage;
  final bool isSelected;
  final int optionIndex;
  final int totalOptions;
  final bool isDisabled;
  final String? voterImage;

  const OptionTile({
    super.key,
    required this.label,
    required this.votes,
    required this.percentage,
    required this.isSelected,
    required this.optionIndex,
    required this.totalOptions,
    this.isDisabled = false,
    this.voterImage,
  });

  Color _getOptionColor() {
    if (isSelected) return ColorsManager.primary;

    // Assign different colors to each option for visual distinction
    final colors = [
      ColorsManager.primary,
      ColorsManager.success,
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFFFB84D), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
    ];

    return colors[(optionIndex - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getOptionColor();
    final percentageText = (percentage * 100).toStringAsFixed(0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : ColorsManager.navbarColor,
          width: isSelected ? 2 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option header with checkbox and label
          Row(
            children: [
              // Animated checkbox/radio
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : ColorsManager.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Option label
              Expanded(
                child: Text(
                  label,
                  style: StylesManager.medium(
                    fontSize: FontSize.small,
                    color: isSelected ? color : ColorsManager.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Vote count badge
              if (votes > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.user_copy,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        votes.toString(),
                        style: StylesManager.semiBold(
                          fontSize: FontSize.xSmall,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar with percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: percentage),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: ColorsManager.navbarColor,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Percentage text
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                child: Text(
                  '$percentageText%',
                  style: StylesManager.semiBold(
                    fontSize: FontSize.small,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
