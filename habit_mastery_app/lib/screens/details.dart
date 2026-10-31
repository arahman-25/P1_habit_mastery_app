import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../models/habit_weekly_progress.dart';
import '../services/check_in_service.dart';
import '../services/habit_service.dart';
import '../services/service_exceptions.dart';
import '../utils/calendar_utils.dart';
import '../widgets/plant_display.dart';
import 'create_edit.dart';
import 'history.dart';

/// Screen 3: Detail / Activity
/// Focus screen for a specific habit's active weekly cycle.
///
/// Features:
/// - Hero plant visual and numeric completion rate.
/// - Weekly calendar cycle indicators (Monday..Sunday).
/// - Stateful cycle controls:
///   1. Check In Today (blocked if already checked in today).
///   2. Start / Reset View (transient view filter without altering SQLite history).
///   3. Finish Cycle (celebratory reward when weekly target is achieved).
/// - Quick navigation to History & Garden Guide or Edit Habit.
class Details extends StatefulWidget {
  final int habitId;

  const Details({super.key, required this.habitId});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final HabitService _habitService = HabitService.instance;
  final CheckInService _checkInService = CheckInService.instance;

  Habit? _habit;
  HabitWeeklyProgress? _weeklyProgress;
  bool _hasCheckedInToday = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Transient view filter state (Start / Reset View)
  bool _isPreviewFilterActive = false;

  @override
  void initState() {
    super.initState();
    _loadHabitData();
  }

