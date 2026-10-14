import 'package:flutter/material.dart';

class RealClapperboardSticksPainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;
  final double stripeWidth;

  RealClapperboardSticksPainter({
    this.darkColor = const Color(0xFF111118),
    this.lightColor = const Color(0xFFF6F6FC),
    this.stripeWidth = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double halfHeight = size.height / 2;

    final bgPaint = Paint()..color = darkColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, halfHeight - 0.5), bgPaint);
    canvas.drawRect(Rect.fromLTWH(0, halfHeight + 0.5, size.width, halfHeight - 0.5), bgPaint);

    final stripePaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    double step = stripeWidth * 2;
    double offset = 8.0;

    for (double x = -size.height * 2; x < size.width + size.height * 2; x += step) {
      final topPath = Path()
        ..moveTo(x, halfHeight - 0.5)
        ..lineTo(x + stripeWidth, halfHeight - 0.5)
        ..lineTo(x + stripeWidth - offset, 0)
        ..lineTo(x - offset, 0)
        ..close();
      canvas.drawPath(topPath, stripePaint);

      final bottomPath = Path()
        ..moveTo(x, halfHeight + 0.5)
        ..lineTo(x + stripeWidth, halfHeight + 0.5)
        ..lineTo(x + stripeWidth - offset, size.height)
        ..lineTo(x - offset, size.height)
        ..close();
      canvas.drawPath(bottomPath, stripePaint);
    }

    final seamPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, halfHeight), Offset(size.width, halfHeight), seamPaint);

    final hingeRect = Rect.fromLTWH(0, 0, 24, size.height);
    final hingePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E8EA0), Color(0xFFD0D0E2), Color(0xFF6E6E80)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(hingeRect);
    canvas.drawRRect(RRect.fromRectAndRadius(hingeRect, const Radius.circular(3)), hingePaint);

    final rivetPaint = Paint()..color = const Color(0xFF2C2C3A);
    final rivetCenterPaint = Paint()..color = const Color(0xFFE5E5F0);
    canvas.drawCircle(Offset(12, halfHeight / 2), 3, rivetPaint);
    canvas.drawCircle(Offset(12, halfHeight / 2), 1, rivetCenterPaint);
    canvas.drawCircle(Offset(12, halfHeight + halfHeight / 2), 3, rivetPaint);
    canvas.drawCircle(Offset(12, halfHeight + halfHeight / 2), 1, rivetCenterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClapperboardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onOpenSettings;
  final bool showSettings;
  final String sceneNumber;
  final String takeNumber;

  const ClapperboardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onOpenSettings,
    this.showSettings = true,
    this.sceneNumber = '01',
    this.takeNumber = '4K',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: RealClapperboardSticksPainter(
                darkColor: const Color(0xFF0F0F16),
                lightColor: const Color(0xFFF2F2FC),
                stripeWidth: 16,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                ...?actions,

                if (showSettings && onOpenSettings != null)
                  IconButton(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                    tooltip: 'Paramètres',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
