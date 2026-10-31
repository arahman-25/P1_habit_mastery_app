import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/garden_guide.dart';

/// Rule-based recommendation card for the Garden Guide smart helper.
///
/// Features:
/// - Honest labeling as a rule-based algorithm (per AGENTS.md Section 7).
/// - Transparent rationale based on the average of the last 3 completed weeks.
/// - Explicit "Apply Suggestion" button that requires user confirmation.
/// - Supportive, non-judgmental messaging ("Missed days are information, not failure").
class GardenGuideCard extends StatelessWidget {
  final GardenGuideRecommendation recommendation;
  final VoidCallback? onApplySuggestion;
  final bool isApplying;

  const GardenGuideCard({
    super.key,
    required this.recommendation,
    this.onApplySuggestion,
    this.isApplying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Gentle soft green
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade800, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner with leaf icon and algorithm label
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green.shade800, size: 22),
              const SizedBox(width: 8),
              Text(
                'GARDEN GUIDE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.green.shade900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade700, width: 0.8),
                ),
                child: Text(
                  'Rule-Based Algorithm',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Headline
          Text(
            recommendation.headline,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),

          // Rationale
          Text(
            recommendation.rationale,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Weekly history pills if available
          if (recommendation.completedWeekCounts.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Past 3 full weeks: ',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                for (int i = 0; i < recommendation.completedWeekCounts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Text(
                      '${recommendation.completedWeekCounts[i]}d',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action row if suggestion differs from current target
          if (recommendation.shouldSuggestChange) ...[
            const Divider(color: Colors.black12),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target adjustment:',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${recommendation.currentTarget} → ${recommendation.suggestedTarget} days / week',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: isApplying ? null : onApplySuggestion,
                  icon: isApplying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(
                    'Apply Suggestion',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.green.shade900, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
