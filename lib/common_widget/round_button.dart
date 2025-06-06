import 'package:flutter/material.dart';

enum RoundButtonType { primary, secondary, text }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;

  const RoundButton({
    super.key,
    required this.title,
    this.type = RoundButtonType.primary,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: type == RoundButtonType.primary 
            ? colorScheme.primary 
            : type == RoundButtonType.secondary 
                ? colorScheme.secondary 
                : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: type != RoundButtonType.text 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: MaterialButton(
        onPressed: onPressed,
        height: 50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: type == RoundButtonType.text 
              ? BorderSide(color: colorScheme.primary)
              : BorderSide.none,
        ),
        minWidth: double.maxFinite,
        elevation: type != RoundButtonType.text ? 0 : elevation,
        color: Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            color: type == RoundButtonType.text 
                ? colorScheme.primary 
                : type == RoundButtonType.primary 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSecondary,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
