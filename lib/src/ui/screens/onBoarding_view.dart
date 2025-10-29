import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      'title': 'Bine ai venit la RaluNorvegia!',
      'subtitle': 'Aici curățenia devine o plăcere.',
    },
    {
      'title': 'Task-urile zilnice',
      'subtitle': 'Nu uita să completezi activitățile din secțiunea Daily.',
      'image': 'assets/Daily.jpeg',
    },
    {
      'title': 'Sarcinile săptămânale',
      'subtitle': 'Rezolvă task-urile pentru ziua curentă din săptămână.',
      'image': 'assets/Today.jpeg',
    },
    {
      'title': 'Calendarul tău',
      'subtitle': 'Poți reveni oricând pentru a recupera task-uri ratate.',
      'image': 'assets/Calendar.jpeg',
    },
    {
      'title': 'Menține-ți streak-ul!',
      'subtitle': 'Finalizează zilnic și obține 10% reducere la 100 de zile consecutive.',
      'image': 'assets/Strike.png',
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/welcome');
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
                      _page == _slides.length - 1 ? "Gata, să începem!" : "Continuă",
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