import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onPrefixTap;
  final bool isDarkTheme;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  // 👇 CHANGE: String ki jagah ValueChanged<String>? karein
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onPrefixTap,
    required this.isDarkTheme,
    this.controller,
    this.onChanged,
    this.onSubmitted, // ✅ Constructor sahi hai
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted, // ✅ Yahan pass karna zaroori hai
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          fillColor: cardColor,
          hintText: hintText,
          hintStyle: TextStyle(color: secondaryTextColor, fontSize: 12.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 22.w,
            vertical: 16.h,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(right: 9.w),
                  child: IconButton(
                    onPressed: onPrefixTap,
                    icon: Icon(prefixIcon),
                    iconSize: 21.sp,
                    color: textColor,
                  ),
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(right: 9.w),
                  child: IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(suffixIcon),
                    color: textColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
