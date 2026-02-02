import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';

/// Shared Settings UI Widgets
/// Provides consistent, reusable components for settings screens

// ============================================================================
// SETTINGS SECTION
// ============================================================================

/// Section container with header
class SettingsSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const SettingsSection({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: Paddings.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: Paddings.small,
                bottom: Paddings.xSmall,
              ),
              child: Text(
                title!.toUpperCase(),
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: ColorsManager.surfaceAdaptive(context),
              borderRadius: BorderRadius.circular(Radiuss.medium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radiuss.medium),
              child: Column(
                children: _buildChildrenWithDividers(),
              ),
            ),
          ),
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: Paddings.small,
                top: Paddings.xSmall,
              ),
              child: Text(
                subtitle!,
                style: StylesManager.regular(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(Divider(
          height: 1,
          thickness: 0.5,
          color: ColorsManager.lightGrey.withOpacity(0.5),
          indent: 56,
        ));
      }
    }
    return result;
  }
}

// ============================================================================
// SETTINGS TILE
// ============================================================================

/// Standard settings tile with icon, title, and optional trailing widget
class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Paddings.normal,
            vertical: Paddings.medium,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ??
                        (iconColor ?? ColorsManager.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? ColorsManager.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Sizes.size12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StylesManager.regular(
                        fontSize: FontSize.medium,
                        color: enabled
                            ? ColorsManager.textPrimaryAdaptive(context)
                            : ColorsManager.grey,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: StylesManager.regular(
                          fontSize: FontSize.xSmall,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && showChevron && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: ColorsManager.grey.withOpacity(0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SETTINGS SWITCH
// ============================================================================

/// Settings tile with switch
class SettingsSwitch extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const SettingsSwitch({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      showChevron: false,
      trailing: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: ColorsManager.primary,
      ),
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}

/// Reactive settings switch that works with Rx<bool>
class ReactiveSettingsSwitch extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final RxBool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const ReactiveSettingsSwitch({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => SettingsSwitch(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          value: value.value,
          onChanged: onChanged,
          enabled: enabled,
        ));
  }
}

// ============================================================================
// SETTINGS DROPDOWN
// ============================================================================

/// Settings tile with dropdown value display
class SettingsDropdown<T> extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final T value;
  final List<DropdownOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  const SettingsDropdown({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentOption = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );

    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentOption.label,
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: ColorsManager.grey.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
      onTap: enabled ? () => _showOptionsPicker(context) : null,
    );
  }

  void _showOptionsPicker(BuildContext context) {
    Get.bottomSheet(
      Builder(
          builder: (ctx) => Container(
                decoration: BoxDecoration(
                  color: ColorsManager.surfaceAdaptive(ctx),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHandle(),
                      Padding(
                        padding: const EdgeInsets.all(Paddings.large),
                        child: Text(
                          title,
                          style:
                              StylesManager.semiBold(fontSize: FontSize.large),
                        ),
                      ),
                      const Divider(height: 1),
                      ...options.map((option) => _buildOption(option)),
                      const SizedBox(height: Paddings.large),
                    ],
                  ),
                ),
              )),
      isScrollControlled: true,
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildOption(DropdownOption<T> option) {
    final isSelected = option.value == value;
    return InkWell(
      onTap: () {
        Get.back();
        onChanged?.call(option.value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.medium,
        ),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                color: isSelected ? ColorsManager.primary : ColorsManager.grey,
                size: 24,
              ),
              const SizedBox(width: Sizes.size12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color:
                          isSelected ? ColorsManager.primary : Colors.black87,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: StylesManager.regular(
                        fontSize: FontSize.xSmall,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorsManager.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown option model
class DropdownOption<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;

  const DropdownOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });
}

// ============================================================================
// SETTINGS HEADER
// ============================================================================

/// Large header for settings sections
class SettingsHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const SettingsHeader({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Paddings.large),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (iconColor ?? ColorsManager.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor ?? ColorsManager.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: Sizes.size16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.bold(fontSize: FontSize.xLarge),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ============================================================================
// SCORE CARD
// ============================================================================

/// Privacy/Security score card
class ScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final String? actionLabel;

  const ScoreCard({
    super.key,
    required this.score,
    required this.label,
    this.color,
    this.onTap,
    this.actionLabel,
  });

  Color get _scoreColor {
    if (color != null) return color!;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Paddings.large),
      padding: const EdgeInsets.all(Paddings.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor.withOpacity(0.1),
            _scoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scoreColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                ),
                Text(
                  '$score',
                  style: StylesManager.bold(
                    fontSize: FontSize.xLarge,
                    color: _scoreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sizes.size16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.large,
                    color: _scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreDescription(),
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel ?? 'Check',
                style: StylesManager.semiBold(
                  fontSize: FontSize.small,
                  color: _scoreColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getScoreDescription() {
    if (score >= 80) return 'Your settings are well configured';
    if (score >= 60) return 'Some settings could be improved';
    return 'Review your settings for better protection';
  }
}

// ============================================================================
// LOADING OVERLAY
// ============================================================================

/// Loading overlay for async operations
class SettingsLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const SettingsLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(Paddings.large),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    if (message != null) ...[
                      const SizedBox(height: Sizes.size16),
                      Text(
                        message!,
                        style: StylesManager.regular(fontSize: FontSize.medium),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

/// Empty state widget for lists
class SettingsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SettingsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Paddings.xLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: ColorsManager.grey.withOpacity(0.5),
          ),
          const SizedBox(height: Sizes.size16),
          Text(
            title,
            style: StylesManager.semiBold(
              fontSize: FontSize.large,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: Sizes.size8),
            Text(
              subtitle!,
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Sizes.size24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
