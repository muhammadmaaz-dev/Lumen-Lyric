import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/pages/onboarding/name_input_screen.dart';
import 'package:musicapp/utils/slide_route.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo - Vinyl/Record Icon
              _buildLogo(),
              SizedBox(height: 32.h),
              // App Name
              Text(
                'Lumen Lyric',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16.h),
              // Tagline
              Text(
                'Your Music. Your Space.',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              // Subtitle
              Text(
                'Listen without noise. Just sound.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              ),
              const Spacer(flex: 3),
              // Get Started Button
              _buildGetStartedButton(context),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo/logo.png',
      width: 140.w,
      height: 140.w,
      fit: BoxFit.contain,
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            SlideRightToLeftRoute(page: const NameInputScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Get Started',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
