import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a dynamic plant illustration reflecting the habit's derived completion tier:
/// - Tier 0: Seed in soil (0%)
/// - Tier 1: Sprout (1% – 49%)
/// - Tier 2: Growing bud (50% – 99%)
/// - Tier 3: Full bloom (>= 100%)
///
/// Accessibility Rule (AGENTS.md Section 5):
/// The widget ALWAYS displays the numeric progress string (e.g. "3/4 days (75%)")
/// and stage name so understanding progress never relies solely on visuals.
class PlantDisplay extends StatelessWidget {
  final int plantTier;
  final String plantStageName;
  final double completionRate;
  final int completedDays;
  final int targetDays;
  final double size;
  final bool showLabel;
  final bool compact;

  const PlantDisplay({
    super.key,
    required this.plantTier,
    required this.plantStageName,
    required this.completionRate,
    required this.completedDays,
    required this.targetDays,
    this.size = 160,
    this.showLabel = true,
    this.compact = false,
  });

  String get displayProgress {
    final percent = (completionRate * 100).round();
    return '$completedDays/$targetDays days ($percent%)';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = compact ? (size > 80 ? 60.0 : size) : size;
    final clampedTier = plantTier.clamp(0, 3);

    return Semantics(
      label: 'Plant stage: $plantStageName, progress $displayProgress',
      child: compact
          ? _buildCompactLayout(context, effectiveSize, clampedTier)
          : _buildStandardLayout(context, effectiveSize, clampedTier),
    );
  }

