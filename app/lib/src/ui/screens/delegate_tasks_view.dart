import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

class DelegateTasksView extends StatefulWidget {
  const DelegateTasksView({super.key});

  @override
  State<DelegateTasksView> createState() => _DelegateTasksViewState();
}

class _DelegateTasksViewState extends State<DelegateTasksView>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  String? _activeProfileId;

  late String _currentDay;
  late String _currentWeek;
  late int _currentWeekday;

  /// Locations loaded from Firestore for today.
  final List<String> _locationNames = [];
  final List<String> _locationDocIds = [];
  final List<List<String>> _tasksPerLocation = [];

  /// Map of "locIdx-taskIdx" → delegated profile id (for display).
  final Map<String, String> _delegationMap = {};

  /// Family profiles (non-admin) that can receive delegated tasks.
  List<FamilyProfile> _assignableProfiles = [];

  /// All profiles for lookup.
  List<FamilyProfile> _allProfiles = [];

  /// Delegated tasks across all profiles (for the bottom section).
  List<_DelegatedTaskInfo> _delegatedTasks = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ──────────────────────────────────────────────
  //  Day / Week helpers
  // ──────────────────────────────────────────────

  String _dayName(int weekday) {
    const names = [
      'Mandag', 'Tirsdag', 'Onsdag', 'Torsdag',
      'Fredag', 'Lørdag', 'Søndag',
    ];
    return names[weekday - 1];
  }

  String _dayKey(int weekday) {
    const keys = [
      'Luni', 'Marti', 'Miercuri', 'Joi',
      'Vineri', 'Sambata', 'Duminica',
    ];
    return keys[weekday - 1];
  }

  String _getWeekKey(DateTime d) {
    final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart =
        firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    final week =
        ((thursday.difference(firstWeekStart).inDays) / 7).floor() + 1;
    return 'Y${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    final now = DateTime.now();
    _currentWeekday = now.weekday;
    _currentDay = _dayKey(now.weekday);
    _currentWeek = _getWeekKey(now);

    _loadAll();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Data loading
  // ──────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (user == null) return;
    try {
      // Load active profile id
      _activeProfileId = await ProfileService.getActiveProfileId();

      // Load profiles
      _allProfiles = await ProfileService.getProfiles(user!.uid);
      _assignableProfiles =
          _allProfiles.where((p) => !p.isAdmin).toList();

      // Load today's tasks
      await _loadTodayTasks();

      // Load delegated tasks from all non-admin profiles
      await _loadDelegatedTasks();

      if (!mounted) return;
      setState(() => _loading = false);
      _animController.forward();
    } catch (e) {
      debugPrint('DelegateTasksView: Error loading data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTodayTasks() async {
    final locsSnap = await _db
        .collection('users')
        .doc(user!.uid)
        .collection('userProgress')
        .doc(_currentWeek)
        .collection('days')
        .doc(_currentDay)
        .collection('locations')
        .orderBy('index')
        .get();

    _locationNames.clear();
    _locationDocIds.clear();
    _tasksPerLocation.clear();
    _delegationMap.clear();

    for (int i = 0; i < locsSnap.docs.length; i++) {
      final doc = locsSnap.docs[i];
      final data = doc.data();
      _locationNames.add(data['name']?.toString() ?? 'Rom ${i + 1}');
      _locationDocIds.add(doc.id);
      final tasks = List<String>.from(data['tasks'] ?? const <String>[]);
      _tasksPerLocation.add(tasks);

      // Check if any task in this location has been delegated
      final delegations =
          Map<String, dynamic>.from(data['delegations'] ?? {});
      for (final entry in delegations.entries) {
        _delegationMap['$i-${entry.key}'] = entry.value.toString();
      }
    }
  }

  Future<void> _loadDelegatedTasks() async {
    _delegatedTasks.clear();
    for (final profile in _assignableProfiles) {
      final snap = await _db
          .collection('users')
          .doc(user!.uid)
          .collection('familyProfiles')
          .doc(profile.id)
          .collection('delegatedTasks')
          .where('week', isEqualTo: _currentWeek)
          .where('day', isEqualTo: _currentDay)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        _delegatedTasks.add(_DelegatedTaskInfo(
          docId: doc.id,
          profileId: profile.id,
          profileName: profile.name,
          profileEmoji: profile.emoji,
          profileColor: profile.color,
          taskName: data['taskName'] ?? '',
          status: data['status'] ?? 'pending',
        ));
      }
    }
  }

  // ──────────────────────────────────────────────
  //  Task delegation action
  // ──────────────────────────────────────────────

  Future<void> _delegateTask(
    int locIdx,
    int taskIdx,
    String taskName,
    FamilyProfile target,
  ) async {
    if (user == null || _activeProfileId == null) return;

    try {
      // Write to ProfileService
      await ProfileService.delegateTask(
        uid: user!.uid,
        targetProfileId: target.id,
        week: _currentWeek,
        day: _currentDay,
        locationIndex: locIdx,
        taskIndex: taskIdx,
        taskName: taskName,
        delegatedByProfileId: _activeProfileId!,
      );

      // Also store in the location doc for quick lookup
      final locRef = _db
          .collection('users')
          .doc(user!.uid)
          .collection('userProgress')
          .doc(_currentWeek)
          .collection('days')
          .doc(_currentDay)
          .collection('locations')
          .doc(_locationDocIds[locIdx]);

      await locRef.set({
        'delegations': {'$taskIdx': target.id},
      }, SetOptions(merge: true));

      setState(() {
        _delegationMap['$locIdx-$taskIdx'] = target.id;
      });

      // Reload delegated tasks
      await _loadDelegatedTasks();
      if (mounted) setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accent3,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              '${target.emoji} ${target.name} har fått oppgaven "$taskName"',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('DelegateTasksView: Error delegating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Kunne ikke delegere oppgaven. Prøv igjen.'),
          ),
        );
      }
    }
  }

  FamilyProfile? _findProfile(String profileId) {
    try {
      return _allProfiles.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.accentDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Deleger oppgaver',
          style: TextStyle(
            color: AppColors.accentDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryBackground],
            stops: [0.0, 0.35],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent3),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: _buildContent(),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Day Selector ──
        _buildDaySelector(),
        const SizedBox(height: 16),

        // ── Today header ──
        _buildTodayHeader(),
        const SizedBox(height: 20),

        // ── Location cards with tasks ──
        if (_tasksPerLocation.isEmpty)
          _buildEmptyState()
        else
          ..._buildLocationCards(),

        const SizedBox(height: 28),

        // ── Delegated tasks summary ──
        _buildDelegatedSection(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Row(
      children: List.generate(5, (index) {
        final dayNum = index + 1;
        final isSelected = _currentWeekday == dayNum;
        final dayName = _dayName(dayNum);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == 4 ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () async {
                if (_currentWeekday == dayNum) return;
                setState(() {
                  _currentWeekday = dayNum;
                  _currentDay = _dayKey(dayNum);
                  _loading = true;
                });
                await _loadTodayTasks();
                await _loadDelegatedTasks();
                if (mounted) {
                  setState(() {
                    _loading = false;
                  });
                }
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent3 : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.accent3 : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  dayName.substring(0, 3), // "Man", "Tir", etc.
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.accentDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────────────
  //  Today header
  // ──────────────────────────────────────────────

  Widget _buildTodayHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.accent3,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dagens oppgaver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dayName(_currentWeekday),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent3.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_tasksPerLocation.fold<int>(0, (sum, l) => sum + l.length)} oppgaver',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Empty state
  // ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 56, color: AppColors.accent3.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'Ingen oppgaver i dag',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Legg til oppgaver i ukeplanen for å kunne delegere.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.primaryText2),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Location cards
  // ──────────────────────────────────────────────

  List<Widget> _buildLocationCards() {
    return List.generate(_locationNames.length, (locIdx) {
      final locationName = _locationNames[locIdx];
      final tasks = _tasksPerLocation[locIdx];

      if (tasks.isEmpty) return const SizedBox.shrink();

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + locIdx * 120),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              childrenPadding:
                  const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.room_outlined,
                    color: AppColors.accent3, size: 20),
              ),
              title: Text(
                locationName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${tasks.length} oppgaver',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryText2.withOpacity(0.7),
                ),
              ),
              children: List.generate(tasks.length, (taskIdx) {
                return _buildTaskRow(locIdx, taskIdx, tasks[taskIdx]);
              }),
            ),
          ),
        ),
      );
    });
  }

  // ──────────────────────────────────────────────
  //  Single task row
  // ──────────────────────────────────────────────

  Widget _buildTaskRow(int locIdx, int taskIdx, String taskName) {
    final delegationKey = '$locIdx-$taskIdx';
    final delegatedToId = _delegationMap[delegationKey];
    final delegatedProfile =
        delegatedToId != null ? _findProfile(delegatedToId) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: delegatedProfile != null
            ? delegatedProfile.color.withOpacity(0.08)
            : AppColors.primaryBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: delegatedProfile != null
            ? Border.all(color: delegatedProfile.color.withOpacity(0.25), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Task name
          Expanded(
            child: Text(
              taskName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delegation chip or selector
          if (delegatedProfile != null)
            _buildAssignedChip(delegatedProfile, locIdx, taskIdx, taskName)
          else
            _buildAssignButton(locIdx, taskIdx, taskName),
        ],
      ),
    );
  }

  Widget _buildAssignedChip(
    FamilyProfile profile,
    int locIdx,
    int taskIdx,
    String taskName,
  ) {
    return GestureDetector(
      onTap: () => _showProfilePicker(locIdx, taskIdx, taskName),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: profile.color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: profile.color.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: profile.color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.swap_horiz_rounded,
                  size: 14, color: profile.color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignButton(int locIdx, int taskIdx, String taskName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showProfilePicker(locIdx, taskIdx, taskName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.accent3.withOpacity(0.25), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                  size: 16, color: AppColors.accent3),
              SizedBox(width: 5),
              Text(
                'Tildel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Profile picker bottom sheet
  // ──────────────────────────────────────────────

  void _showProfilePicker(int locIdx, int taskIdx, String taskName) {
    if (_assignableProfiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content:
              const Text('Ingen familiemedlemmer tilgjengelig for delegering.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Hvem skal gjøre "$taskName"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(height: 20),

              // Profile list
              ...List.generate(_assignableProfiles.length, (i) {
                final profile = _assignableProfiles[i];
                final isSelected =
                    _delegationMap['$locIdx-$taskIdx'] == profile.id;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 250 + i * 80),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _delegateTask(locIdx, taskIdx, taskName, profile);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? profile.color.withOpacity(0.12)
                                : AppColors.primaryBackground.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: profile.color.withOpacity(0.4),
                                    width: 1.5)
                                : Border.all(
                                    color: Colors.grey.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: profile.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(profile.emoji,
                                      style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.accent3, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  Delegated tasks bottom section
  // ──────────────────────────────────────────────

  Widget _buildDelegatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.checklist_rounded,
                  color: AppColors.accentDark, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delegerte oppgaver',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
            ),
            if (_delegatedTasks.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_delegatedTasks.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (_delegatedTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 40, color: AppColors.primaryText2.withOpacity(0.35)),
                const SizedBox(height: 10),
                const Text(
                  'Ingen delegerte oppgaver ennå',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trykk "Tildel" på en oppgave for å starte.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText2.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_delegatedTasks.length, (i) {
            final task = _delegatedTasks[i];
            return _buildDelegatedTaskCard(task, i);
          }),
      ],
    );
  }

  Widget _buildDelegatedTaskCard(_DelegatedTaskInfo task, int index) {
    final isDone = task.status == 'done';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.accent3.withOpacity(0.3)
                : task.profileColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile emoji circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.profileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(task.profileEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? AppColors.primaryText2
                          : AppColors.primaryText,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.profileName,
                    style: TextStyle(
                      fontSize: 13,
                      color: task.profileColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.accent3.withOpacity(0.12)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: isDone ? AppColors.accent3 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? 'Ferdig' : 'Venter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? AppColors.accent3 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Helper model for delegated task display
// ──────────────────────────────────────────────

class _DelegatedTaskInfo {
  final String docId;
  final String profileId;
  final String profileName;
  final String profileEmoji;
  final Color profileColor;
  final String taskName;
  final String status;

  const _DelegatedTaskInfo({
    required this.docId,
    required this.profileId,
    required this.profileName,
    required this.profileEmoji,
    required this.profileColor,
    required this.taskName,
    required this.status,
  });
}
