import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';

class PinInputFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isEnabled;
  final ValueChanged<String>? onChanged;
  final Color? borderColor;

  const PinInputFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.isEnabled = true,
    this.onChanged,
    this.borderColor,
  });

  @override
  State<PinInputFields> createState() => _PinInputFieldsState();
}

class _PinInputFieldsState extends State<PinInputFields> {
  bool _isObscured = true;

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Backspace was pressed (changed from ' ' to '')
      widget.controllers[index].text = ' ';
      if (index > 0) {
        widget.controllers[index - 1].text = ' ';
        widget.focusNodes[index - 1].requestFocus();
      }
    } else {
      // User typed something
      final cleanValue = value.replaceAll(' ', '');
      if (cleanValue.isNotEmpty) {
        // Keep only the last character typed
        widget.controllers[index].text = cleanValue[cleanValue.length - 1];
        widget.controllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: 1),
        );
        if (index < 3) {
          widget.focusNodes[index + 1].requestFocus();
        }
      } else {
        // Fallback to space
        widget.controllers[index].text = ' ';
      }
    }

    final pin = widget.controllers.map((c) => c.text == ' ' ? '' : c.text).join();
    if (widget.onChanged != null) {
      widget.onChanged!(pin);
    }
    setState(() {}); // trigger build to update obscureText conditions
  }

  void _onFieldTap(int index) {
    // Find the first empty field (which has text == ' ')
    int firstEmptyIndex = -1;
    for (int i = 0; i < 4; i++) {
      if (widget.controllers[i].text == ' ') {
        firstEmptyIndex = i;
        break;
      }
    }

    if (firstEmptyIndex != -1) {
      widget.focusNodes[firstEmptyIndex].requestFocus();
    } else {
      // All filled, keep focus on tapped or last one
      widget.focusNodes[index].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the item width based on constraints, with a max of 44.
        // Total padding & icon space = (3 * 8) + 8 + 34 = 66.
        // So the remaining width for 4 boxes is constraints.maxWidth - 66.
        // Each box width can be calculated dynamically and clamped.
        final availableWidth = constraints.maxWidth;
        final boxWidth = ((availableWidth - 66) / 4).clamp(32.0, 44.0);
        final boxHeight = (boxWidth * 1.18).clamp(38.0, 52.0);
        final paddingBetween = (availableWidth < 250) ? 6.0 : 8.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(4, (i) {
              final showObscured = _isObscured && widget.controllers[i].text != ' ';

              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0.0 : paddingBetween),
                child: SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: TextField(
                    controller: widget.controllers[i],
                    focusNode: widget.focusNodes[i],
                    enabled: widget.isEnabled,
                    obscureText: showObscured,
                    obscuringCharacter: '●',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 2, // Allow 2 to process space + typed char easily before cleaning
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: (boxWidth * 0.5).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.primaryBackground,
                      contentPadding: EdgeInsets.symmetric(vertical: (boxWidth * 0.25).clamp(8.0, 12.0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.borderColor ?? AppColors.primaryBackground,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.borderColor ?? AppColors.primaryBackground,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.borderColor ?? AppColors.accent3,
                          width: 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBackground,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onDigitChanged(i, value),
                    onTap: () => _onFieldTap(i),
                  ),
                ),
              );
            }),
            SizedBox(width: paddingBetween),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(
                  _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.primaryText2.withValues(alpha: 0.6),
                  size: (boxWidth * 0.5).clamp(18.0, 22.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
