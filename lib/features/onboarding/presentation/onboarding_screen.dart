import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/providers/app_flow_provider.dart';
import 'package:subscription_track/router/route_constants.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_controls.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_data.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).setCompleted(true);
    if (mounted) {
      context.go(RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == onboardingPages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            StoryProgressBar(
              currentPage: _currentPage,
              totalPages: onboardingPages.length,
            ),
            OnboardingHeader(showSkip: !isLastPage, onSkip: _finishOnboarding),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: onboardingPages
                    .map((data) => OnboardingPage(data: data))
                    .toList(),
              ),
            ),
            OnboardingBottomNav(
              currentPage: _currentPage,
              totalPages: onboardingPages.length,
              onNext: _nextPage,
              onBack: _previousPage,
            ),
          ],
        ),
      ),
    );
  }
}
