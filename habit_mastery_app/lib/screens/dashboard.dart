import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_weekly_progress.dart';
import '../services/check_in_service.dart';
import '../services/habit_service.dart';
import '../services/service_exceptions.dart';
import '../widgets/habit_card.dart';
import 'create_edit.dart';
import 'details.dart';
import 'settings.dart';

/// Screen 1: Catalog / Dashboard
/// Displays the user's habit garden, category filter bar, weekly completion rates,
/// dynamic plant visual states, and quick-check-in shortcuts.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final HabitService _habitService = HabitService.instance;
  final CheckInService _checkInService = CheckInService.instance;

  static const List<String> _categories = [
    'All',
    'Study',
    'Health',
    'Creative',
    'Mindfulness',
  ];

  String _selectedCategory = 'All';
  List<HabitWeeklyProgress> _allProgressList = [];
  Map<int, bool> _todayCheckInStatus = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progressList = await _habitService.getAllHabitsWeeklyProgress();
      final Map<int, bool> statusMap = {};
      for (final p in progressList) {
        if (p.habit.id != null) {
          final hasChecked = await _checkInService.hasCheckedInToday(p.habit.id!);
          statusMap[p.habit.id!] = hasChecked;
        }
      }

      if (mounted) {
        setState(() {
          _allProgressList = progressList;
          _todayCheckInStatus = statusMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load habit garden: $e';
        });
      }
    }
  }

  List<HabitWeeklyProgress> get _filteredProgressList {
    if (_selectedCategory == 'All') {
      return _allProgressList;
    }
    return _allProgressList
        .where((p) => p.habit.category.trim().toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  Future<void> _handleQuickCheckIn(HabitWeeklyProgress progress) async {
    final habitId = progress.habit.id;
    if (habitId == null) return;

    try {
      await _checkInService.checkInToday(habitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
            content: Text(
              'Checked in for "${progress.habit.title}"! 🌱',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
      }
      await _loadHabits();
    } on DuplicateCheckInException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: Text(
              'Already checked in today for "${progress.habit.title}".',
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
              'Check-in failed: $e',
              style: GoogleFonts.jetBrainsMono(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProgressList;

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
        title: Text(
          'Habit Garden',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: const [
          SettingButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        icon: const Icon(Icons.add),
        label: Text(
          'Plant Habit',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEdit()),
          );
          _loadHabits();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadHabits,
        color: Colors.greenAccent,
        backgroundColor: Colors.black87,
        child: Column(
          children: [
            // Category Filter Bar
            _buildCategoryFilter(),

            // Content body
            Expanded(
              child: _buildBody(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.green.shade800.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  category,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
                labelStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                selected: isSelected,
                selectedColor: Colors.greenAccent,
                backgroundColor: Colors.green.shade900,
                side: BorderSide(
                  color: isSelected ? Colors.black : Colors.white38,
                  width: 1,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(List<HabitWeeklyProgress> filtered) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHabits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                child: Text('Retry', style: GoogleFonts.jetBrainsMono()),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state 1: No habits at all in the database
    if (_allProgressList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grass, size: 64, color: Colors.greenAccent),
              ),
              const SizedBox(height: 16),
              Text(
                'Your garden is empty',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '“Grow a routine. Not a guilt trip.”\nPlant your first habit to begin nurturing your momentum.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateEdit()),
                  );
                  _loadHabits();
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(
                  'Plant Your First Habit',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state 2: Habits exist, but none match the category filter
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt_off, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                'No habits in "$_selectedCategory"',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try selecting another category filter or add a habit under $_selectedCategory.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List of HabitCards
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final progress = filtered[index];
        final habitId = progress.habit.id;
        final isCheckedToday = habitId != null && (_todayCheckInStatus[habitId] ?? false);

        return HabitCard(
          progress: progress,
          isCheckedInToday: isCheckedToday,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(habitId: progress.habit.id!),
              ),
            );
            _loadHabits();
          },
          onQuickCheckIn: isCheckedToday ? null : () => _handleQuickCheckIn(progress),
        );
      },
    );
  }
}

/// Settings gear button for the AppBar
class SettingButton extends StatefulWidget {
  const SettingButton({super.key});

  @override
  State<SettingButton> createState() => SettingButtonState();
}

class SettingButtonState extends State<SettingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Settings()),
        );
      },
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHovered ? Colors.greenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: SvgPicture.asset(
          'assets/icons/gear-svgrepo-com.svg',
          height: 26,
          width: 26,
        ),
      ),
    );
  }
}
