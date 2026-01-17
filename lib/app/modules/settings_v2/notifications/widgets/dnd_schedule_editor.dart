import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// DND Schedule Editor Widget
/// Allows creating and editing Do Not Disturb schedules
class DNDScheduleEditor extends StatefulWidget {
  final DNDSchedule? schedule;
  final Function(DNDSchedule) onSave;

  const DNDScheduleEditor({
    super.key,
    this.schedule,
    required this.onSave,
  });

  static Future<DNDSchedule?> show({
    required BuildContext context,
    DNDSchedule? schedule,
  }) async {
    DNDSchedule? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DNDScheduleEditor(
        schedule: schedule,
        onSave: (s) {
          result = s;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  @override
  State<DNDScheduleEditor> createState() => _DNDScheduleEditorState();
}

class _DNDScheduleEditorState extends State<DNDScheduleEditor> {
  late TextEditingController _nameController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _selectedDays;
  late bool _enabled;
  late bool _allowCalls;
  late bool _allowRepeatedCalls;

  bool get isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _nameController = TextEditingController(
      text: schedule?.name ?? 'Sleep',
    );
    _startTime = schedule?.startTime ?? const TimeOfDay(hour: 22, minute: 0);
    _endTime = schedule?.endTime ?? const TimeOfDay(hour: 7, minute: 0);
    _selectedDays = schedule?.daysOfWeek.toSet() ??
        {DateTime.monday, DateTime.tuesday, DateTime.wednesday,
         DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday};
    _enabled = schedule?.enabled ?? true;
    _allowCalls = schedule?.allowCalls ?? false;
    _allowRepeatedCalls = schedule?.allowRepeatedCalls ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a name for this schedule',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one day',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final schedule = DNDSchedule(
      id: widget.schedule?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      daysOfWeek: _selectedDays.toList()..sort(),
      enabled: _enabled,
      allowCalls: _allowCalls,
      allowRepeatedCalls: _allowRepeatedCalls,
    );

    widget.onSave(schedule);
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
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

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayName(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.do_not_disturb_on_rounded, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Schedule' : 'New Schedule',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    activeColor: ColorsManager.primary,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name input
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Schedule Name',
                        hintText: 'e.g., Sleep, Work, Weekend',
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Time selection
                    Text(
                      'Time Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerButton(
                            label: 'Start',
                            time: _startTime,
                            onTap: () => _selectTime(true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Expanded(
                          child: _TimePickerButton(
                            label: 'End',
                            time: _endTime,
                            onTap: () => _selectTime(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Days selection
                    Text(
                      'Repeat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DateTime.monday,
                        DateTime.tuesday,
                        DateTime.wednesday,
                        DateTime.thursday,
                        DateTime.friday,
                        DateTime.saturday,
                        DateTime.sunday,
                      ].map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(day);
                              } else {
                                _selectedDays.add(day);
                              }
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ColorsManager.primary
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getDayName(day)[0],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Quick selection buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickSelectChip(
                          label: 'Weekdays',
                          onTap: () {
                            setState(() {
                              _selectedDays = {
                                DateTime.monday,
                                DateTime.tuesday,
                                DateTime.wednesday,
                                DateTime.thursday,
                                DateTime.friday,
                              };
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickSelectChip(
                          label: 'Weekends',
                          onTap: () {
                            setState(() {
                              _selectedDays = {
                                DateTime.saturday,
                                DateTime.sunday,
                              };
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickSelectChip(
                          label: 'Every Day',
                          onTap: () {
                            setState(() {
                              _selectedDays = {
                                DateTime.monday,
                                DateTime.tuesday,
                                DateTime.wednesday,
                                DateTime.thursday,
                                DateTime.friday,
                                DateTime.saturday,
                                DateTime.sunday,
                              };
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Exceptions
                    Text(
                      'Exceptions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile.adaptive(
                      value: _allowCalls,
                      onChanged: (v) => setState(() => _allowCalls = v),
                      title: const Text('Allow Calls'),
                      subtitle: const Text('Let calls come through during DND'),
                      contentPadding: EdgeInsets.zero,
                      activeColor: ColorsManager.primary,
                    ),

                    SwitchListTile.adaptive(
                      value: _allowRepeatedCalls,
                      onChanged: _allowCalls ? null : (v) =>
                          setState(() => _allowRepeatedCalls = v),
                      title: const Text('Repeated Calls'),
                      subtitle: const Text(
                        'Allow if same person calls twice within 15 minutes',
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeColor: ColorsManager.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isEditing ? 'Save' : 'Create'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSelectChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// Quick DND Options Widget
/// Shows quick toggle options for DND duration
class QuickDNDOptions extends StatelessWidget {
  final bool isActive;
  final DateTime? activeUntil;
  final Function(bool enabled, Duration? duration) onToggle;

  const QuickDNDOptions({
    super.key,
    required this.isActive,
    this.activeUntil,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isActive) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_rounded, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Do Not Disturb is ON',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                      if (activeUntil != null)
                        Text(
                          'Until ${_formatDateTime(activeUntil!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onToggle(false, null),
                  child: const Text('Turn Off'),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Turn on for...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DurationChip(
                label: '30 min',
                onTap: () => onToggle(true, const Duration(minutes: 30)),
              ),
              _DurationChip(
                label: '1 hour',
                onTap: () => onToggle(true, const Duration(hours: 1)),
              ),
              _DurationChip(
                label: '2 hours',
                onTap: () => onToggle(true, const Duration(hours: 2)),
              ),
              _DurationChip(
                label: '8 hours',
                onTap: () => onToggle(true, const Duration(hours: 8)),
              ),
              _DurationChip(
                label: 'Until I turn off',
                onTap: () => onToggle(true, null),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year && dt.month == now.month && dt.day == now.day + 1;

    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return 'today at $time';
    } else if (isTomorrow) {
      return 'tomorrow at $time';
    } else {
      return '${dt.day}/${dt.month} at $time';
    }
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
