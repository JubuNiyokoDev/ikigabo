import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/pin_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../../l10n/app_localizations.dart';

class PinScreen extends ConsumerStatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;
  final String? oldPin;
  final Completer<bool>? completer;

  const PinScreen({
    super.key,
    this.mode = PinMode.verify,
    this.onSuccess,
    this.oldPin,
    this.completer,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

enum PinMode { setup, verify, change }

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  final int _pinLength = 4;

  void _onNumberTap(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
        _hasError = false;
      });

      if (_pin.length == _pinLength) {
        _handlePinComplete();
      }
    }
  }

  void _onDeleteTap() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  void _handlePinComplete() async {
    if (widget.mode == PinMode.setup) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        if (_pin == _confirmPin) {
          final success = await ref.read(pinProvider.notifier).setPin(_pin);
          if (success) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          setState(() {
            _hasError = true;
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else if (widget.mode == PinMode.verify) {
      final success = await ref.read(pinProvider.notifier).verifyPin(_pin);
      if (success && widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (!success && mounted) {
        setState(() {
          _hasError = true;
          _pin = '';
        });
      }
    } else if (widget.mode == PinMode.change) {
      final success = await ref
          .read(pinProvider.notifier)
          .changePin(widget.oldPin!, _pin);
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          _hasError = true;
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.spacing20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 40.h),

              // App logo
              Container(
                width: 64.w,
                height: 64.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(AppIcons.wallet, size: 28.sp, color: Colors.white),
              ).animate().scale(delay: 100.ms, duration: 400.ms),

              SizedBox(height: AppSizes.spacing16),

              // Title
              Text(
                _getTitle(l10n),
                style: TextStyle(
                  fontSize: AppSizes.textHeading,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ).animate().fadeIn(delay: 200.ms),

              SizedBox(height: AppSizes.spacing12),

              Text(
                _getSubtitle(l10n),
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              if (_hasError) ...[
                SizedBox(height: AppSizes.spacing12),
                Text(
                  l10n.incorrectPin,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ).animate().shake(),
              ],

              SizedBox(height: 54.h),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pinLength,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: _PinDot(
                      isFilled: index < _pin.length,
                      isDark: isDark,
                      hasError: _hasError,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              if (widget.mode == PinMode.setup) ...[
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(pinProvider.notifier).skipPinSetup();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    l10n.skipForNow,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.black54,
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              // Biometric button (only for verify mode)
              if (widget.mode == PinMode.verify) ...[
                Consumer(
                  builder: (context, ref, child) {
                    final biometricState = ref.watch(biometricProvider);
                    if (biometricState == BiometricState.enabled) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () async {
                            final success = await ref
                                .read(biometricProvider.notifier)
                                .authenticateWithBiometric();
                            if (success) {
                              ref.read(pinProvider.notifier).markAsAuthenticated();
                              if (widget.onSuccess != null) {
                                widget.onSuccess!();
                              }
                            }
                          },
                          child: Container(
                            width: 64.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              AppIcons.fingerprint,
                              color: AppColors.primary,
                              size: 28.sp,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ] else
                const Spacer(),

              // Numpad
              _buildNumpad(isDark),

              SizedBox(height: AppSizes.spacing16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    if (widget.mode == PinMode.setup) {
      return _isConfirming ? l10n.confirmPin : l10n.createPin;
    } else if (widget.mode == PinMode.change) {
      return l10n.enterNewPin;
    }
    return l10n.enterPin;
  }

  String _getSubtitle(AppLocalizations l10n) {
    if (widget.mode == PinMode.setup) {
      return _isConfirming ? l10n.confirmYourPin : l10n.createPinDescription;
    } else if (widget.mode == PinMode.change) {
      return l10n.enterNewPinDescription;
    }
    return l10n.enterPinToContinue;
  }

  Widget _buildNumpad(bool isDark) {
    return Column(
      children: [
        _buildNumRow(['1', '2', '3'], isDark),
        SizedBox(height: AppSizes.spacing16),
        _buildNumRow(['4', '5', '6'], isDark),
        SizedBox(height: AppSizes.spacing16),
        _buildNumRow(['7', '8', '9'], isDark),
        SizedBox(height: AppSizes.spacing16),
        _buildNumRow(['', '0', 'delete'], isDark),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildNumRow(List<String> numbers, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return SizedBox(width: 64.w, height: 64.h);
        }

        if (number == 'delete') {
          return _NumpadButton(
            onTap: _onDeleteTap,
            isDark: isDark,
            child: Icon(
              AppIcons.delete,
              color: isDark ? AppColors.textDark : Colors.black87,
              size: 24.sp,
            ),
          );
        }

        return _NumpadButton(
          onTap: () => _onNumberTap(number),
          isDark: isDark,
          child: Text(
            number,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool isFilled;
  final bool isDark;
  final bool hasError;

  const _PinDot({
    required this.isFilled,
    required this.isDark,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 18.w,
      height: 18.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? (hasError ? AppColors.error : AppColors.primary)
            : Colors.transparent,
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isFilled
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade400)),
          width: 2,
        ),
      ),
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _NumpadButton({
    required this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 64.w,
        height: 64.h,
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.8)
                    : Colors.grey.shade200)
              : (widget.isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: widget.isDark
                ? AppColors.borderDark.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.1 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