  Widget _buildCompactLayout(BuildContext context, double boxSize, int tier) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: CustomPaint(
        size: Size(boxSize, boxSize),
        painter: PlantPainter(tier: tier),
      ),
    );
  }

  Widget _buildStandardLayout(BuildContext context, double boxSize, int tier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(boxSize, boxSize),
            painter: PlantPainter(tier: tier),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 12),
          Text(
            plantStageName,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Text(
              displayProgress,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom vector painter rendering the 4 growth tiers accurately across screen sizes.
class PlantPainter extends CustomPainter {
  final int tier;

  PlantPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw soil mound at the base
    final soilPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.fill;

    final soilBorderPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.02);

    final soilPath = Path()
      ..moveTo(w * 0.2, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.72, w * 0.8, h * 0.82)
      ..lineTo(w * 0.8, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.2, h * 0.88)
      ..close();

    canvas.drawPath(soilPath, soilPaint);
    canvas.drawPath(soilPath, soilBorderPaint);

    // Small soil texture speckles
    final specklePaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.82), w * 0.02, specklePaint);
    canvas.drawCircle(Offset(w * 0.55, h * 0.83), w * 0.018, specklePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.81), w * 0.02, specklePaint);

    switch (tier) {
      case 0:
        _drawSeed(canvas, w, h);
        break;
      case 1:
        _drawSprout(canvas, w, h);
        break;
      case 2:
        _drawGrowingBud(canvas, w, h);
        break;
      case 3:
      default:
        _drawFullBloom(canvas, w, h);
        break;
    }
  }

  void _drawSeed(Canvas canvas, double w, double h) {
    final seedPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..style = PaintingStyle.fill;
    final seedStroke = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.025);

    canvas.save();
    canvas.translate(w * 0.5, h * 0.76);
    canvas.rotate(-0.25);
    final rotatedRect = Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: w * 0.22);
    canvas.drawOval(rotatedRect, seedPaint);
    canvas.drawOval(rotatedRect, seedStroke);
    canvas.restore();
  }

  void _drawSprout(Canvas canvas, double w, double h) {
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.5, w * 0.04);

    // Stem rising
    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.75)
      ..quadraticBezierTo(w * 0.49, h * 0.60, w * 0.5, h * 0.48);
    canvas.drawPath(stemPath, stemPaint);

    // Left leaf
    final leafPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    final leafBorder = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final leftLeaf = Path()
      ..moveTo(w * 0.5, h * 0.50)
      ..cubicTo(w * 0.35, h * 0.48, w * 0.28, h * 0.40, w * 0.35, h * 0.35)
      ..cubicTo(w * 0.45, h * 0.35, w * 0.48, h * 0.45, w * 0.5, h * 0.50);
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(leftLeaf, leafBorder);

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.5, h * 0.48)
      ..cubicTo(w * 0.65, h * 0.46, w * 0.72, h * 0.38, w * 0.65, h * 0.33)
      ..cubicTo(w * 0.55, h * 0.33, w * 0.52, h * 0.43, w * 0.5, h * 0.48);
    canvas.drawPath(rightLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafBorder);
  }

  void _drawGrowingBud(Canvas canvas, double w, double h) {
    final stemPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(3.0, w * 0.045);

    // Taller stem
    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.75)
      ..cubicTo(w * 0.48, h * 0.58, w * 0.52, h * 0.45, w * 0.5, h * 0.32);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final leafBorder = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Lower left leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.49, h * 0.60)
      ..cubicTo(w * 0.30, h * 0.62, w * 0.24, h * 0.52, w * 0.32, h * 0.46)
      ..cubicTo(w * 0.42, h * 0.48, w * 0.47, h * 0.56, w * 0.49, h * 0.60);
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(leftLeaf, leafBorder);

    // Mid right leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.48)
      ..cubicTo(w * 0.70, h * 0.50, w * 0.76, h * 0.40, w * 0.68, h * 0.34)
      ..cubicTo(w * 0.58, h * 0.36, w * 0.53, h * 0.44, w * 0.51, h * 0.48);
    canvas.drawPath(rightLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafBorder);

    // Top bud (swollen flower bud preparing to open)
    final budPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;
    final budPetalPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    final budBorder = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Golden petal tip poking through
    final tipPath = Path()
      ..moveTo(w * 0.47, h * 0.28)
      ..quadraticBezierTo(w * 0.5, h * 0.22, w * 0.53, h * 0.28)
      ..close();
    canvas.drawPath(tipPath, budPetalPaint);

    // Calyx / sepals
    final calyxPath = Path()
      ..moveTo(w * 0.44, h * 0.33)
      ..cubicTo(w * 0.44, h * 0.26, w * 0.56, h * 0.26, w * 0.56, h * 0.33)
      ..quadraticBezierTo(w * 0.5, h * 0.36, w * 0.44, h * 0.33);
    canvas.drawPath(calyxPath, budPaint);
    canvas.drawPath(calyxPath, budBorder);
  }

  void _drawFullBloom(Canvas canvas, double w, double h) {
    final stemPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(3.5, w * 0.05);

    // Strong, full stem
    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.75)
      ..cubicTo(w * 0.48, h * 0.60, w * 0.52, h * 0.46, w * 0.5, h * 0.36);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;
    final leafBorder = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left full leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.49, h * 0.58)
      ..cubicTo(w * 0.26, h * 0.62, w * 0.20, h * 0.48, w * 0.30, h * 0.42)
      ..cubicTo(w * 0.40, h * 0.44, w * 0.47, h * 0.53, w * 0.49, h * 0.58);
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(leftLeaf, leafBorder);

    // Right full leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.50)
      ..cubicTo(w * 0.74, h * 0.54, w * 0.80, h * 0.40, w * 0.70, h * 0.34)
      ..cubicTo(w * 0.60, h * 0.36, w * 0.53, h * 0.45, w * 0.51, h * 0.50);
    canvas.drawPath(rightLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafBorder);

    // Full Bloom Flower Head
    final flowerCenter = Offset(w * 0.5, h * 0.26);
    final petalRadius = w * 0.12;

    final petalPaint = Paint()
      ..color = const Color(0xFFFFCA28) // Bright golden sunflower / bloom
      ..style = PaintingStyle.fill;
    final petalBorder = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 8 round petals radiating around center
    const numPetals = 8;
    for (int i = 0; i < numPetals; i++) {
      final angle = (i * 2 * math.pi) / numPetals;
      final petalCenter = Offset(
        flowerCenter.dx + math.cos(angle) * (petalRadius * 0.85),
        flowerCenter.dy + math.sin(angle) * (petalRadius * 0.85),
      );
      canvas.drawCircle(petalCenter, petalRadius * 0.6, petalPaint);
      canvas.drawCircle(petalCenter, petalRadius * 0.6, petalBorder);
    }

    // Central flower disc
    final discPaint = Paint()
      ..color = const Color(0xFFFF7043)
      ..style = PaintingStyle.fill;
    final discBorder = Paint()
      ..color = const Color(0xFFBF360C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(flowerCenter, petalRadius * 0.7, discPaint);
    canvas.drawCircle(flowerCenter, petalRadius * 0.7, discBorder);

    // Little sparkles / pollen dots for celebration
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.24, h * 0.18), w * 0.02, sparkPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.16), w * 0.025, sparkPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.28), w * 0.018, sparkPaint);
  }

  @override
  bool shouldRepaint(covariant PlantPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}
