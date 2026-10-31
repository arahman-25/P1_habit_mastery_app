import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_weekly_progress.dart';
import 'plant_display.dart';

/// Reusable StatelessWidget garden tile representing a habit on the Dashboard.
///
/// Displays:
/// - Habit title
/// - Category chip
/// - Plant illustration reflecting derived tier
/// - Numeric completion rate: "X/Y days (Z%)"
/// - Linear progress bar
/// - Quick "Check In Today" action
class HabitCard extends StatelessWidget {
  final HabitWeeklyProgress progress;
  final VoidCallback onTap;
  final VoidCallback? onQuickCheckIn;
  final bool isCheckedInToday;

  const HabitCard({
    super.key,
    required this.progress,
    required this.onTap,
    this.onQuickCheckIn,
    this.isCheckedInToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final habit = progress.habit;
    final clampedRate = progress.completionRate.clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with category chip and plant thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black45, width: 0.8),
                        ),
                        child: Text(
                          habit.category.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        habit.title,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (habit.motivation != null && habit.motivation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“${habit.motivation!.trim()}”',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PlantDisplay(
                  plantTier: progress.plantTier,
                  plantStageName: progress.plantStageName,
                  completionRate: progress.completionRate,
                  completedDays: progress.completedDays,
                  targetDays: progress.targetDays,
                  size: 58,
                  compact: true,
                  showLabel: false,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar and rate text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.displayProgress,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  progress.plantStageName,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: clampedRate,
                minHeight: 10,
                backgroundColor: Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress.isGoalMet ? Colors.green.shade800 : Colors.green.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick action button / status
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCheckedInToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Checked In Today',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (onQuickCheckIn != null)
                  ElevatedButton.icon(
                    onPressed: onQuickCheckIn,
                    icon: const Icon(Icons.check, size: 16, color: Colors.black),
                    label: Text(
                      'Check In Today',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      elevation: 1,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
