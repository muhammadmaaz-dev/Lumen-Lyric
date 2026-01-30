import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class SearchResultSkelton extends StatelessWidget {
  const SearchResultSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- FIX: High Contrast Colors ---
    // Light Mode: Thora dark grey (300 -> 400) taake white pe dikhe
    // Dark Mode: Thora light grey (900 -> 800) taake black pe dikhe
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[400]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    // Container color bus opaque hona chahiye (Color matter nahi karta shimmer uske upar draw hoga)
    final containerColor = Colors.black;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Background match kiya
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.separated(
          padding: EdgeInsets.all(16.r),
          itemCount: 10,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => _buildListItem(containerColor),
        ),
      ),
    );
  }

  Widget _buildListItem(Color color) {
    return Row(
      children: [
        // Image Box
        Container(
          width: 50.h,
          height: 50.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(width: 16.w),
        // Text Lines
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Line
              Container(
                width: 140.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8.h),
              // Subtitle Line
              Container(
                width: 80.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
