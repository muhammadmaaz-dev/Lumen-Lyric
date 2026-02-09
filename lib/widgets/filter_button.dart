import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FilterButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDarkTheme;

  const FilterButton({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    final activeBtnColor = isDarkTheme
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color(0xff000000);
    final activeBtnText = isDarkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);
    final inactiveBtnColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final inactiveBtnText = isDarkTheme ? Colors.grey[400] : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isActive ? activeBtnColor : inactiveBtnColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? activeBtnText : inactiveBtnText,
            fontWeight: FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }
}
