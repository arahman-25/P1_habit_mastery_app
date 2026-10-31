import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/service_exceptions.dart';
import '../services/settings_service.dart';
import '../utils/calendar_utils.dart';

/// Screen 2: Create / Edit Habit
/// Provides a validated form to create a new habit or edit an existing one.
///
/// Invariants enforced:
/// - Title is required and non-empty.
/// - Weekly target is clamped between 1 and 7.
/// - Start date cannot be in the future (startedLocalDate <= today).
/// - If editing, start date cannot be moved past existing check-in dates.
/// - Deleting prompts for confirmation and cascade deletes all check-ins.
class CreateEdit extends StatefulWidget {
  final Habit? habit;

  const CreateEdit({super.key, this.habit});

  bool get isEditMode => habit != null;

  @override
  State<CreateEdit> createState() => _CreateEditState();
}

class _CreateEditState extends State<CreateEdit> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _motivationController = TextEditingController();

  final HabitService _habitService = HabitService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  static const List<String> _categoryOptions = [
    'Study',
    'Health',
    'Creative',
    'Mindfulness',
    'General',
  ];

  late String _selectedCategory;
  double _weeklyTarget = 5.0;
  late String _startedLocalDate;
  bool _isLoading = false;
  bool _hasModified = false;

  @override
  void initState() {
    super.initState();
    final today = CalendarUtils.formatLocalDate(DateTime.now());

    if (widget.isEditMode) {
      final h = widget.habit!;
      _titleController.text = h.title;
      _motivationController.text = h.motivation ?? '';
      _selectedCategory = _categoryOptions.firstWhere(
        (c) => c.toLowerCase() == h.category.toLowerCase(),
        orElse: () => h.category.isNotEmpty ? h.category : 'General',
      );
      _weeklyTarget = h.weeklyTarget.toDouble().clamp(1.0, 7.0);
      _startedLocalDate = h.startedLocalDate;
    } else {
      _selectedCategory = 'Study';
      _startedLocalDate = today;
      _loadDefaultSettingsTarget();
    }

    _titleController.addListener(_markModified);
    _motivationController.addListener(_markModified);
  }

  void _markModified() {
    if (!_hasModified) {
      setState(() => _hasModified = true);
    }
  }

  Future<void> _loadDefaultSettingsTarget() async {
    try {
      final settings = await _settingsService.loadSettings();
      if (mounted && !widget.isEditMode) {
        setState(() {
          _weeklyTarget = settings.weeklyGoal.toDouble().clamp(1.0, 7.0);
        });
      }
    } catch (_) {
      // Default to 5 if settings fail to load
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final currentParsed = CalendarUtils.isValidLocalDate(_startedLocalDate)
        ? CalendarUtils.parseLocalDate(_startedLocalDate)
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentParsed.isAfter(now) ? now : currentParsed,
      firstDate: DateTime(2020),
      lastDate: now, // Future dates disallowed per AGENTS.md Section 4
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = CalendarUtils.formatLocalDate(picked);
      if (formatted != _startedLocalDate) {
        setState(() {
          _startedLocalDate = formatted;
          _hasModified = true;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasModified) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Text(
          'Discard Changes?',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: GoogleFonts.jetBrainsMono(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Editing', style: GoogleFonts.jetBrainsMono(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final habitData = Habit(
        id: widget.habit?.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        weeklyTarget: _weeklyTarget.round().clamp(1, 7),
        startedLocalDate: _startedLocalDate,
        motivation: _motivationController.text.trim().isEmpty
            ? null
            : _motivationController.text.trim(),
      );

      final Habit saved;
      if (widget.isEditMode) {
        saved = await _habitService.updateHabit(habitData);
      } else {
        saved = await _habitService.createHabit(habitData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(
              widget.isEditMode
                  ? 'Habit "${saved.title}" updated!'
                  : 'Planted "${saved.title}"! 🌱',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context, saved);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              e.message,
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
            content: Text(
              'Save failed: $e',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!widget.isEditMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        title: Text(
          'Delete Habit?',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text(
          'Deleting "${widget.habit!.title}" will permanently remove all associated check-in records. This cannot be undone.',
          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.black87),
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
            child: Text('Delete Habit', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _habitService.deleteHabit(widget.habit!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black87,
              content: Text(
                'Habit removed.',
                style: GoogleFonts.jetBrainsMono(color: Colors.white),
              ),
            ),
          );
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Failed to delete: $e', style: GoogleFonts.jetBrainsMono()),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          backgroundColor: Colors.greenAccent,
          shadowColor: Colors.black,
          elevation: 3,
          title: Text(
            widget.isEditMode ? 'Edit Habit' : 'Plant Habit',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            if (widget.isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Habit',
                onPressed: _isLoading ? null : _handleDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Habit Title
                _buildFieldCard(
                  label: 'HABIT TITLE *',
                  child: TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.jetBrainsMono(fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g. Daily Reading, Morning Jog',
                      hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Habit title is required.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Category Selector
                _buildFieldCard(
                  label: 'CATEGORY',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryOptions.map((cat) {
                      final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        ),
                        labelStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        selected: isSelected,
                        selectedColor: Colors.greenAccent,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? Colors.black : Colors.black26,
                          width: isSelected ? 1.5 : 1,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _hasModified = true;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Weekly Target Slider (1..7 days)
                _buildFieldCard(
                  label: 'WEEKLY TARGET: ${_weeklyTarget.toInt()} DAYS / WEEK',
                  child: Column(
                    children: [
                      Slider(
                        value: _weeklyTarget,
                        min: 1,
                        max: 7,
                        divisions: 6,
                        activeColor: Colors.green.shade800,
                        inactiveColor: Colors.black26,
                        label: '${_weeklyTarget.toInt()} days',
                        onChanged: (val) {
                          setState(() {
                            _weeklyTarget = val;
                            _hasModified = true;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            final isCurrent = day == _weeklyTarget.toInt();
                            return Text(
                              '$day',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? Colors.green.shade900 : Colors.black45,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Start Date Picker
                _buildFieldCard(
                  label: 'START DATE',
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.black54),
                          const SizedBox(width: 12),
                          Text(
                            _startedLocalDate,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Change',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Motivation Note
                _buildFieldCard(
                  label: 'MOTIVATION NOTE (OPTIONAL)',
                  child: TextFormField(
                    controller: _motivationController,
                    maxLines: 3,
                    style: GoogleFonts.jetBrainsMono(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g. Build steady focus without burning out.',
                      hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          widget.isEditMode ? 'Update Habit' : 'Plant Habit 🌱',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black45, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
