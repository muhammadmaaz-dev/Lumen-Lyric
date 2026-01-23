import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/pages/main_navigation.dart';
import 'package:musicapp/pages/onboarding/name_input_screen.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPages extends StatefulWidget {
  const OnboardingPages({super.key});

  @override
  State<OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<OnboardingPages> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Discover Your Sound',
      features: [
        FeatureItem(
          icon: Icons.library_music_outlined,
          text: 'Browse your library',
        ),
        FeatureItem(icon: Icons.favorite_border, text: 'Save favorites'),
        FeatureItem(icon: Icons.playlist_play, text: 'Create playlists'),
      ],
    ),
    OnboardingData(
      title: 'Listen Anywhere',
      features: [
        FeatureItem(
          icon: Icons.headphones_outlined,
          text: 'High quality audio',
        ),
        FeatureItem(icon: Icons.repeat, text: 'Seamless playback'),
        FeatureItem(icon: Icons.shuffle, text: 'Shuffle & repeat'),
      ],
    ),
    OnboardingData(
      title: 'Music That Matches You',
      features: [
        FeatureItem(icon: Icons.cloud_off_outlined, text: 'Offline listening'),
        FeatureItem(
          icon: Icons.do_not_disturb_on_outlined,
          text: 'No distractions',
        ),
        FeatureItem(icon: Icons.equalizer, text: 'Pure sound'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        SlideRightToLeftRoute(page: const MainNavigation()),
        (route) => false,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Page Indicators
            _buildPageIndicators(),
            SizedBox(height: 24.h),
            // Next Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: _buildNextButton(),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Sound Wave Illustration
          _buildSoundWaveIllustration(),
          SizedBox(height: 48.h),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 32.h),
          // Features List
          ...data.features.map((feature) => _buildFeatureItem(feature)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildSoundWaveIllustration() {
    return Image.asset(
      'assets/logo/lines.png',
      height: 200.h,
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFeatureItem(FeatureItem feature) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Icon(feature.icon, color: Colors.grey[400], size: 24.sp),
          SizedBox(width: 16.w),
          Text(
            feature.text,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentPage == index ? 8.w : 6.w,
          height: _currentPage == index ? 8.w : 6.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == _pages.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastPage ? 'Get Started' : 'Next',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final List<FeatureItem> features;

  OnboardingData({required this.title, required this.features});
}

class FeatureItem {
  final IconData icon;
  final String text;

  FeatureItem({required this.icon, required this.text});
}
