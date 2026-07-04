import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView>
    with SingleTickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;

  String? _profileId;
  String? _profileName;
  String? _profileEmoji;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadActiveProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProfile() async {
    final id = await ProfileService.getActiveProfileId();
    final name = await ProfileService.getActiveProfileName();
    final emoji = await ProfileService.getActiveProfileEmoji();
    if (mounted) {
      setState(() {
        _profileId = id;
        _profileName = name;
        _profileEmoji = emoji;
      });
      _fadeController.forward();
    }
  }

  // ──────────────────────────────────────────────
  //  Day helpers
  // ──────────────────────────────────────────────

  /// Translates internal Firestore day keys to Norwegian display names.
  String _translateDay(String day) {
    switch (day.toLowerCase()) {
      case 'luni':
        return 'Mandag';
      case 'marti':
        return 'Tirsdag';
      case 'miercuri':
        return 'Onsdag';
      case 'joi':
        return 'Torsdag';
      case 'vineri':
        return 'Fredag';
      case 'sambata':
        return 'Lørdag';
      case 'duminica':
        return 'Søndag';
      default:
        return day;
    }
  }

  String _currentDayKey() {
    const days = [
      'Luni',
      'Marti',
      'Miercuri',
      'Joi',
      'Vineri',
      'Sambata',
      'Duminica'
    ];
    return days[DateTime.now().weekday - 1];
  }

  // ──────────────────────────────────────────────
  //  Group tasks by day
  // ──────────────────────────────────────────────

  /// Groups Firestore task documents into day buckets.
  /// Returns a map of { dayKey: [ doc, doc, … ] } ordered: today first,
  /// then the rest sorted alphabetically.
  Map<String, List<QueryDocumentSnapshot>> _groupByDay(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final day = (data['day'] as String?) ?? 'Ukjent';
      grouped.putIfAbsent(day, () => []).add(doc);
    }

    // Sort so today comes first
    final today = _currentDayKey();
    final dayOrder = [
      'Luni',
      'Marti',
      'Miercuri',
      'Joi',
      'Vineri',
      'Sambata',
      'Duminica'
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == today) return -1;
        if (b == today) return 1;
        final ia = dayOrder.indexOf(a);
        final ib = dayOrder.indexOf(b);
        return ia.compareTo(ib);
      });

    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  // ──────────────────────────────────────────────
  //  Task actions
  // ──────────────────────────────────────────────

  Future<void> _toggleTask(String docId, bool isDone) async {
    if (_user == null || _profileId == null) return;

    if (isDone) {
      // Already done → mark pending again
      await ProfileService.markDelegatedTaskPending(
          _user!.uid, _profileId!, docId);
    } else {
      await ProfileService.markDelegatedTaskDone(
          _user!.uid, _profileId!, docId);
    }
  }

  // ──────────────────────────────────────────────
  //  Delegator name resolver
  // ──────────────────────────────────────────────

  /// Caches profile names so we don't re-fetch every build.
  final Map<String, String> _delegatorNameCache = {};

  Future<String> _resolveDelegatorName(String profileId) async {
    if (_delegatorNameCache.containsKey(profileId)) {
      return _delegatorNameCache[profileId]!;
    }
    if (_user == null) return profileId;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('familyProfiles')
          .doc(profileId)
          .get();
      final name = doc.data()?['name'] as String? ?? profileId;
      _delegatorNameCache[profileId] = name;
      return name;
    } catch (_) {
      return profileId;
    }
  }

  // ──────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = _user?.uid;
    final profileId = _profileId;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              _buildAppBar(),
              const SizedBox(height: 8),
              // ── Task List ──
              Expanded(
                child: (uid == null || profileId == null)
                    ? _buildLoading()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTaskStream(uid, profileId),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  App Bar
  // ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.accentDark,
              size: 20,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(homePath);
              }
            },
          ),
          const SizedBox(width: 4),
          // Profile emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _profileEmoji ?? '👤',
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mine oppgaver',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentDark,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_profileName != null)
                  Text(
                    _profileName!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Small decorative icon
          Icon(
            Icons.checklist_rounded,
            color: AppColors.accent3.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Task stream
  // ──────────────────────────────────────────────

  Widget _buildTaskStream(String uid, String profileId) {
    return StreamBuilder<QuerySnapshot>(
      stream: ProfileService.getDelegatedTasksStream(uid, profileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Noe gikk galt. Prøv igjen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryText2.withOpacity(0.7),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        final grouped = _groupByDay(docs);

        return RefreshIndicator(
          color: AppColors.accent3,
          backgroundColor: Colors.white,
          onRefresh: () async {
            // Force a brief pause so the user sees the refresh indicator
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dayKey = grouped.keys.elementAt(index);
              final tasks = grouped[dayKey]!;
              final isToday = dayKey == _currentDayKey();

              return _DaySectionWidget(
                dayLabel: _translateDay(dayKey),
                isToday: isToday,
                tasks: tasks,
                onToggle: _toggleTask,
                resolveDelegator: _resolveDelegatorName,
                animationDelay: index,
              );
            },
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  Empty state
  // ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cleaning illustration icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '✨',
                    style: TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Ingen oppgaver ennå! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Du har ingen oppgaver akkurat nå.\nSlapp av og nyt dagen!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryText2.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Loading
  // ──────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.accent3,
        strokeWidth: 3,
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Day Section Widget (grouped by day)
// ══════════════════════════════════════════════════

class _DaySectionWidget extends StatefulWidget {
  final String dayLabel;
  final bool isToday;
  final List<QueryDocumentSnapshot> tasks;
  final Future<void> Function(String docId, bool isDone) onToggle;
  final Future<String> Function(String profileId) resolveDelegator;
  final int animationDelay;

  const _DaySectionWidget({
    required this.dayLabel,
    required this.isToday,
    required this.tasks,
    required this.onToggle,
    required this.resolveDelegator,
    required this.animationDelay,
  });

  @override
  State<_DaySectionWidget> createState() => _DaySectionWidgetState();
}

class _DaySectionWidgetState extends State<_DaySectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Stagger the animation based on section index
    Future.delayed(Duration(milliseconds: 100 * widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort tasks: pending first, done last
    final sorted = List<QueryDocumentSnapshot>.from(widget.tasks);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDone = (aData['status'] == 'done') ? 1 : 0;
      final bDone = (bData['status'] == 'done') ? 1 : 0;
      return aDone.compareTo(bDone);
    });

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isToday
                        ? AppColors.accent3
                        : AppColors.primaryText2.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isToday) ...[
                        const Icon(
                          Icons.today_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        widget.isToday ? 'I dag · ${widget.dayLabel}' : widget.dayLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isToday
                              ? Colors.white
                              : AppColors.primaryText2,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Task count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sorted.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task cards
          ...sorted.map((doc) => _TaskCard(
                doc: doc,
                onToggle: widget.onToggle,
                resolveDelegator: widget.resolveDelegator,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Individual Task Card
// ══════════════════════════════════════════════════

class _TaskCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Future<void> Function(String docId, bool isDone) onToggle;
  final Future<String> Function(String profileId) resolveDelegator;

  const _TaskCard({
    required this.doc,
    required this.onToggle,
    required this.resolveDelegator,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  String? _delegatorName;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _loadDelegatorName();
  }

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      _delegatorName = null;
      _loadDelegatorName();
    }
  }

  Future<void> _loadDelegatorName() async {
    final data = widget.doc.data() as Map<String, dynamic>;
    final delegatedBy = data['delegatedBy'] as String?;
    if (delegatedBy != null) {
      final name = await widget.resolveDelegator(delegatedBy);
      if (mounted) setState(() => _delegatorName = name);
    }
  }

  Future<void> _handleToggle(bool isDone) async {
    if (_toggling) return;
    setState(() => _toggling = true);

    // Animate scale down and up
    await _scaleController.reverse();
    await widget.onToggle(widget.doc.id, isDone);
    if (mounted) {
      await _scaleController.forward();
      setState(() => _toggling = false);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final taskName = data['taskName'] as String? ?? 'Oppgave';
    final isDone = data['status'] == 'done';

    return ScaleTransition(
      scale: _scaleController,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFFE8F5E9).withOpacity(0.85)
              : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: isDone
              ? Border.all(
                  color: AppColors.accent3.withOpacity(0.25), width: 1.5)
              : null,
          boxShadow: isDone
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleToggle(isDone),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Checkbox area – large touch target
                  _buildCheckbox(isDone),
                  const SizedBox(width: 14),
                  // Task info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? AppColors.accent3.withOpacity(0.6)
                                : AppColors.primaryText,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor:
                                AppColors.accent3.withOpacity(0.5),
                            decorationThickness: 2,
                          ),
                          child: Text(taskName),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.primaryText2.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fra: ${_delegatorName ?? '...'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryText2.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: isDone
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('done'),
                            color: AppColors.accent3,
                            size: 28,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('pending'),
                            color: AppColors.primaryText2.withOpacity(0.25),
                            size: 28,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isDone) {
    return GestureDetector(
      onTap: () => _handleToggle(isDone),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.accent3
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDone
                    ? AppColors.accent3
                    : AppColors.primaryText2.withOpacity(0.3),
                width: 2.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('checked'),
                      color: Colors.white,
                      size: 20,
                    )
                  : const SizedBox.shrink(key: ValueKey('unchecked')),
            ),
          ),
        ),
      ),
    );
  }
}
