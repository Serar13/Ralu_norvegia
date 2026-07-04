import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';
import 'package:ralu_norvegia/src/ui/widgets/admin_pin_dialog.dart';

/// Netflix-style "Hvem er du?" profile selection screen.
///
/// Displays a grid of family profile avatars. Admin profiles show a lock badge
/// and require a PIN dialog before activating. Tapping a non-admin profile
/// directly sets it as active and navigates to home.
class ProfileSelectionView extends StatefulWidget {
  const ProfileSelectionView({super.key});

  @override
  State<ProfileSelectionView> createState() => _ProfileSelectionViewState();
}

class _ProfileSelectionViewState extends State<ProfileSelectionView>
    with TickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  /// Tracks which profile card is currently being scale-animated on tap.
  String? _tappedProfileId;

  /// Whether the screen is in manage profiles mode.
  bool _isManageMode = false;

  /// Holds the current profiles list.
  List<FamilyProfile> _currentProfiles = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Auto-heal profiles on load
    if (_user != null) {
      ProfileService.ensureAdminProfileExists(_user!.uid);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ───────────────────────── Profile Tap ─────────────────────────

  Future<void> _onProfileTap(FamilyProfile profile) async {
    if (_isManageMode) {
      if (profile.isAdmin) {
        _showAdminPinDialog(profile, isManageMode: true);
      } else {
        _showManageProfileDialog(profile);
      }
      return;
    }

    // Trigger scale animation
    setState(() => _tappedProfileId = profile.id);
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    if (profile.isAdmin) {
      _showAdminPinDialog(profile, isManageMode: false);
    } else {
      await ProfileService.setActiveProfile(profile);
      if (mounted) context.go(homePath);
    }

    // Reset scale after a short delay (in case dialog is dismissed)
    if (mounted) setState(() => _tappedProfileId = null);
  }

  void _showManageProfileDialog(FamilyProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Administrer ${profile.name}',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: AppColors.accentDark,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar display
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: profile.color.withOpacity(0.2),
                  border: Border.all(color: profile.color, width: 2),
                ),
                child: Center(
                  child: Text(
                    profile.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Edit button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(createProfilePath, extra: {'profile': profile});
                },
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                label: Text(
                  'Rediger profil',
                  style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent3,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Delete button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteProfile(profile);
                },
                icon: const Icon(Icons.delete_forever_rounded, color: AppColors.warning),
                label: Text(
                  'Slett profil',
                  style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warning),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Avbryt',
                style: GoogleFonts.kanit(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProfile(FamilyProfile profile) {
    if (profile.isAdmin) {
      final adminCount = _currentProfiles.where((p) => p.isAdmin).length;
      if (adminCount <= 1) {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Text(
                'Kan ikke slette profil',
                style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
              content: const Text(
                'Du må ha minst én administratorprofil i familien. Denne profilen kan ikke slettes.',
                style: TextStyle(color: AppColors.primaryText2),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'OK',
                    style: GoogleFonts.kanit(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Slett profil?',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: AppColors.accentDark,
            ),
          ),
          content: Text(
            'Er du sikker på at du vil slette profilen til ${profile.name}? Dette vil slette profilen permanent.',
            style: const TextStyle(color: AppColors.primaryText2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Avbryt',
                style: GoogleFonts.kanit(color: AppColors.accentDark),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                
                // If the deleted profile was the active one, clear active profile
                final activeId = await ProfileService.getActiveProfileId();
                if (activeId == profile.id) {
                  await ProfileService.clearActiveProfile();
                }
                
                await ProfileService.deleteProfile(_user!.uid, profile.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${profile.name} ble slettet'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Slett',
                style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAdminPinDialog(FamilyProfile profile, {required bool isManageMode}) {
    showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AdminPinDialog(
        uid: _user!.uid,
        profileId: profile.id,
        title: isManageMode ? 'Bekreft admin-PIN' : 'Skriv inn PIN',
        message: isManageMode
            ? 'Skriv inn PIN-koden for å administrere ${profile.name}'
            : 'Skriv inn PIN-koden for ${profile.name}',
      ),
    ).then((verifiedPin) async {
      if (verifiedPin != null && mounted) {
        if (isManageMode) {
          _showManageProfileDialog(profile);
        } else {
          await ProfileService.setActiveProfile(profile);
          if (mounted) context.go(homePath);
        }
      }
    });
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // Safety fallback – should not happen after login
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryBackground,
            ],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<FamilyProfile>>(
            stream: ProfileService.getProfilesStream(_user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentDark,
                  ),
                );
              }

              final profiles = snapshot.data ?? [];
              _currentProfiles = profiles;

              // Start fade-in when we first receive data
              if (!_fadeController.isCompleted &&
                  !_fadeController.isAnimating) {
                _fadeController.forward();
              }

              final nonAdminCount =
                  profiles.where((p) => !p.isAdmin).length;
              final showLargerSingle =
                  nonAdminCount == 1 && profiles.length <= 2;
              final canAddMore = profiles.length < 5;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ── Title ──
                    Text(
                      _isManageMode ? 'Administrer profiler' : 'Hvem er du?',
                      style: GoogleFonts.kanit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isManageMode
                          ? 'Velg profilen du ønsker å redigere eller slette'
                          : 'Velg profilen din for å fortsette',
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryText2,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Profile Grid ──
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: [
                              // Profile cards
                              ...profiles.map(
                                (profile) => _ProfileCard(
                                  profile: profile,
                                  isLarge: showLargerSingle &&
                                      !profile.isAdmin,
                                  isPressed:
                                      _tappedProfileId == profile.id,
                                  onTap: () => _onProfileTap(profile),
                                  isManageMode: _isManageMode,
                                ),
                              ),

                              // Add profile card
                              if (canAddMore)
                                _AddProfileCard(
                                  onTap: () => context.push(
                                    createProfilePath,
                                    extra: {'isFirstProfile': profiles.isEmpty},
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Manage button ──
                    if (profiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isManageMode = !_isManageMode;
                          });
                        },
                        icon: Icon(
                          _isManageMode ? Icons.check_rounded : Icons.settings_outlined,
                          size: 18,
                          color: AppColors.primaryText2,
                        ),
                        label: Text(
                          _isManageMode ? 'Ferdig' : 'Administrer profiler',
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Profile Card Widget
// ═══════════════════════════════════════════════════════════════════

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isLarge,
    required this.isPressed,
    required this.onTap,
    this.isManageMode = false,
  });

  final FamilyProfile profile;
  final bool isLarge;
  final bool isPressed;
  final VoidCallback onTap;
  final bool isManageMode;

  @override
  Widget build(BuildContext context) {
    final double avatarSize = isLarge ? 120 : 96;
    final double emojiSize = isLarge ? 52 : 40;
    final double nameSize = isLarge ? 18 : 15;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: avatarSize + 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Avatar Circle ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Outer glow / shadow
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: profile.color,
                      boxShadow: [
                        BoxShadow(
                          color: profile.color.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.emoji,
                        style: TextStyle(fontSize: emojiSize),
                      ),
                    ),
                  ),

                  // Netflix-style semi-transparent edit overlay with pen icon in manage mode
                  if (isManageMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                  // Admin lock badge
                  if (profile.isAdmin)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accentDark,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Profile Name ──
              Text(
                profile.name,
                style: GoogleFonts.kanit(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Add Profile Card Widget
// ═══════════════════════════════════════════════════════════════════

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 96;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dashed circle with '+' ──
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
                border: Border.all(
                  color: AppColors.primaryText2.withOpacity(0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                size: 40,
                color: AppColors.primaryText2.withOpacity(0.5),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Legg til profil',
              style: GoogleFonts.kanit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText2.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
