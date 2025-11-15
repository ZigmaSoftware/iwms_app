import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';

class CitizenAuthIntroScreen extends StatefulWidget {
  const CitizenAuthIntroScreen({super.key});

  @override
  State<CitizenAuthIntroScreen> createState() =>
      _CitizenAuthIntroScreenState();
}

class _CitizenAuthIntroScreenState extends State<CitizenAuthIntroScreen> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;

  void _handlePageChanged(int index) {
    setState(() {
      _activeIndex = index;
    });
  }

  void _openRegister() {
    context.go(AppRoutePaths.citizenRegister);
  }

  void _openLogin() {
    context.go(AppRoutePaths.citizenLogin);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slide = _authIntroSlides[_activeIndex];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            itemCount: _authIntroSlides.length,
            itemBuilder: (context, index) {
              return SizedBox.expand(
                child: Image.asset(
                  _authIntroSlides[index].assetPath,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openRegister,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:
                        List.generate(_authIntroSlides.length, (index) {
                      final bool isActive = index == _activeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: isActive ? 32 : 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    slide.title,
                    textAlign: TextAlign.left,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.description,
                    textAlign: TextAlign.left,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D5A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _openLogin,
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthIntroSlide {
  final String title;
  final String description;
  final String assetPath;

  const _AuthIntroSlide({
    required this.title,
    required this.description,
    required this.assetPath,
  });
}

const List<_AuthIntroSlide> _authIntroSlides = [
  _AuthIntroSlide(
    title: 'Friendly doorstep pickups',
    description:
        'Hand over your wet, dry and mixed bags with a smile - our crew is here to help on time.',
    assetPath: 'assets/intro/intro2.png',
  ),
  _AuthIntroSlide(
    title: 'Track your progress',
    description:
        'See how much you recycled this month and stay motivated with easy-to-read stats.',
    assetPath: 'assets/intro/intro3.png',
  ),
  _AuthIntroSlide(
    title: 'Smarter recycling plants',
    description:
        'Every sorted bag powers automated recycling lines that turn trash into new materials.',
    assetPath: 'assets/intro/intro4.png',
  ),
  _AuthIntroSlide(
    title: 'Keep our city green',
    description:
        'Rolling hills, bright trees and clean rivers stay beautiful when we segregate waste every day.',
    assetPath: 'assets/intro/intro1.png',
  ),
];
