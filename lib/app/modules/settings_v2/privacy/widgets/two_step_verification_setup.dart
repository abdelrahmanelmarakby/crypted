import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Two-Step Verification Setup Wizard
/// Guides users through setting up two-factor authentication
class TwoStepVerificationSetup extends StatefulWidget {
  final bool isEnabled;

  const TwoStepVerificationSetup({
    super.key,
    this.isEnabled = false,
  });

  /// Show the setup wizard as a full-screen modal
  static Future<bool?> show(BuildContext context, {bool isEnabled = false}) async {
    return await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TwoStepVerificationSetup(isEnabled: isEnabled),
      ),
    );
  }

  @override
  State<TwoStepVerificationSetup> createState() => _TwoStepVerificationSetupState();
}

class _TwoStepVerificationSetupState extends State<TwoStepVerificationSetup>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;

  // PIN setup
  String _pin = '';
  String _confirmPin = '';
  bool _pinMismatch = false;
  final _pinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();

  // Recovery email
  final _emailController = TextEditingController();
  bool _emailValid = false;
  bool _skipEmail = false;

  // Hint
  final _hintController = TextEditingController();

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Steps for setup
  final List<_SetupStep> _setupSteps = [
    _SetupStep(
      title: 'Two-Step Verification',
      type: _StepType.intro,
    ),
    _SetupStep(
      title: 'Create PIN',
      type: _StepType.createPin,
    ),
    _SetupStep(
      title: 'Confirm PIN',
      type: _StepType.confirmPin,
    ),
    _SetupStep(
      title: 'Recovery Email',
      type: _StepType.recoveryEmail,
    ),
    _SetupStep(
      title: 'PIN Hint',
      type: _StepType.hint,
    ),
    _SetupStep(
      title: 'Setup Complete',
      type: _StepType.complete,
    ),
  ];

  // Steps for disable
  final List<_SetupStep> _disableSteps = [
    _SetupStep(
      title: 'Disable Two-Step Verification',
      type: _StepType.disableIntro,
    ),
    _SetupStep(
      title: 'Enter PIN',
      type: _StepType.verifyPin,
    ),
    _SetupStep(
      title: 'Disabled',
      type: _StepType.disableComplete,
    ),
  ];

  List<_SetupStep> get _steps => widget.isEnabled ? _disableSteps : _setupSteps;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _hintController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _emailValid = emailRegex.hasMatch(email);
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      HapticFeedback.lightImpact();

      // Validate current step before proceeding
      if (!_validateCurrentStep()) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final step - complete setup
      _completeSetup();
    }
  }

  bool _validateCurrentStep() {
    final step = _steps[_currentStep];

    switch (step.type) {
      case _StepType.createPin:
        if (_pin.length != 6) {
          _showError('Please enter a 6-digit PIN');
          return false;
        }
        return true;

      case _StepType.confirmPin:
        if (_confirmPin != _pin) {
          setState(() => _pinMismatch = true);
          HapticFeedback.heavyImpact();
          _showError('PINs do not match');
          return false;
        }
        return true;

      case _StepType.recoveryEmail:
        if (!_skipEmail && !_emailValid) {
          _showError('Please enter a valid email');
          return false;
        }
        return true;

      case _StepType.verifyPin:
        if (_pin.length != 6) {
          _showError('Please enter your PIN');
          return false;
        }
        // TODO: Verify PIN with service
        return true;

      default:
        return true;
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

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      final service = Get.find<PrivacySettingsService>();

      if (widget.isEnabled) {
        // Disable two-step verification
        await service.toggleTwoStepVerification(false);
        Get.snackbar(
          'Disabled',
          'Two-step verification has been turned off',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      } else {
        // Enable two-step verification
        await service.setupTwoStepVerification(
          pin: _pin,
          recoveryEmail: _skipEmail ? null : _emailController.text.trim(),
          hint: _hintController.text.trim().isNotEmpty
              ? _hintController.text.trim()
              : null,
        );
        Get.snackbar(
          'Enabled',
          'Two-step verification is now active',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Failed to ${widget.isEnabled ? 'disable' : 'enable'} two-step verification');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
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
            _buildNavigationButtons(),
          ],
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

  Widget _buildStepContent(_SetupStep step) {
    switch (step.type) {
      case _StepType.intro:
        return _buildIntroStep();
      case _StepType.createPin:
        return _buildCreatePinStep();
      case _StepType.confirmPin:
        return _buildConfirmPinStep();
      case _StepType.recoveryEmail:
        return _buildRecoveryEmailStep();
      case _StepType.hint:
        return _buildHintStep();
      case _StepType.complete:
        return _buildCompleteStep();
      case _StepType.disableIntro:
        return _buildDisableIntroStep();
      case _StepType.verifyPin:
        return _buildVerifyPinStep();
      case _StepType.disableComplete:
        return _buildDisableCompleteStep();
    }
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_tick,
              size: 64,
              color: ColorsManager.primary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Two-Step Verification',
            style: StylesManager.bold(fontSize: FontSize.xLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Add an extra layer of security to your account. When enabled, you\'ll need to enter a PIN when registering your phone number with Crypted again.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitItem(
            icon: Iconsax.lock,
            title: 'Secure Account',
            description: 'Protect your account from unauthorized access',
          ),
          _buildBenefitItem(
            icon: Iconsax.key,
            title: '6-Digit PIN',
            description: 'Create a memorable PIN that only you know',
          ),
          _buildBenefitItem(
            icon: Iconsax.sms,
            title: 'Recovery Email',
            description: 'Add an email to reset your PIN if you forget it',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.semiBold(fontSize: FontSize.medium),
                ),
                Text(
                  description,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Icon(
            Iconsax.key,
            size: 64,
            color: ColorsManager.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Create Your PIN',
            style: StylesManager.bold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),

          Text(
            'Enter a 6-digit PIN that you\'ll remember',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // PIN display
          _buildPinDisplay(_pin),
          const SizedBox(height: 32),

          // Keypad
          _buildNumericKeypad(
            onDigit: (digit) {
              if (_pin.length < 6) {
                setState(() => _pin += digit);
                HapticFeedback.lightImpact();
              }
            },
            onDelete: () {
              if (_pin.isNotEmpty) {
                setState(() => _pin = _pin.substring(0, _pin.length - 1));
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Icon(
            Iconsax.tick_circle,
            size: 64,
            color: _pinMismatch ? Colors.red : ColorsManager.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Confirm Your PIN',
            style: StylesManager.bold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),

          Text(
            _pinMismatch
                ? 'PINs don\'t match. Try again.'
                : 'Re-enter your 6-digit PIN',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: _pinMismatch ? Colors.red : ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // PIN display
          _buildPinDisplay(_confirmPin, isError: _pinMismatch),
          const SizedBox(height: 32),

          // Keypad
          _buildNumericKeypad(
            onDigit: (digit) {
              if (_confirmPin.length < 6) {
                setState(() {
                  _confirmPin += digit;
                  _pinMismatch = false;
                });
                HapticFeedback.lightImpact();
              }
            },
            onDelete: () {
              if (_confirmPin.isNotEmpty) {
                setState(() {
                  _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                  _pinMismatch = false;
                });
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Icon(
            Iconsax.sms,
            size: 64,
            color: ColorsManager.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Recovery Email',
            style: StylesManager.bold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),

          Text(
            'Add an email address to help you reset your PIN if you forget it.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email input
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_skipEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'example@email.com',
              prefixIcon: const Icon(Iconsax.sms),
              suffixIcon: _emailValid
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorsManager.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skip option
          CheckboxListTile(
            value: _skipEmail,
            onChanged: (value) {
              setState(() => _skipEmail = value ?? false);
            },
            title: Text(
              'Skip for now',
              style: StylesManager.medium(fontSize: FontSize.medium),
            ),
            subtitle: Text(
              'You can add this later in settings',
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: ColorsManager.primary,
          ),

          if (!_skipEmail) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll send a verification link to this email.',
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: Colors.blue.shade900,
                      ),
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

  Widget _buildHintStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Icon(
            Iconsax.message_question,
            size: 64,
            color: ColorsManager.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Create a Hint',
            style: StylesManager.bold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),

          Text(
            'Add a hint to help you remember your PIN. This hint will be shown if you forget your PIN.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Hint input
          TextField(
            controller: _hintController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'PIN Hint (optional)',
              hintText: 'e.g., My birthday',
              prefixIcon: const Icon(Iconsax.lamp_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorsManager.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Don\'t make the hint too obvious or include your PIN!',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 64),

          // Success animation
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_tick,
              size: 80,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'You\'re All Set!',
            style: StylesManager.bold(fontSize: FontSize.xLarge),
          ),
          const SizedBox(height: 16),

          Text(
            'Two-step verification is now enabled. Your account has an extra layer of security.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Iconsax.tick_circle,
                  label: 'PIN Created',
                  value: '******',
                  color: Colors.green,
                ),
                if (!_skipEmail && _emailController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow(
                    icon: Iconsax.sms,
                    label: 'Recovery Email',
                    value: _emailController.text,
                    color: Colors.blue,
                  ),
                ],
                if (_hintController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow(
                    icon: Iconsax.lamp_on,
                    label: 'Hint',
                    value: _hintController.text,
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisableIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_cross,
              size: 64,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Disable Two-Step Verification',
            style: StylesManager.bold(fontSize: FontSize.large),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Are you sure you want to disable two-step verification? This will make your account less secure.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Without two-step verification, your account may be vulnerable to unauthorized access.',
                    style: StylesManager.regular(
                      fontSize: FontSize.small,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Icon(
            Iconsax.key,
            size: 64,
            color: ColorsManager.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Enter Your PIN',
            style: StylesManager.bold(fontSize: FontSize.large),
          ),
          const SizedBox(height: 8),

          Text(
            'Enter your current PIN to disable two-step verification',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          _buildPinDisplay(_pin),
          const SizedBox(height: 32),

          _buildNumericKeypad(
            onDigit: (digit) {
              if (_pin.length < 6) {
                setState(() => _pin += digit);
                HapticFeedback.lightImpact();
              }
            },
            onDelete: () {
              if (_pin.isNotEmpty) {
                setState(() => _pin = _pin.substring(0, _pin.length - 1));
                HapticFeedback.lightImpact();
              }
            },
          ),

          const SizedBox(height: 24),

          TextButton(
            onPressed: () {
              // TODO: Forgot PIN flow
              Get.snackbar(
                'Forgot PIN',
                'Check your recovery email to reset your PIN',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              'Forgot PIN?',
              style: StylesManager.medium(
                fontSize: FontSize.medium,
                color: ColorsManager.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisableCompleteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 64),

          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_slash,
              size: 80,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Two-Step Verification Disabled',
            style: StylesManager.bold(fontSize: FontSize.large),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Your account no longer requires a PIN for verification. You can enable it again anytime in settings.',
            style: StylesManager.regular(
              fontSize: FontSize.medium,
              color: ColorsManager.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPinDisplay(String pin, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < pin.length;
        return Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isFilled
                ? (isError ? Colors.red : ColorsManager.primary)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? Colors.red
                  : isFilled
                      ? ColorsManager.primary
                      : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: isFilled
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildNumericKeypad({
    required Function(String) onDigit,
    required VoidCallback onDelete,
  }) {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], onDigit),
        const SizedBox(height: 12),
        _buildKeypadRow(['4', '5', '6'], onDigit),
        const SizedBox(height: 12),
        _buildKeypadRow(['7', '8', '9'], onDigit),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80), // Empty space
            _buildKeypadButton('0', onDigit),
            SizedBox(
              width: 80,
              height: 56,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Iconsax.arrow_left, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits, Function(String) onDigit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) => _buildKeypadButton(digit, onDigit)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, Function(String) onDigit) {
    return Container(
      width: 80,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onDigit(digit),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              digit,
              style: StylesManager.bold(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
            ),
            Text(
              value,
              style: StylesManager.semiBold(fontSize: FontSize.medium),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _steps.length - 1;
    final isFirstStep = _currentStep == 0;
    final step = _steps[_currentStep];

    // Determine button text based on step
    String buttonText;
    if (isLastStep) {
      buttonText = 'Done';
    } else if (step.type == _StepType.intro) {
      buttonText = 'Get Started';
    } else if (step.type == _StepType.disableIntro) {
      buttonText = 'Continue';
    } else {
      buttonText = 'Next';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, 16 + MediaQuery.of(context).padding.bottom,
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
          if (!isFirstStep && !isLastStep)
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

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isEnabled && step.type == _StepType.disableIntro
                    ? Colors.red
                    : ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: StylesManager.semiBold(fontSize: FontSize.medium),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Internal models

enum _StepType {
  intro,
  createPin,
  confirmPin,
  recoveryEmail,
  hint,
  complete,
  disableIntro,
  verifyPin,
  disableComplete,
}

class _SetupStep {
  final String title;
  final _StepType type;

  const _SetupStep({
    required this.title,
    required this.type,
  });
}
