import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// PIN input widget with visual dots and numeric keypad
class PinInputWidget extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool showError;
  final String? errorText;
  final VoidCallback? onBiometricPressed;
  final bool showBiometricButton;
  final IconData? biometricIcon;

  const PinInputWidget({
    super.key,
    this.pinLength = 4,
    required this.onCompleted,
    this.onChanged,
    this.obscureText = true,
    this.showError = false,
    this.errorText,
    this.onBiometricPressed,
    this.showBiometricButton = false,
    this.biometricIcon,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showError && !oldWidget.showError) {
      _shakeController.forward();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length >= widget.pinLength) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
    });

    widget.onChanged?.call(_pin);

    if (_pin.length == widget.pinLength) {
      widget.onCompleted(_pin);
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });

    widget.onChanged?.call(_pin);
  }

  void clear() {
    setState(() {
      _pin = '';
    });
    widget.onChanged?.call(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots display
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * (widget.showError ? 1 : 0), 0),
              child: child,
            );
          },
          child: _buildPinDisplay(),
        ),

        const SizedBox(height: 16),

        // Error text
        if (widget.showError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
          ),

        // Numeric keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pinLength, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (widget.showError ? Colors.red : ColorsManager.primary)
                : Colors.transparent,
            border: Border.all(
              color: widget.showError
                  ? Colors.red
                  : (isFilled ? ColorsManager.primary : ColorsManager.grey),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          // Row 2: 4, 5, 6
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          // Row 3: 7, 8, 9
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          // Row 4: biometric/empty, 0, delete
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildKeypadButton(digit)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric or empty
        if (widget.showBiometricButton && widget.onBiometricPressed != null)
          _buildActionButton(
            icon: widget.biometricIcon ?? Icons.fingerprint,
            onPressed: widget.onBiometricPressed!,
          )
        else
          const SizedBox(width: 72, height: 72),

        // 0
        _buildKeypadButton('0'),

        // Delete
        _buildActionButton(
          icon: Icons.backspace_outlined,
          onPressed: _removeDigit,
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addDigit(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorsManager.white,
            border: Border.all(
              color: ColorsManager.lightGrey,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: StylesManager.bold(
                fontSize: FontSize.xLarge + 4,
                color: ColorsManager.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorsManager.offWhite,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: ColorsManager.grey,
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN setup screen for creating a new PIN
class PinSetupScreen extends StatefulWidget {
  final ValueChanged<String> onPinCreated;
  final VoidCallback? onCancel;
  final int pinLength;

  const PinSetupScreen({
    super.key,
    required this.onPinCreated,
    this.onCancel,
    this.pinLength = 4,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstPin;
  bool _isConfirming = false;
  bool _showError = false;
  String? _errorText;

  final GlobalKey<_PinInputWidgetState> _pinInputKey =
      GlobalKey<_PinInputWidgetState>();

  void _onPinCompleted(String pin) {
    if (!_isConfirming) {
      // First entry - save and ask for confirmation
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _showError = false;
        _errorText = null;
      });
      _pinInputKey.currentState?.clear();
    } else {
      // Confirming - check if PINs match
      if (pin == _firstPin) {
        widget.onPinCreated(pin);
      } else {
        setState(() {
          _showError = true;
          _errorText = 'PINs do not match. Please try again.';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _pinInputKey.currentState?.clear();
          setState(() {
            _showError = false;
          });
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _firstPin = null;
      _isConfirming = false;
      _showError = false;
      _errorText = null;
    });
    _pinInputKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      appBar: AppBar(
        backgroundColor: ColorsManager.navbarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ColorsManager.black),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isConfirming ? 'Confirm PIN' : 'Create PIN',
          style: StylesManager.bold(
            fontSize: FontSize.large,
            color: ColorsManager.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConfirming ? Icons.check_circle_outline : Icons.lock_outline,
                size: 40,
                color: ColorsManager.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Enter a ${widget.pinLength}-digit PIN',
              style: StylesManager.medium(
                fontSize: FontSize.large,
                color: ColorsManager.black,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              _isConfirming
                  ? 'Re-enter your PIN to confirm'
                  : 'This PIN will be used to unlock the app',
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // PIN input
            PinInputWidget(
              key: _pinInputKey,
              pinLength: widget.pinLength,
              onCompleted: _onPinCompleted,
              showError: _showError,
              errorText: _errorText,
            ),

            const SizedBox(height: 24),

            // Reset button (only when confirming)
            if (_isConfirming)
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Start over',
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: ColorsManager.primary,
                  ),
                ),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// PIN verification screen for unlocking with PIN
class PinVerificationScreen extends StatefulWidget {
  final ValueChanged<bool> onVerified;
  final VoidCallback? onCancel;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBiometricPressed;
  final bool showBiometricButton;
  final IconData? biometricIcon;
  final int pinLength;
  final Future<bool> Function(String pin) verifyPin;

  const PinVerificationScreen({
    super.key,
    required this.onVerified,
    required this.verifyPin,
    this.onCancel,
    this.title,
    this.subtitle,
    this.onBiometricPressed,
    this.showBiometricButton = false,
    this.biometricIcon,
    this.pinLength = 4,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  bool _showError = false;
  String? _errorText;
  bool _isVerifying = false;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  final GlobalKey<_PinInputWidgetState> _pinInputKey =
      GlobalKey<_PinInputWidgetState>();

  Future<void> _onPinCompleted(String pin) async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _showError = false;
    });

    try {
      final isValid = await widget.verifyPin(pin);

      if (isValid) {
        widget.onVerified(true);
      } else {
        _attempts++;
        setState(() {
          _showError = true;
          _errorText = _attempts >= _maxAttempts
              ? 'Too many attempts. Please try again later.'
              : 'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
        });

        if (_attempts >= _maxAttempts) {
          // Lock out the user
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              setState(() {
                _attempts = 0;
                _showError = false;
              });
            }
          });
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            _pinInputKey.currentState?.clear();
            if (mounted) {
              setState(() {
                _showError = false;
              });
            }
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.navbarColor,
      appBar: widget.onCancel != null
          ? AppBar(
              backgroundColor: ColorsManager.navbarColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: ColorsManager.black),
                onPressed: widget.onCancel,
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: ColorsManager.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              widget.title ?? 'Enter PIN',
              style: StylesManager.medium(
                fontSize: FontSize.large,
                color: ColorsManager.black,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              widget.subtitle ?? 'Enter your PIN to continue',
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // PIN input
            if (_attempts < _maxAttempts)
              PinInputWidget(
                key: _pinInputKey,
                pinLength: widget.pinLength,
                onCompleted: _onPinCompleted,
                showError: _showError,
                errorText: _errorText,
                showBiometricButton: widget.showBiometricButton,
                onBiometricPressed: widget.onBiometricPressed,
                biometricIcon: widget.biometricIcon,
              )
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Too many attempts',
                      style: StylesManager.bold(
                        fontSize: FontSize.large,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait 30 seconds before trying again',
                      style: StylesManager.regular(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
