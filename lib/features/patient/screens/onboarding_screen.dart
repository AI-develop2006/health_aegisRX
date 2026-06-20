import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Secure Medical Vault',
      description:
          'Your health records are safeguarded with medical-grade security. Only you control who has access to your medical credentials.',
      emoji: '🛡️',
    ),
    OnboardingPageData(
      title: 'Seamless Doctor Access',
      description:
          'Present a secure, dynamically rotating QR code to authorized healthcare practitioners for instant and tamper-proof verification.',
      emoji: '📲',
    ),
    OnboardingPageData(
      title: 'Complete Control',
      description:
          'Track prescription checkouts, doctor consult logs, and dispense history in real-time, all in one secure clinical dashboard.',
      emoji: '🩺',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _finishOnboarding() {
    widget.onFinished();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseCanvas,
      body: Stack(
        children: [
          // Ambient Layer Shaders (Matching the Vault Home design)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientBlue.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Safe Area Content
          SafeArea(
            child: Column(
              children: [
                // Top header bar (Skip button)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _currentPage < 2
                        ? TextButton(
                            onPressed: _finishOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.clinicalBlue,
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox(
                            height: 48,
                          ), // Spacer to maintain layout
                  ),
                ),

                // Onboarding Page Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Center(
                          child: GlassCard(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Emoji container with premium radial glow
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.baseCanvas,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderWhite,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.clinicalBlue
                                            .withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 72),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                // Onboarding Page Title
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Onboarding Page Description
                                Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.mutedText,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Page Indicators & Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.clinicalBlue
                                  : AppColors.borderWhite,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Button (Next / Get Started)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finishOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.clinicalBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String emoji;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.emoji,
  });
}
