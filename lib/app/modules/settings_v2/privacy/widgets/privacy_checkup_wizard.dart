import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/privacy/controllers/privacy_settings_controller.dart';

/// Privacy Checkup Wizard
/// Guides users through reviewing and improving their privacy settings
class PrivacyCheckupWizard extends StatefulWidget {
  const PrivacyCheckupWizard({super.key});

  /// Show the wizard as a full-screen modal
  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const PrivacyCheckupWizard(),
      ),
    );
  }

  @override
  State<PrivacyCheckupWizard> createState() => _PrivacyCheckupWizardState();
}

class _PrivacyCheckupWizardState extends State<PrivacyCheckupWizard>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final PrivacySettingsController _controller;

  int _currentStep = 0;
  bool _isLoading = true;
  PrivacyCheckupResult? _checkupResult;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Wizard steps
  final List<_WizardStep> _steps = [
    _WizardStep(
      title: 'Privacy Checkup',
      subtitle: 'Review your privacy settings',
      icon: Iconsax.shield_tick,
      type: _StepType.welcome,
    ),
    _WizardStep(
      title: 'Profile Visibility',
      subtitle: 'Control who can see your info',
      icon: Iconsax.eye,
      type: _StepType.profileVisibility,
    ),
    _WizardStep(
      title: 'Communication',
      subtitle: 'Manage messaging & calls',
      icon: Iconsax.message,
      type: _StepType.communication,
    ),
    _WizardStep(
      title: 'Security',
      subtitle: 'Protect your account',
      icon: Iconsax.lock,
      type: _StepType.security,
    ),
    _WizardStep(
      title: 'Summary',
      subtitle: 'Your privacy score',
      icon: Iconsax.chart,
      type: _StepType.summary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<PrivacySettingsController>();

    // Setup animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _runCheckup();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _runCheckup() async {
    setState(() => _isLoading = true);

    try {
      final result = await _controller.runPrivacyCheckup();
      setState(() {
        _checkupResult = result;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to run privacy checkup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Step content
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _currentStep = index);
                        },
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return _buildStepContent(_steps[index]);
                        },
                      ),
                    ),

                    // Navigation buttons
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? ColorsManager.primary
                : isCompleted
                    ? ColorsManager.primary.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ColorsManager.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your privacy settings...',
            style: StylesManager.medium(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(_WizardStep step) {
    switch (step.type) {
      case _StepType.welcome:
        return _buildWelcomeStep(step);
      case _StepType.profileVisibility:
        return _buildProfileVisibilityStep(step);
      case _StepType.communication:
        return _buildCommunicationStep(step);
      case _StepType.security:
        return _buildSecurityStep(step);
      case _StepType.summary:
        return _buildSummaryStep(step);
    }
  }

  Widget _buildWelcomeStep(_WizardStep step) {
    final settings = _controller.settings;
    final score = _checkupResult?.score ?? _controller.privacyScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Score circle
          _buildScoreCircle(score),
          const SizedBox(height: 32),

          Text(
            'Privacy Checkup',
            style: StylesManager.bold(fontSize: FontSize.xLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Let\'s review your privacy settings and make sure everything is configured the way you want.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Quick stats
          Row(
            children: [
              Expanded(
                  child: _buildQuickStat(
                icon: Iconsax.eye_slash,
                value: _getVisibilityLabel(
                    settings.profileVisibility.lastSeen.level),
                label: 'Last Seen',
              )),
              Expanded(
                  child: _buildQuickStat(
                icon: Iconsax.lock,
                value: settings.security.appLockEnabled ? 'On' : 'Off',
                label: 'App Lock',
              )),
              Expanded(
                  child: _buildQuickStat(
                icon: Iconsax.shield_tick,
                value: settings.security.twoStepEnabled ? 'On' : 'Off',
                label: '2-Step',
              )),
            ],
          ),

          const SizedBox(height: 32),

          // Issues preview
          if (_checkupResult != null && _checkupResult!.issues.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_checkupResult!.issues.length} issues found',
                          style: StylesManager.semiBold(
                            fontSize: FontSize.medium,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'We\'ll help you fix them',
                          style: StylesManager.regular(
                            fontSize: FontSize.small,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileVisibilityStep(_WizardStep step) {
    final settings = _controller.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(step),
          const SizedBox(height: 24),
          _buildSettingCard(
            title: 'Last Seen',
            subtitle: 'Who can see when you were last online',
            currentValue:
                _getVisibilityLabel(settings.profileVisibility.lastSeen.level),
            icon: Iconsax.clock,
            options: VisibilityLevel.values,
            currentLevel: settings.profileVisibility.lastSeen.level,
            onChanged: (level) => _controller.updateLastSeenVisibility(level),
          ),
          _buildSettingCard(
            title: 'Profile Photo',
            subtitle: 'Who can see your profile picture',
            currentValue: _getVisibilityLabel(
                settings.profileVisibility.profilePhoto.level),
            icon: Iconsax.image,
            options: VisibilityLevel.values,
            currentLevel: settings.profileVisibility.profilePhoto.level,
            onChanged: (level) =>
                _controller.updateProfilePhotoVisibility(level),
          ),
          _buildSettingCard(
            title: 'About',
            subtitle: 'Who can see your about info',
            currentValue:
                _getVisibilityLabel(settings.profileVisibility.about.level),
            icon: Iconsax.info_circle,
            options: VisibilityLevel.values,
            currentLevel: settings.profileVisibility.about.level,
            onChanged: (level) => _controller.updateAboutVisibility(level),
          ),
          _buildSettingCard(
            title: 'Online Status',
            subtitle: 'Who can see when you\'re online',
            currentValue: _getVisibilityLabel(
                settings.profileVisibility.onlineStatus.level),
            icon: Iconsax.activity,
            options: VisibilityLevel.values,
            currentLevel: settings.profileVisibility.onlineStatus.level,
            onChanged: (level) =>
                _controller.updateOnlineStatusVisibility(level),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationStep(_WizardStep step) {
    final settings = _controller.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(step),
          const SizedBox(height: 24),
          _buildSettingCard(
            title: 'Who Can Message Me',
            subtitle: 'Control who can send you messages',
            currentValue:
                _getVisibilityLabel(settings.communication.whoCanMessage.level),
            icon: Iconsax.message,
            options: VisibilityLevel.values,
            currentLevel: settings.communication.whoCanMessage.level,
            onChanged: (level) => _controller.updateWhoCanMessage(level),
          ),
          _buildSettingCard(
            title: 'Who Can Call Me',
            subtitle: 'Control who can call you',
            currentValue:
                _getVisibilityLabel(settings.communication.whoCanCall.level),
            icon: Iconsax.call,
            options: VisibilityLevel.values,
            currentLevel: settings.communication.whoCanCall.level,
            onChanged: (level) => _controller.updateWhoCanCall(level),
          ),
          _buildSettingCard(
            title: 'Group Invitations',
            subtitle: 'Who can add you to groups',
            currentValue: _getVisibilityLabel(
                settings.communication.whoCanAddToGroups.level),
            icon: Iconsax.people,
            options: VisibilityLevel.values,
            currentLevel: settings.communication.whoCanAddToGroups.level,
            onChanged: (level) => _controller.updateWhoCanAddToGroups(level),
          ),
          const SizedBox(height: 16),
          _buildToggleCard(
            title: 'Read Receipts',
            subtitle: 'Show others when you\'ve read their messages',
            value: settings.communication.readReceipts,
            icon: Iconsax.tick_circle,
            onChanged: (value) {
              _controller.toggleReadReceipts(value);
            },
          ),
          _buildToggleCard(
            title: 'Typing Indicator',
            subtitle: 'Show others when you\'re typing',
            value: settings.communication.typingIndicator,
            icon: Iconsax.edit,
            onChanged: (value) {
              _controller.toggleTypingIndicator(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep(_WizardStep step) {
    final settings = _controller.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(step),
          const SizedBox(height: 24),
          _buildToggleCard(
            title: 'App Lock',
            subtitle: 'Require authentication to open the app',
            value: settings.security.appLockEnabled,
            icon: Iconsax.lock,
            onChanged: (value) => _controller.toggleAppLock(value),
            isImportant: !settings.security.appLockEnabled,
          ),
          if (settings.security.appLockEnabled)
            _buildToggleCard(
              title: 'Biometric Unlock',
              subtitle: 'Use fingerprint or face to unlock',
              value: settings.security.biometricEnabled,
              icon: Iconsax.finger_scan,
              onChanged: (value) => _controller.toggleBiometric(value),
            ),
          _buildToggleCard(
            title: 'Two-Step Verification',
            subtitle: 'Add an extra layer of security',
            value: settings.security.twoStepEnabled,
            icon: Iconsax.shield_tick,
            onChanged: (value) => _controller.toggleTwoStepVerification(value),
            isImportant: !settings.security.twoStepEnabled,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildToggleCard(
            title: 'Allow Screenshots',
            subtitle: 'Allow others to screenshot your messages',
            value: settings.contentProtection.allowScreenshots,
            icon: Iconsax.screenmirroring,
            onChanged: (value) => _controller.toggleScreenshots(value),
          ),
          _buildToggleCard(
            title: 'Allow Forwarding',
            subtitle: 'Allow others to forward your messages',
            value: settings.contentProtection.allowForwarding,
            icon: Iconsax.forward,
            onChanged: (value) => _controller.toggleForwarding(value),
          ),
          _buildToggleCard(
            title: 'Hide Media in Gallery',
            subtitle: 'Don\'t show Crypted media in phone gallery',
            value: settings.contentProtection.hideMediaInGallery,
            icon: Iconsax.gallery_slash,
            onChanged: (value) => _controller.toggleHideMediaInGallery(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(_WizardStep step) {
    final score = _checkupResult?.score ?? _controller.privacyScore;
    final issues = _checkupResult?.issues ?? [];
    final recommendations = _checkupResult?.recommendations ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Final score
          _buildScoreCircle(score, large: true),
          const SizedBox(height: 24),

          Text(
            _getScoreLabel(score),
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: _getScoreColor(score),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _getScoreDescription(score),
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Issues to fix
          if (issues.isNotEmpty) ...[
            _buildSectionHeader('Issues to Address', issues.length),
            const SizedBox(height: 12),
            ...issues.map((issue) => _buildIssueCard(issue)),
            const SizedBox(height: 24),
          ],

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            _buildSectionHeader('Recommendations', recommendations.length),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],

          // All good message
          if (issues.isEmpty && recommendations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.tick_circle,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your privacy settings look great!',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.medium,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep up the good work protecting your privacy.',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(_WizardStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            step.icon,
            color: ColorsManager.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step.title,
          style: StylesManager.bold(fontSize: FontSize.large),
        ),
        const SizedBox(height: 4),
        Text(
          step.subtitle,
          style: StylesManager.regular(
            fontSize: FontSize.medium,
            color: ColorsManager.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCircle(int score, {bool large = false}) {
    final size = large ? 160.0 : 120.0;
    final strokeWidth = large ? 10.0 : 8.0;
    final fontSize = large ? 48.0 : 36.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.grey.shade200,
            color: Colors.grey.shade200,
          ),
          // Progress circle
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            color: _getScoreColor(score),
            strokeCap: StrokeCap.round,
          ),
          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: StylesManager.bold(
                  fontSize: fontSize,
                  color: _getScoreColor(score),
                ),
              ),
              Text(
                'score',
                style: StylesManager.regular(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: ColorsManager.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: StylesManager.semiBold(fontSize: FontSize.small),
          ),
          Text(
            label,
            style: StylesManager.regular(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required String currentValue,
    required IconData icon,
    required List<VisibilityLevel> options,
    required VisibilityLevel currentLevel,
    required Function(VisibilityLevel) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ColorsManager.primary, size: 22),
        ),
        title: Text(
          title,
          style: StylesManager.semiBold(fontSize: FontSize.medium),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: StylesManager.regular(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            currentValue,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.primary,
            ),
          ),
        ),
        onTap: () =>
            _showVisibilityPicker(title, options, currentLevel, onChanged),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
    bool isImportant = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isImportant && !value ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: isImportant && !value
            ? Border.all(color: Colors.orange.shade200)
            : null,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(16),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isImportant && !value
                ? Colors.orange.withValues(alpha: 0.2)
                : ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isImportant && !value
                ? Colors.orange.shade700
                : ColorsManager.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: StylesManager.semiBold(fontSize: FontSize.medium),
            ),
            if (isImportant && !value) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recommended',
                  style: StylesManager.medium(
                    fontSize: 10,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: StylesManager.regular(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey,
            ),
          ),
        ),
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
        activeThumbColor: ColorsManager.primary,
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: StylesManager.bold(fontSize: FontSize.medium),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssueCard(PrivacyIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.warning_2,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.small,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  issue.description,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (issue.canAutoFix)
            TextButton(
              onPressed: () async {
                final success = await _controller.autoFixIssue(issue.id);
                if (success) {
                  await _runCheckup();
                }
              },
              child: const Text('Fix'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(PrivacyRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.lamp_on,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.small,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  rec.description,
                  style: StylesManager.regular(
                    fontSize: FontSize.xSmall,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _steps.length - 1;
    final isFirstStep = _currentStep == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ColorsManager.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: ColorsManager.primary,
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: 16),

          // Next/Done button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLastStep ? 'Done' : 'Continue',
                style: StylesManager.semiBold(fontSize: FontSize.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVisibilityPicker(
    String title,
    List<VisibilityLevel> options,
    VisibilityLevel currentLevel,
    Function(VisibilityLevel) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: StylesManager.bold(fontSize: FontSize.large),
              ),
            ),
            ...options.map((level) => ListTile(
                  leading: Radio<VisibilityLevel>(
                    value: level,
                    groupValue: currentLevel,
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(value);
                        Navigator.pop(context);
                      }
                    },
                    activeColor: ColorsManager.primary,
                  ),
                  title: Text(_getVisibilityLabel(level)),
                  subtitle: Text(
                    _getVisibilityDescription(level),
                    style: StylesManager.regular(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                  onTap: () {
                    onChanged(level);
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _getVisibilityLabel(VisibilityLevel level) {
    switch (level) {
      case VisibilityLevel.everyone:
        return 'Everyone';
      case VisibilityLevel.contacts:
        return 'Contacts';
      case VisibilityLevel.contactsExcept:
        return 'Contacts except...';
      case VisibilityLevel.nobody:
        return 'Nobody';
      case VisibilityLevel.nobodyExcept:
        return 'Nobody except...';
    }
  }

  String _getVisibilityDescription(VisibilityLevel level) {
    switch (level) {
      case VisibilityLevel.everyone:
        return 'Anyone can see this';
      case VisibilityLevel.contacts:
        return 'Only your contacts can see this';
      case VisibilityLevel.contactsExcept:
        return 'Your contacts except some people';
      case VisibilityLevel.nobody:
        return 'Nobody can see this';
      case VisibilityLevel.nobodyExcept:
        return 'Nobody except some people';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent!';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  String _getScoreDescription(int score) {
    if (score >= 80) {
      return 'Your privacy settings are well configured. Keep it up!';
    }
    if (score >= 60) {
      return 'Your privacy is reasonably protected. Consider the suggestions below.';
    }
    if (score >= 40) {
      return 'There are some areas where your privacy could be improved.';
    }
    return 'Your privacy settings need attention. Review the issues below.';
  }
}

// Internal models

enum _StepType {
  welcome,
  profileVisibility,
  communication,
  security,
  summary,
}

class _WizardStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final _StepType type;

  const _WizardStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
}
