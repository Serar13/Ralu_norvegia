

import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/validators.dart';

class WidgetFactory {
  static Widget buttonWithTextIcon(
      String buttonText,
      double buttonHeight,
      double buttonWidth,
      double opacity,
      Color containerColor,
      Color borderColor,
      double borderwidth,
      Color textColor,
      String? buttonIc,
      VoidCallback onClick) {
    return  Container(
      height: buttonHeight,
      width: buttonWidth,
      decoration: BoxDecoration(
        color: containerColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: borderColor,
          width: borderwidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25), // Match the border radius of the outer container
          onTap: () {
            onClick.call();
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (buttonIc != null)...[
                  Image.asset(
                    buttonIc,
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  buttonText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  static Widget buttonWithTextIconExpanded(
      String buttonText,
      double buttonHeight,
      double opacity,
      Color containerColor,
      Color borderColor,
      double borderwidth,
      Color textColor,
      VoidCallback onClick
      ) {
    return Expanded(
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            color: containerColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor,
              width: borderwidth,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              // Match the border radius of the outer container
              onTap: () {
                onClick.call();
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
    );
  }

  static Widget makeInputPassword(
      {label,
        contex,
        controller,
        TextInputType? keyboardType,
        obscureText = false,
        passToggle,
        required Validator? validator,
        required VoidCallback togglePasswordVisibility
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          scrollPadding: const EdgeInsets.only(
              bottom: 300),
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.primaryText,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: (value) {
            return validator?.validate(value);
          },
          decoration: InputDecoration(
            suffixIcon: InkWell(
              onTap: togglePasswordVisibility,
              child: Icon(
                  passToggle ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.accent3
              ),
            ),
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.primaryText,
            ),
            hintText: label,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Colors.white,
              ),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
        const SizedBox(
          height: 15,
        )
      ],
    );
  }

  static Widget makeInput(
      {label,
        contex,
        controller,
        TextInputType? keyboardType,
        obscureText = false,
        required Validator? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          scrollPadding: const EdgeInsets.only(
              bottom: 300),
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.primaryText,
          ),
          obscureText: obscureText,
          textCapitalization: TextCapitalization.none,
          keyboardType: keyboardType,
          validator: (value) {
            return validator?.validate(value);
          },
          decoration: InputDecoration(
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.primaryText,
            ),
            hintText: label,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Colors.white,
              ),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
        const SizedBox(
          height: 15,
        )
      ],
    );
  }


}