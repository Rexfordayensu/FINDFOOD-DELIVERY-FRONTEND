import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String) onChanged;
  final TextEditingController controller;
  final bool enabled;

  const OtpInputWidget({
    super.key,
    required this.onChanged,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
    _controllers = List.generate(6, (_) => TextEditingController());

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else if (value.length == 1) {
      // Single digit entered
      _controllers[index].text = value;
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _updateOtpValue();
    } else if (value.length == 6 && index == 0) {
      // Paste 6-digit OTP
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].unfocus();
      _updateOtpValue();
    }
  }

  void _updateOtpValue() {
    final otp = _controllers.map((c) => c.text).join();
    widget.controller.text = otp;
    widget.onChanged(otp);
  }

  void _clearAllBoxes() {
    for (final controller in _controllers) {
      controller.clear();
    }
    widget.controller.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final boxBorder = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkTextPri : AppTheme.lightTextPri;
    final hintColor = isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Container(
              width: 50,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: boxBg,
                border: Border.all(
                  color: _focusNodes[index].hasFocus
                      ? AppTheme.accent
                      : boxBorder,
                  width: _focusNodes[index].hasFocus ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '-',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 28,
                  ),
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                ),
                onChanged: (value) {
                  _handleInput(value, index);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.controller.text.isNotEmpty)
          TextButton.icon(
            onPressed: _clearAllBoxes,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.danger,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}
