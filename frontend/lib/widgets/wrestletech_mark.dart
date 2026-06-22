import 'package:flutter/material.dart';

class WrestleTechMark extends StatelessWidget {
  const WrestleTechMark({
    super.key,
    this.iconSize = 76,
    this.textScale = 1,
    this.showWordmark = true,
  });

  final double iconSize;
  final double textScale;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final wordmarkStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 28 * textScale,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -1.2,
          color: Colors.white,
        );

    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CustomPaint(painter: _WrestleTechIconPainter()),
          ),
          if (showWordmark) ...[
            SizedBox(width: 14 * textScale),
            RichText(
              text: TextSpan(
                style: wordmarkStyle,
                children: [
                  const TextSpan(text: 'Pin '),
                  TextSpan(
                    text: 'IQ',
                    style:
                        wordmarkStyle?.copyWith(color: const Color(0xFFE11D1D)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WrestleTechIconPainter extends CustomPainter {
  const _WrestleTechIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF1A2138),
          Color(0xFF0F1424),
          Color(0xFF090C15),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(center, radius - ringPaint.strokeWidth / 2, ringPaint);

    final glowRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.72),
      width: size.width * 0.66,
      height: size.height * 0.17,
    );
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x0000A3FF),
          Color(0xFF1AA3FF),
          Color(0x0000A3FF),
        ],
      ).createShader(glowRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038;
    canvas.drawArc(glowRect, 0.2, 2.75, false, glowPaint);

    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.97);
    final stripePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = size.width * 0.032
      ..strokeCap = StrokeCap.round;

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.48),
        width: size.width * 0.15,
        height: size.height * 0.34,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(torso, bodyPaint);
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.2),
      size.width * 0.08,
      bodyPaint,
    );
    canvas.drawLine(
      Offset(center.dx - size.width * 0.04, size.height * 0.3),
      Offset(center.dx - size.width * 0.04, size.height * 0.58),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx, size.height * 0.3),
      Offset(center.dx, size.height * 0.58),
      stripePaint,
    );
    canvas.drawLine(
      Offset(center.dx + size.width * 0.04, size.height * 0.3),
      Offset(center.dx + size.width * 0.04, size.height * 0.58),
      stripePaint,
    );

    final raisedArm = Path()
      ..moveTo(center.dx + size.width * 0.025, size.height * 0.32)
      ..lineTo(center.dx + size.width * 0.13, size.height * 0.08)
      ..lineTo(center.dx + size.width * 0.19, size.height * 0.1)
      ..lineTo(center.dx + size.width * 0.08, size.height * 0.35)
      ..close();
    canvas.drawPath(raisedArm, bodyPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + size.width * 0.2, size.height * 0.045),
          width: size.width * 0.08,
          height: size.height * 0.08,
        ),
        Radius.circular(size.width * 0.02),
      ),
      bodyPaint,
    );

    final otherArm = Path()
      ..moveTo(center.dx - size.width * 0.03, size.height * 0.32)
      ..lineTo(center.dx - size.width * 0.15, size.height * 0.26)
      ..lineTo(center.dx - size.width * 0.11, size.height * 0.18)
      ..lineTo(center.dx + size.width * 0.01, size.height * 0.28)
      ..close();
    canvas.drawPath(otherArm, bodyPaint);

    void drawWrestler({required bool left}) {
      final direction = left ? -1.0 : 1.0;
      final shoulder =
          Offset(center.dx + direction * size.width * 0.22, size.height * 0.45);
      final head =
          Offset(center.dx + direction * size.width * 0.29, size.height * 0.39);

      canvas.drawCircle(head, size.width * 0.055, bodyPaint);

      final torsoPath = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..lineTo(shoulder.dx + direction * size.width * 0.18, size.height * 0.5)
        ..lineTo(shoulder.dx + direction * size.width * 0.1, size.height * 0.62)
        ..lineTo(
            shoulder.dx - direction * size.width * 0.03, size.height * 0.58)
        ..close();
      canvas.drawPath(torsoPath, bodyPaint);

      final armPath = Path()
        ..moveTo(shoulder.dx + direction * size.width * 0.02,
            shoulder.dy + size.height * 0.02)
        ..lineTo(center.dx + direction * size.width * 0.06, size.height * 0.49)
        ..lineTo(center.dx + direction * size.width * 0.02, size.height * 0.54)
        ..lineTo(
            shoulder.dx - direction * size.width * 0.03, size.height * 0.48)
        ..close();
      canvas.drawPath(armPath, bodyPaint);

      final frontLeg = Path()
        ..moveTo(shoulder.dx + direction * size.width * 0.1, size.height * 0.62)
        ..lineTo(shoulder.dx + direction * size.width * 0.2, size.height * 0.8)
        ..lineTo(shoulder.dx + direction * size.width * 0.11, size.height * 0.8)
        ..lineTo(
            shoulder.dx + direction * size.width * 0.03, size.height * 0.67)
        ..close();
      canvas.drawPath(frontLeg, bodyPaint);

      final backLeg = Path()
        ..moveTo(
            shoulder.dx + direction * size.width * 0.02, size.height * 0.62)
        ..lineTo(
            shoulder.dx - direction * size.width * 0.11, size.height * 0.73)
        ..lineTo(shoulder.dx - direction * size.width * 0.06, size.height * 0.8)
        ..lineTo(
            shoulder.dx + direction * size.width * 0.08, size.height * 0.68)
        ..close();
      canvas.drawPath(backLeg, bodyPaint);
    }

    drawWrestler(left: true);
    drawWrestler(left: false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
