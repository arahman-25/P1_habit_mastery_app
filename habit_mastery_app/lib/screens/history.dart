import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import '../services/check_in_service.dart';
import '../services/garden_guide.dart';
import '../services/habit_service.dart';
import '../services/service_exceptions.dart';
import '../utils/calendar_utils.dart';
import '../widgets/garden_guide_card.dart';

/// Screen 4: History / Check-in Journal & Insights
///
/// Features:
/// - Habit selector dropdown (or displays focused habit).
/// - Garden Guide smart helper card (rule-based target estimation with "Apply Suggestion").
/// - Historical weekly completion rate summary.
/// - Full CRUD over past check-ins:
///   1. List of past check-ins (date + note).
///   2. Add past check-in (restricted: >= habit.startedLocalDate and <= today; no duplicates).
///   3. Edit check-in (modify date and note with boundary & duplicate checks).
///   4. Delete check-in with confirmation dialog.
class History extends StatefulWidget {
  final Habit? initialHabit;

  const History({super.key, this.initialHabit});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final HabitService _habitService = HabitService.instance;
  final CheckInService _checkInService = CheckInService.instance;

  List<Habit> _habits = [];
  Habit? _selectedHabit;
  List<CheckIn> _checkIns = [];
  GardenGuideRecommendation? _recommendation;
  List<int> _completedWeekCounts = [];

  bool _isLoading = true;
  bool _isApplyingSuggestion = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final habits = await _habitService.getAllHabits();
      Habit? current;

      if (widget.initialHabit != null) {
        current = habits.firstWhere(
          (h) => h.id == widget.initialHabit!.id,
          orElse: () => widget.initialHabit!,
        );
      } else if (habits.isNotEmpty) {
        current = habits.first;
      }

      _habits = habits;
      _selectedHabit = current;

