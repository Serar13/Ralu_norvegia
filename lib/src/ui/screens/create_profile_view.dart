import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/models/family_profile.dart';
import 'package:ralu_norvegia/src/service/profile_service.dart';
import 'package:ralu_norvegia/src/ui/widgets/admin_pin_dialog.dart';
import 'package:ralu_norvegia/src/ui/widgets/pin_input_fields.dart';

class CreateProfileView extends StatefulWidget {
  final bool isFirstProfile;

  const CreateProfileView({super.key, this.isFirstProfile = false});

  @override
  State<CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends State<CreateProfileView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<TextEditingController> _createPinControllers =
      List.generate(4, (_) => TextEditingController(text: ' '));
  final List<FocusNode> _createPinFocusNodes = List.generate(4, (_) => FocusNode());
  String? _pinError;

  late String _selectedEmoji;
  late Color _selectedColor;
  late bool _isAdmin;
  bool _isSaving = false;

  // Editing state
  FamilyProfile? _editingProfile;
  bool get _isEditing => _editingProfile != null;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _selectedEmoji = FamilyProfile.availableEmojis.first;
    _selectedColor = FamilyProfile.availableColors.first;
    _isAdmin = widget.isFirstProfile;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Grab edit data from GoRouter extra (only once)
    if (_editingProfile == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic> && extra.containsKey('profile')) {
        final profile = extra['profile'] as FamilyProfile;
        _editingProfile = profile;
        _nameController.text = profile.name;
        _selectedEmoji = profile.emoji;
        _selectedColor = profile.color;
        _isAdmin = profile.isAdmin;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _createPinControllers) {
      c.dispose();
    }
    for (final f in _createPinFocusNodes) {
      f.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  String _getPinValue() {
    return _createPinControllers.map((c) => c.text == ' ' ? '' : c.text).join();
  }

  void _setPinValue(String pin) {
    final chars = pin.split('');
    for (int i = 0; i < 4; i++) {
      if (i < chars.length) {
        _createPinControllers[i].text = chars[i];
      } else {
        _createPinControllers[i].text = ' ';
      }
    }
  }

  // ─────────────────────────────────────────────
  //  Save
  // ─────────────────────────────────────────────

  bool _validateForm() {
    final isFormValid = _formKey.currentState!.validate();
    if (_isAdmin) {
      final pin = _getPinValue();
      setState(() {
        if (!_isEditing && pin.length != 4) {
          _pinError = 'PIN-koden må være 4 siffer';
        } else if (_isEditing && pin.isNotEmpty && pin.length != 4) {
          _pinError = 'PIN-koden må være 4 siffer';
        } else {
          _pinError = null;
        }
      });
      if (_pinError != null) return false;
    }
    return isFormValid;
  }

  Future<void> _save() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Ikke innlogget');

      if (_isEditing) {
        await ProfileService.updateProfile(
          uid: user.uid,
          profileId: _editingProfile!.id,
          name: _nameController.text.trim(),
          emoji: _selectedEmoji,
          colorValue: _selectedColor.value,
          isAdmin: _isAdmin,
          newPin: _getPinValue().isNotEmpty ? _getPinValue() : null,
        );

        final activeId = await ProfileService.getActiveProfileId();
        if (activeId == _editingProfile!.id) {
          await ProfileService.setActiveProfile(FamilyProfile(
            id: _editingProfile!.id,
            name: _nameController.text.trim(),
            emoji: _selectedEmoji,
            color: _selectedColor,
            isAdmin: _isAdmin,
            order: _editingProfile!.order,
          ));
        }
      } else {
        await ProfileService.createProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          emoji: _selectedEmoji,
          colorValue: _selectedColor.value,
          isAdmin: _isAdmin,
          pin: _isAdmin ? _getPinValue() : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Profilen er oppdatert!' : 'Profilen er opprettet!',
            ),
            backgroundColor: AppColors.accent3,
          ),
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Noe gikk galt: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Rediger profil' : 'Nytt profil',
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          onPressed: () => GoRouter.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.accent3),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 32,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: AnimatedScale(
                      scale: _scaleAnim.value,
                      duration: Duration.zero,
                      child: _buildCard(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Avatar preview ──
              _buildAvatarPreview(),
              const SizedBox(height: 28),

              // ── Name field ──
              _buildNameField(),
              const SizedBox(height: 24),

              // ── Emoji selector ──
              _buildSectionLabel('Velg emoji'),
              const SizedBox(height: 8),
              _buildEmojiSelector(),
              const SizedBox(height: 24),

              // ── Color selector ──
              _buildSectionLabel('Velg farge'),
              const SizedBox(height: 8),
              _buildColorSelector(),
              const SizedBox(height: 24),

              // ── Admin toggle ──
              _buildAdminToggle(),
              const SizedBox(height: 16),

              // ── PIN field (shown for admins) ──
              if (_isAdmin) ...[
                _buildPinField(),
                const SizedBox(height: 24),
              ],

              // ── Save button ──
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Avatar preview
  // ─────────────────────────────────────────────

  Widget _buildAvatarPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _selectedColor.withOpacity(0.25),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutBack,
          child: Text(
            _selectedEmoji,
            key: ValueKey(_selectedEmoji),
            style: const TextStyle(fontSize: 52),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Name field
  // ─────────────────────────────────────────────

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: AppColors.primaryText, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Navn',
          labelStyle: TextStyle(color: AppColors.accent3.withOpacity(0.7)),
          hintText: 'Skriv inn navnet',
          hintStyle: TextStyle(color: AppColors.primary.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent3, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon:
              const Icon(Icons.person_outline, color: AppColors.accent3),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Navn er påkrevd';
          }
          return null;
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Section label
  // ─────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryText2,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Emoji selector
  // ─────────────────────────────────────────────

  Widget _buildEmojiSelector() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FamilyProfile.availableEmojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final emoji = FamilyProfile.availableEmojis[index];
          final isSelected = emoji == _selectedEmoji;

          return GestureDetector(
            onTap: () => setState(() => _selectedEmoji = emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _selectedColor.withOpacity(0.18)
                    : Colors.grey.withOpacity(0.08),
                border: Border.all(
                  color: isSelected ? _selectedColor : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Color selector
  // ─────────────────────────────────────────────

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FamilyProfile.availableColors.map((color) {
        final isSelected = color == _selectedColor;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? AppColors.accentDark : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 22),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  Admin toggle
  // ─────────────────────────────────────────────

  Widget _buildAdminToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent3.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings,
              color: AppColors.accent3, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Administrator',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Switch.adaptive(
            value: _isAdmin,
            onChanged: (widget.isFirstProfile)
                ? null
                : (bool val) async {
                    if (val) {
                      final verifiedPin = await _promptForAdminPin();
                      if (verifiedPin != null) {
                        setState(() {
                          _isAdmin = true;
                          _setPinValue(verifiedPin);
                          _pinError = null;
                        });
                      }
                    } else {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final profiles = await ProfileService.getProfiles(user.uid);
                        final adminCount = profiles.where((p) => p.isAdmin).length;
                        if (_isEditing && _editingProfile!.isAdmin && adminCount <= 1) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Handling ikke tillatt'),
                                content: const Text(
                                  'Du må ha minst én administratorprofil i familien. Denne administratoren kan ikke deaktiveres.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: AppColors.accent3)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return;
                        }
                      }
                      setState(() {
                        _isAdmin = false;
                        _setPinValue('');
                        _pinError = null;
                      });
                    }
                  },
            activeColor: AppColors.accent3,
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForAdminPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final verifiedPin = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AdminPinDialog(
        uid: user.uid,
        profileId: null, // Verify against any admin profile
        title: 'Bekreft admin-PIN',
        message: 'Skriv inn PIN-koden til en administratorprofil for å aktivere administratorrettigheter.',
      ),
    );

    return verifiedPin;
  }

  Widget _buildPinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Velg en PIN-kode'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              PinInputFields(
                controllers: _createPinControllers,
                focusNodes: _createPinFocusNodes,
                isEnabled: !_isSaving,
                onChanged: (val) {
                  if (_pinError != null) {
                    setState(() => _pinError = null);
                  }
                },
              ),
              if (_pinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _pinError!,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Save button
  // ─────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent3,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent3.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Lagre profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
