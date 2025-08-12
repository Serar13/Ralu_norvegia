import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';

class RoomsSetupPage extends StatefulWidget {
  const RoomsSetupPage({super.key});

  @override
  State<RoomsSetupPage> createState() => _RoomsSetupPageState();
}

class _RoomsSetupPageState extends State<RoomsSetupPage> {
  // Tipurile de camere în ordinea dorită
  final List<String> _roomTypes = const [
    'Kjøkken',
    'Baderom',
    'Gjestebad',
    'Stue',
    'Soverom',
    'Gang',
    'Inngangsparti',
    'Trapp',
    'Vaskerom',
    'Garderoberom',
  ];

  // Număr selectat pentru fiecare tip (default 0, dar Kjøkken min 1)
  late final Map<String, int> _counts = {
    for (final t in _roomTypes) t: t == 'Kjøkken' ? 1 : 0,
  };

  // Numele instanțelor pentru fiecare tip:
  // exemplu: { "Soverom": [TextEditingController(), TextEditingController()] }
  final Map<String, List<TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Inițializează controllere pentru Kjøkken 1
    _ensureControllers('Kjøkken', 1);
  }

  @override
  void dispose() {
    for (final list in _controllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _ensureControllers(String type, int wantedLength) {
    final list = _controllers.putIfAbsent(type, () => []);
    // adăugăm controllere până ajungem la count
    while (list.length < wantedLength) {
      final index = list.length + 1;
      final c = TextEditingController(text: '$type $index');
      list.add(c);
    }
    // tăiem dacă s-a redus count-ul
    while (list.length > wantedLength) {
      final removed = list.removeLast();
      removed.dispose();
    }
  }

  void _changeCount(String type, int delta) {
    final minVal = type == 'Kjøkken' ? 1 : 0;
    final maxVal = 4; // limită maximă cerută
    // If already at max and trying to increment, show SnackBar and ignore
    if (delta > 0 && _counts[type] == maxVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimalt antall for $type er 4.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
      return;
    }
    final newVal = (_counts[type]! + delta).clamp(minVal, maxVal);
    if (newVal == _counts[type]) return;
    setState(() {
      _counts[type] = newVal;
      _ensureControllers(type, newVal);
    });
  }

  bool _validate() {
    // Kjøkken trebuie să aibă minim 1
    if ((_counts['Kjøkken'] ?? 0) < 1) return false;
    // opțional: validează să nu existe câmpuri goale
    for (final type in _roomTypes) {
      final list = _controllers[type] ?? const [];
      for (final c in list) {
        if (c.text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  Map<String, List<String>> _buildResult() {
    final out = <String, List<String>>{};
    for (final type in _roomTypes) {
      final list = _controllers[type] ?? const [];
      if (list.isNotEmpty) {
        out[type] = list.map((c) => c.text.trim()).toList();
      }
    }
    return out;
  }

  /// Construiește planul default pe **4 săptămâni** (Uke 1..Uke 4)
  /// Zilele sunt aceleași în fiecare săptămână, dar headerul diferă:
  /// Uke 1 → "Tak og vegger" | Uke 2 → "Inventar" | Uke 3 → "Inventar" | Uke 4 → "Gulv"
  /// Luni -> Kjøkken
  /// Marti -> Baderom (poate fi 1..n)
  /// Miercuri -> Stue, Inngangsparti, Gang, Trapp
  /// Joi -> Gjestebad, Vaskerom
  /// Vineri -> Soverom(1..n), Garderoberom
  Map<String, dynamic> _buildDefaultWeeks(Map<String, List<String>> rooms) {
    List<String> r(String key) => rooms[key] ?? const [];

    final Map<String, String> weekHeaders = const {
      'Uke 1': 'Tak og vegger',
      'Uke 2': 'Inventar',
      'Uke 3': 'Inventar',
      'Uke 4': 'Gulv',
    };

    Map<String, List<String>> _weekDays() => {
          'Luni': [...r('Kjøkken')],
          'Marti': [...r('Baderom')],
          'Miercuri': [
            ...r('Stue'),
            ...r('Inngangsparti'),
            ...r('Gang'),
            ...r('Trapp'),
          ],
          'Joi': [
            ...r('Gjestebad'),
            ...r('Vaskerom'),
          ],
          'Vineri': [
            ...r('Soverom'),
            ...r('Garderoberom'),
          ],
        };

    final Map<String, Map<String, List<String>>> planWeeks = {
      'Uke 1': _weekDays(),
      'Uke 2': _weekDays(),
      'Uke 3': _weekDays(),
      'Uke 4': _weekDays(),
    };

    return {
      'planWeeks': planWeeks,
      'weekHeaders': weekHeaders,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.accent3,
        title: const Text('Velg rom og navn'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _roomTypes.length,
              itemBuilder: (context, i) {
                final type = _roomTypes[i];
                final count = _counts[type]!;
                final controls = _controllers[type] ?? const [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent3.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: nume tip + selector count
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _SmallSquareBtn(
                              icon: Icons.remove,
                              enabled: type == 'Kjøkken' ? count > 1 : count > 0,
                              onTap: () => _changeCount(type, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: count >= 4 ? Colors.black54 : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _SmallSquareBtn(
                              icon: Icons.add,
                              // lăsăm butonul mereu activ ca să putem arăta SnackBar-ul când e la plafon
                              enabled: true,
                              onTap: () => _changeCount(type, 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Câmpuri de denumire (unul pentru fiecare instanță)
                        if (count > 0)
                          ...List.generate(count, (idx) {
                            final controller = controls[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Nume ${type.toLowerCase()} ${idx + 1}',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (!_validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verifică: Kjøkken minim 1 și numele să nu fie goale.'),
                        ),
                      );
                      return;
                    }
                    final result = _buildResult();

                    // Construiește planul default și mergi la ReviewChose (basic)
                    final plan = _buildDefaultWeeks(result);
                    context.go(ReviewChosePath, extra: {
                      'optionType': 'basic',
                      'planWeeks': plan['planWeeks'],
                      'weekHeaders': plan['weekHeaders'],
                      // 'userId': user?.uid, // adaugă dacă vrei să treci uid
                    });
                  },
                  child: const Text(
                    'Fortsett',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSquareBtn extends StatelessWidget {
  const _SmallSquareBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? Colors.black12 : Colors.black12.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.black38,
        ),
      ),
    );
  }
}