import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDarkTheme;

  const SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDarkTheme,
    required Color textColor,
    bool isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory:
            NoSplash.splashFactory, // Removes the ripple globally in this scope
        highlightColor:
            Colors.transparent, // Removes the solid color highlight on tap
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(icon, size: 23.sp, color: textColor),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 21.sp, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
