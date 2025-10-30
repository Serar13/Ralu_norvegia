import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/app_router.dart';
import '../../theme/app_colors.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({Key? key}) : super(key: key);

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Klar til å starte dagen din?',
      'subtitle': 'La oss gjøre rengjøring til en hyggelig rutine.',
    },
    {
      'title': 'Dine daglige oppgaver',
      'subtitle': 'Ikke glem å fullføre aktivitetene i Daglig-seksjonen.',
      'image': 'assets/Daily.jpeg',
    },
    {
      'title': 'Ukentlige oppgaver',
      'subtitle': 'Fullfør oppgavene for dagens ukedag.',
      'image': 'assets/Today.jpeg',
    },
    {
      'title': 'Din kalender',
      'subtitle': 'Du kan alltid gå tilbake for å hente inn tapte oppgaver.',
      'image': 'assets/Calendar.jpeg',
    },
    {
      'title': 'Behold streaken din!',
      'subtitle': 'Fullfør daglig og få 10% rabatt etter 100 sammenhengende dager.',
      'image': 'assets/Strike.png',
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    GoRouter.of(context).go((welcomePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFBFD8C0), Color(0xFFE6EFE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (slide['image'] != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: AssetImage(slide['image']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),
                          Text(
                            slide['title']!,
                            style: TextStyle(
                              color: AppColors.accent3,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['subtitle']!,
                            style: TextStyle(
                              color: AppColors.primaryText.withOpacity(0.8),
                              fontSize: 18,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _page == index ? 22 : 8,
                    decoration: BoxDecoration(
                      color: _page == index
                          ? AppColors.accent3
                          : AppColors.primaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent3,
                      // fixed, consistent height; width fills due to SizedBox
                      minimumSize: const Size.fromHeight(56),
                      padding: EdgeInsets.zero, // no extra padding that changes size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _page == _slides.length - 1
                        ? _finishOnboarding
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            ),
                    child: Text(
                      _page == _slides.length - 1 ? "La oss komme i gang!" : "Fortsett",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}