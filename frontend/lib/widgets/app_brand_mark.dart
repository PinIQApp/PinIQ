import 'package:flutter/material.dart';

import 'wrestletech_mark.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.iconSize = 76,
    this.textScale = 1,
    this.showWordmark = true,
    this.borderRadius,
  });

  final double iconSize;
  final double textScale;
  final bool showWordmark;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final icon = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(iconSize * 0.22),
      child: Image.asset(
        'assets/images/wrestletech_icon.jpg',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => WrestleTechMark(
          iconSize: iconSize,
          textScale: textScale,
          showWordmark: showWordmark,
        ),
      ),
    );

    if (!showWordmark) {
      return icon;
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(iconSize * 0.18),
      child: Image.asset(
        'assets/images/wrestletech_logo.jpg',
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: 14 * textScale),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28 * textScale,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                  children: const [
                    TextSpan(text: 'Pin '),
                    TextSpan(
                      text: 'IQ',
                      style: TextStyle(color: Color(0xFFE11D1D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
