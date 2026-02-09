import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/pages/onboarding/onboarding_pages.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNameAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      if (mounted) {
        Navigator.push(
          context,
          SlideRightToLeftRoute(page: const OnboardingPages()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _buildBackButton(context),
              SizedBox(height: 32.h),
              // Title
              Text(
                'What should we\ncall you?',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This name will appear on your profile',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              ),
              SizedBox(height: 32.h),
              _buildNameTextField(),
              const Spacer(),
              // Continue Button
              _buildContinueButton(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _buildNameTextField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isFocused ? Colors.blue : Colors.grey[700]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _focusNode,
        style: TextStyle(fontSize: 16.sp, color: Colors.white),
        cursorColor: Colors.blue,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 18.h,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _nameController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isEnabled ? _saveNameAndContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.white : Colors.grey[800],
          foregroundColor: isEnabled ? Colors.black : Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[800],
          disabledForegroundColor: Colors.grey[500],
        ),
        child: Text(
          'Continue',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