      if (current != null) {
        await _loadHabitDetails(current);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load habits: $e';
        });
      }
    }
  }

  Future<void> _loadHabitDetails(Habit habit) async {
    try {
      final checkIns = await _checkInService.getCheckInsForHabit(habit.id!);
      final counts = await _checkInService.getPastCompletedWeeksCheckInCounts(
        habit,
        weekCount: 3,
      );
      final recommendation = await GardenGuide.evaluateForHabit(
        habit: habit,
        checkInService: _checkInService,
      );

      if (mounted) {
        setState(() {
          _selectedHabit = habit;
          _checkIns = checkIns;
          _completedWeekCounts = counts;
          _recommendation = recommendation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load habit history: $e';
        });
      }
    }
  }

  Future<void> _handleApplySuggestion() async {
    if (_selectedHabit == null ||
        _recommendation == null ||
        _recommendation!.suggestedTarget == null) {
      return;
    }

    final newTarget = _recommendation!.suggestedTarget!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Text(
          'Apply Suggested Target?',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Update weekly target for "${_selectedHabit!.title}" from ${_selectedHabit!.weeklyTarget} to $newTarget days per week?\n\nThis will take effect immediately.',
          style: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.jetBrainsMono(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apply Target', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isApplyingSuggestion = true);
      try {
        final updatedHabit = _selectedHabit!.copyWith(weeklyTarget: newTarget);
        final saved = await _habitService.updateHabit(updatedHabit);

        // Update in habit list
        final index = _habits.indexWhere((h) => h.id == saved.id);
        if (index != -1) {
          _habits[index] = saved;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              content: Text(
                'Weekly target updated to $newTarget days! 🌿',
                style: GoogleFonts.jetBrainsMono(color: Colors.white),
              ),
            ),
          );
        }
        await _loadHabitDetails(saved);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Failed to update target: $e', style: GoogleFonts.jetBrainsMono()),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isApplyingSuggestion = false);
      }
    }
  }

  // --- Check-In CRUD Operations ---

  Future<void> _showAddCheckInDialog() async {
    if (_selectedHabit == null) return;
    final habit = _selectedHabit!;

    final now = DateTime.now();
    DateTime selectedDate = now;
    final noteController = TextEditingController();

    final habitStartDate = CalendarUtils.isValidLocalDate(habit.startedLocalDate)
        ? CalendarUtils.parseLocalDate(habit.startedLocalDate)
        : DateTime(2020);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            title: Text(
              'Add Past Check-in',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Habit: ${habit.title}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Picker Button
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: habitStartDate,
                          lastDate: now,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black54),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CalendarUtils.formatLocalDate(selectedDate),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Note
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      style: GoogleFonts.jetBrainsMono(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        hintText: 'Note / Reflection (optional)',
                        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: GoogleFonts.jetBrainsMono(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(dialogCtx);
                  final dateStr = CalendarUtils.formatLocalDate(selectedDate);
                  try {
                    await _checkInService.createCheckIn(CheckIn(
                      habitId: habit.id!,
                      localDate: dateStr,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    ));

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade800,
                        content: Text(
                          'Recorded check-in for $dateStr!',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white),
                        ),
                      ),
                    );
                    await _loadHabitDetails(habit);
                  } on DuplicateCheckInException {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.orange.shade800,
                        content: Text(
                          'A check-in already exists on $dateStr.',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white),
                        ),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Failed: $e', style: GoogleFonts.jetBrainsMono()),
                      ),
                    );
                  }
                },
                child: Text('Save', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditCheckInDialog(CheckIn checkIn) async {
    if (_selectedHabit == null) return;
    final habit = _selectedHabit!;

    final now = DateTime.now();
    DateTime selectedDate = CalendarUtils.parseLocalDate(checkIn.localDate);
    final noteController = TextEditingController(text: checkIn.note ?? '');

    final habitStartDate = CalendarUtils.isValidLocalDate(habit.startedLocalDate)
        ? CalendarUtils.parseLocalDate(habit.startedLocalDate)
        : DateTime(2020);

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            title: Text(
              'Edit Check-in',
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Habit: ${habit.title}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date Picker Button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: habitStartDate,
                        lastDate: now,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black54),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CalendarUtils.formatLocalDate(selectedDate),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note text field
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    style: GoogleFonts.jetBrainsMono(fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: 'Note / Reflection',
                      hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: GoogleFonts.jetBrainsMono(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(dialogCtx);
                  final dateStr = CalendarUtils.formatLocalDate(selectedDate);
                  try {
                    await _checkInService.updateCheckIn(checkIn.copyWith(
                      localDate: dateStr,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    ));

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade800,
                        content: Text(
                          'Check-in updated for $dateStr!',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white),
                        ),
                      ),
                    );
                    await _loadHabitDetails(habit);
                  } on DuplicateCheckInException {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.orange.shade800,
                        content: Text(
                          'Another check-in exists on $dateStr.',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white),
                        ),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Update failed: $e', style: GoogleFonts.jetBrainsMono()),
                      ),
                    );
                  }
                },
                child: Text('Update', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteCheckIn(CheckIn checkIn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Text(
          'Delete Check-in?',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove the check-in for ${checkIn.localDate}?',
          style: GoogleFonts.jetBrainsMono(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.jetBrainsMono(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && checkIn.id != null) {
      try {
        await _checkInService.deleteCheckIn(checkIn.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black87,
              content: Text(
                'Check-in removed.',
                style: GoogleFonts.jetBrainsMono(color: Colors.white),
              ),
            ),
          );
        }
        await _loadHabitDetails(_selectedHabit!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Delete failed: $e', style: GoogleFonts.jetBrainsMono()),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF17231B)
          : Colors.green,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF83C991)
            : Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
        title: Text(
          'History & Insights',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: _selectedHabit != null
          ? FloatingActionButton.extended(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Add Check-in',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
              ),
              onPressed: _showAddCheckInDialog,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.jetBrainsMono(color: Colors.white),
          ),
        ),
      );
    }

    if (_habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 60, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                'No Habits Found',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plant your first habit to start recording check-in reflections and unlocking Garden Guide suggestions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: [
        // 1. Habit Selector Dropdown
        _buildHabitSelector(),

        // 2. Garden Guide Recommendation Card
        if (_recommendation != null) ...[
          const SizedBox(height: 8),
          GardenGuideCard(
            recommendation: _recommendation!,
            isApplying: _isApplyingSuggestion,
            onApplySuggestion: _handleApplySuggestion,
          ),
        ],

        // 3. Historical Weekly Performance Summary
        if (_completedWeekCounts.isNotEmpty && _selectedHabit != null)
          _buildWeeklyHistorySummary(),

        // 4. Check-In Journal Header & List
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHECK-IN JOURNAL (${_checkIns.length})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              Text(
                'Tap to edit',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        if (_checkIns.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade800.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
            ),
            child: Text(
              'No check-ins recorded yet for this habit. Tap "+ Add Check-in" below or complete one on the Dashboard.',
              style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._checkIns.map((ci) => _buildCheckInTile(ci)),
      ],
    );
  }

  Widget _buildHabitSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.greenAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.spa, color: Colors.black87, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedHabit?.id,
                isExpanded: true,
                dropdownColor: Colors.greenAccent,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                items: _habits.map((h) {
                  return DropdownMenuItem<int>(
                    value: h.id,
                    child: Text(
                      '${h.title} (${h.category})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    final selected = _habits.firstWhere((h) => h.id == newId);
                    setState(() => _selectedHabit = selected);
                    _loadHabitDetails(selected);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHistorySummary() {
    final target = _selectedHabit!.weeklyTarget;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAST COMPLETED WEEKS HISTORY',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_completedWeekCounts.length, (i) {
              final count = _completedWeekCounts[i];
              final rate = target > 0 ? (count / target) : 0.0;
              final percent = (rate * 100).round();
              final isMet = count >= target;

              return Column(
                children: [
                  Text(
                    'Week -${_completedWeekCounts.length - i}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMet ? Colors.greenAccent : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black87),
                    ),
                    child: Text(
                      '$count/$target d ($percent%)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInTile(CheckIn checkIn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => _showEditCheckInDialog(checkIn),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87),
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.black),
          ),
          title: Text(
            checkIn.localDate,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: (checkIn.note != null && checkIn.note!.trim().isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    checkIn.note!.trim(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Delete Check-in',
            onPressed: () => _handleDeleteCheckIn(checkIn),
          ),
        ),
      ),
    );
  }
}