  Future<void> _loadHabitData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final habit = await _habitService.getHabitById(widget.habitId);
      if (habit == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Habit #${widget.habitId} not found.';
          });
        }
        return;
      }

      final progress = await _habitService.getWeeklyProgress(widget.habitId);
      final checkedToday = await _checkInService.hasCheckedInToday(widget.habitId);

      if (mounted) {
        setState(() {
          _habit = habit;
          _weeklyProgress = progress;
          _hasCheckedInToday = checkedToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load habit details: $e';
        });
      }
    }
  }

  Future<void> _handleCheckInToday() async {
    if (_hasCheckedInToday || _habit == null) return;

    try {
      await _checkInService.checkInToday(widget.habitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(
              'Checked in today for "${_habit!.title}"! 🌱',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
      }
      await _loadHabitData();
    } on DuplicateCheckInException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: Text(
              'You have already checked in today.',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Check-in failed: $e', style: GoogleFonts.jetBrainsMono()),
          ),
        );
      }
    }
  }

  void _togglePreviewView() {
    setState(() {
      _isPreviewFilterActive = !_isPreviewFilterActive;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        backgroundColor: Colors.black87,
        content: Text(
          _isPreviewFilterActive
              ? 'Preview Mode Active: Focusing on completed days only.'
              : 'View Reset: Showing full calendar week.',
          style: GoogleFonts.jetBrainsMono(color: Colors.white),
        ),
      ),
    );
  }

  void _handleFinishCycle() {
    if (_weeklyProgress == null) return;

    final isMet = _weeklyProgress!.isGoalMet;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Row(
          children: [
            Icon(
              isMet ? Icons.emoji_events : Icons.info_outline,
              color: isMet ? Colors.amber.shade800 : Colors.green.shade800,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isMet ? 'Cycle Completed! 🌻' : 'Weekly Status',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMet
                  ? 'Congratulations! You reached ${_weeklyProgress!.completedDays}/${_weeklyProgress!.targetDays} target days this week! Your plant is flourishing.'
                  : 'You have completed ${_weeklyProgress!.completedDays} of ${_weeklyProgress!.targetDays} days so far this week. Remember: "Missed days are information, not failure."',
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Weekly cycle resets smoothly every Monday at 00:00.',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Growing', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          backgroundColor: Colors.greenAccent,
          title: Text('Cycle Details', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    if (_errorMessage != null || _habit == null || _weeklyProgress == null) {
      return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(backgroundColor: Colors.greenAccent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage ?? 'Unable to display details.',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final habit = _habit!;
    final progress = _weeklyProgress!;
    final clampedRate = progress.completionRate.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
        title: Text(
          habit.title,
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            tooltip: 'Edit Habit',
            onPressed: () async {
              final nav = Navigator.of(context);
              final result = await nav.push(
                MaterialPageRoute(builder: (context) => CreateEdit(habit: habit)),
              );
              if (result == 'deleted') {
                if (mounted) nav.pop();
              } else {
                _loadHabitData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Habit metadata chip and motivation
            _buildHeaderCard(habit),
            const SizedBox(height: 16),

            // Hero Plant Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  PlantDisplay(
                    plantTier: progress.plantTier,
                    plantStageName: progress.plantStageName,
                    completionRate: progress.completionRate,
                    completedDays: progress.completedDays,
                    targetDays: progress.targetDays,
                    size: 150,
                  ),
                  const SizedBox(height: 18),

                  // Linear progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: clampedRate,
                      minHeight: 12,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress.isGoalMet ? Colors.green.shade900 : Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Week of ${progress.weekStartLocalDate} to ${progress.weekEndLocalDate}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Week Day Checklist
            _buildWeekCalendarRow(progress),
            const SizedBox(height: 20),

            // Stateful Weekly Cycle Controls
            _buildCycleControlButtons(),
            const SizedBox(height: 24),

            // Bottom Actions (History & Insights)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => History(initialHabit: habit),
                  ),
                );
              },
              icon: const Icon(Icons.history, color: Colors.black),
              label: Text(
                'View History & Garden Guide',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Habit habit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black38, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  habit.category.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                'Started ${habit.startedLocalDate}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (habit.motivation != null && habit.motivation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“${habit.motivation!.trim()}”',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekCalendarRow(HabitWeeklyProgress progress) {
    final now = DateTime.now();
    final monday = CalendarUtils.getMondayOfWeek(now);
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black38, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE WEEK CALENDAR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              if (_isPreviewFilterActive)
                Text(
                  '(Filtered: Completed Only)',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.greenAccent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayDate = monday.add(Duration(days: i));
              final dayStr = CalendarUtils.formatLocalDate(dayDate);
              final isCompleted = progress.completedDates.contains(dayStr);
              final isToday = dayStr == CalendarUtils.formatLocalDate(now);

              if (_isPreviewFilterActive && !isCompleted) {
                return Opacity(
                  opacity: 0.25,
                  child: _buildDayDot(dayNames[i], dayDate.day, false, isToday),
                );
              }

              return _buildDayDot(dayNames[i], dayDate.day, isCompleted, isToday);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(String label, int dayNum, bool isCompleted, bool isToday) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.greenAccent
                : (isToday ? Colors.white24 : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? Colors.white : (isCompleted ? Colors.black : Colors.white38),
              width: isToday ? 2.0 : 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 20, color: Colors.black)
              : Text(
                  '$dayNum',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCycleControlButtons() {
    return Column(
      children: [
        // 1. Check In Today Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _hasCheckedInToday ? null : _handleCheckInToday,
            icon: Icon(
              _hasCheckedInToday ? Icons.check_circle : Icons.add_task,
              color: _hasCheckedInToday ? Colors.white70 : Colors.black,
            ),
            label: Text(
              _hasCheckedInToday ? 'Checked In Today ✓' : 'Check In Today',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _hasCheckedInToday ? Colors.white70 : Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasCheckedInToday ? Colors.green.shade900 : Colors.greenAccent,
              side: BorderSide(
                color: _hasCheckedInToday ? Colors.white38 : Colors.black,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2 & 3. Start / Reset View & Finish Cycle
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _togglePreviewView,
                icon: Icon(
                  _isPreviewFilterActive ? Icons.restore : Icons.visibility,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _isPreviewFilterActive ? 'Reset View' : 'Start / Filter',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleFinishCycle,
                icon: const Icon(Icons.celebration, size: 16, color: Colors.black),
                label: Text(
                  'Finish Cycle',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
