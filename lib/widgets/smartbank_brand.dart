import 'package:flutter/material.dart';

class SmartBankBrand extends StatelessWidget {
  final double iconSize;
  final bool showIcon;
  final bool lightText;

  const SmartBankBrand({
    super.key,
    this.iconSize = 42,
    this.showIcon = true,
    this.lightText = false,
  });

  static const Color blue = Color(0xFF0B5AA6);
  static const Color darkBlue = Color(0xFF06457E);
  static const Color yellow = Color(0xFFF4C542);

  @override
  Widget build(BuildContext context) {
    final textColor = lightText
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIcon) ...[
          _SmartBankIcon(size: iconSize),
          SizedBox(width: iconSize * 0.22),
        ],

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'S',
                style: TextStyle(
                  color: textColor,
                  fontSize: iconSize * 0.64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'mart',
                style: TextStyle(
                  color: textColor,
                  fontSize: iconSize * 0.47,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'B',
                style: TextStyle(
                  color: blue,
                  fontSize: iconSize * 0.64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'ank',
                style: TextStyle(
                  color: textColor,
                  fontSize: iconSize * 0.47,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ============================================================
// SMARTBANK CUSTOM ICON
// ============================================================

class _SmartBankIcon extends StatelessWidget {
  final double size;

  const _SmartBankIcon({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --------------------------------------------------
          // Fond principal
          // --------------------------------------------------
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SmartBankBrand.blue,
                  SmartBankBrand.darkBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.27),
              boxShadow: [
                BoxShadow(
                  color: SmartBankBrand.blue.withValues(alpha: 0.22),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.09),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // Toit / symbole banque
          // --------------------------------------------------
          Positioned(
            top: size * 0.20,
            left: size * 0.20,
            right: size * 0.20,
            child: CustomPaint(
              size: Size(size * 0.60, size * 0.25),
              painter: _BankRoofPainter(),
            ),
          ),

          // --------------------------------------------------
          // Colonnes
          // --------------------------------------------------
          Positioned(
            left: size * 0.25,
            bottom: size * 0.20,
            child: Row(
              children: [
                _column(size),
                SizedBox(width: size * 0.075),
                _column(size),
                SizedBox(width: size * 0.075),
                _column(size),
              ],
            ),
          ),

          // --------------------------------------------------
          // Ligne inférieure
          // --------------------------------------------------
          Positioned(
            left: size * 0.20,
            right: size * 0.20,
            bottom: size * 0.16,
            child: Container(
              height: size * 0.055,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),

          // --------------------------------------------------
          // Accent jaune
          // --------------------------------------------------
          Positioned(
            right: size * 0.12,
            top: size * 0.10,
            child: Container(
              width: size * 0.19,
              height: size * 0.19,
              decoration: const BoxDecoration(
                color: SmartBankBrand.yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(double size) {
    return Container(
      width: size * 0.09,
      height: size * 0.27,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.02),
      ),
    );
  }
}


// ============================================================
// TOIT DE LA BANQUE
// ============================================================

class _BankRoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(size.width * 0.50, 0);

    path.lineTo(size.width, size.height * 0.72);

    path.lineTo(0, size.height * 0.72);

    path.close();

    canvas.drawPath(path, paint);

    // Ligne horizontale sous le toit
    final linePaint = Paint()
      ..color = SmartBankBrand.blue
      ..strokeWidth = size.height * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.88, size.height * 0.72),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}