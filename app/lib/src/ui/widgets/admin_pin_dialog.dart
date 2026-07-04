import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';
import 'pin_input_fields.dart';

class AdminPinDialog extends StatefulWidget {
  final String uid;
  final String? profileId;
  final VoidCallback? onSuccess;
  final String? title;
  final String? message;

  const AdminPinDialog({
    super.key,
    required this.uid,
    required this.profileId,
    this.onSuccess,
    this.title,
    this.message,
  });

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController(text: ' '));
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;
  bool _showError = false;
  bool _showSuccess = false;
  bool _isDefaultPin = false;

  // ── Shake animation ──
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── Error flash animation ──
  late final AnimationController _errorFlashController;
  late final Animation<Color?> _errorColorAnimation;

  // ── Success scale animation ──
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnimation;
  late final Animation<double> _successOpacityAnimation;

  // ── Dialog entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFadeAnimation;
  late final Animation<double> _entranceScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Shake: quick left-right oscillation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Error flash: border turns red then back
    _errorFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _errorColorAnimation = ColorTween(
      begin: Colors.red.shade400,
      end: AppColors.primaryBackground,
    ).animate(CurvedAnimation(
      parent: _errorFlashController,
      curve: Curves.easeOut,
    ));

    // Success: scale + opacity for checkmark
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _entranceFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _entranceController.forward();

    _checkIfDefaultPin();

    // Auto-focus the first field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  Future<void> _checkIfDefaultPin() async {
    try {
      if (widget.profileId != null) {
        final isDefault = await ProfileService.verifyAdminPin(
          widget.uid,
          widget.profileId!,
          '0000',
        );
        if (mounted) {
          setState(() {
            _isDefaultPin = isDefault;
          });
        }
      } else {
        // Verify if any admin profile has the default '0000' PIN
        final profiles = await ProfileService.getProfiles(widget.uid);
        final adminProfiles = profiles.where((p) => p.isAdmin).toList();
        for (final admin in adminProfiles) {
          final ok = await ProfileService.verifyAdminPin(widget.uid, admin.id, '0000');
          if (ok) {
            if (mounted) {
              setState(() {
                _isDefaultPin = true;
              });
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    _errorFlashController.dispose();
    _successController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── PIN helpers ──

  String get _currentPin =>
      _controllers.map((c) => c.text == ' ' ? '' : c.text).join();

  Future<void> _verifyPin() async {
    if (_isVerifying) return;

    final pin = _currentPin;
    if (pin.length != 4) return;

    setState(() {
      _isVerifying = true;
      _showError = false;
    });

    try {
      bool isCorrect = false;
      if (widget.profileId != null) {
        isCorrect = await ProfileService.verifyAdminPin(
          widget.uid,
          widget.profileId!,
          pin,
        );
      } else {
        // Verify against any admin profile
        final profiles = await ProfileService.getProfiles(widget.uid);
        final adminProfiles = profiles.where((p) => p.isAdmin).toList();
        for (final admin in adminProfiles) {
          final ok = await ProfileService.verifyAdminPin(widget.uid, admin.id, pin);
          if (ok) {
            isCorrect = true;
            break;
          }
        }
      }

      if (!mounted) return;

      if (isCorrect) {
        setState(() => _showSuccess = true);
        await _successController.forward();
        // Small delay so the user sees the checkmark
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          Navigator.of(context).pop(pin);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _showError = true);
        _shakeController.forward(from: 0);
        _errorFlashController.forward(from: 0);

        // Clear all fields after shake finishes
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          for (final c in _controllers) {
            c.text = ' ';
          }
          _focusNodes[0].requestFocus();
          setState(() => _isVerifying = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _showError = true;
        });
        for (final c in _controllers) {
          c.text = ' ';
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFadeAnimation,
      child: ScaleTransition(
        scale: _entranceScaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentDark.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.accentDark.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Lock icon ──
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.accent3,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ──
                Text(
                  widget.title ?? 'Skriv inn PIN',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Subtitle ──
                Text(
                  widget.message ?? 'Denne profilen er beskyttet',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryText2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isDefaultPin) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tips: Standard PIN-kode er 0000',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),

                // ── PIN fields or Success checkmark ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _showSuccess
                      ? _buildSuccessCheckmark()
                      : _buildPinFields(),
                ),

                // ── Error text ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _showError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Feil PIN',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade400,
                            ),
                          ),
                        )
                      : const SizedBox(height: 0),
                ),

                const SizedBox(height: 24),

                // ── Cancel button ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _isVerifying && !_showSuccess
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor:
                          AppColors.primaryBackground.withValues(alpha: 0.7),
                    ),
                    child: Text(
                      'Avbryt',
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinFields() {
    return AnimatedBuilder(
      key: const ValueKey('pin_fields'),
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _errorColorAnimation,
        builder: (context, _) {
          final borderColor = _showError
              ? _errorColorAnimation.value ?? Colors.red.shade400
              : null;
          return PinInputFields(
            controllers: _controllers,
            focusNodes: _focusNodes,
            isEnabled: !_isVerifying,
            borderColor: borderColor,
            onChanged: (pin) {
              if (_showError) {
                setState(() => _showError = false);
              }
              if (pin.length == 4) {
                _verifyPin();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSuccessCheckmark() {
    return SizedBox(
      key: const ValueKey('success_check'),
      height: 58,
      child: Center(
        child: FadeTransition(
          opacity: _successOpacityAnimation,
          child: ScaleTransition(
            scale: _successScaleAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent3.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.accent3,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
