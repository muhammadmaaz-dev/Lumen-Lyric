import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:shimmer/shimmer.dart';

class SongMetadataSkeleton extends StatelessWidget {
  const SongMetadataSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors for skeleton
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final shimmerItemColor = isDark ? Colors.white : Colors.grey[400]!;
    final iconColor = isDark ? Colors.grey[800] : Colors.grey[400];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: Icon(Icons.arrow_back, color: iconColor),
        elevation: 0,
      ),
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                // Album Art Skeleton
                Container(
                  width: 300.w,
                  height: 300.h,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                SizedBox(height: 22.h),

                // Title Skeleton
                Container(
                  width: 200.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 12.h),

                // Artist Skeleton
                Container(
                  width: 150.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),

                // Album Skeleton
                Container(
                  width: 100.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 32.h),

                // Metadata Grid Skeleton
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      // Row 1
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => _buildMiniBlock(shimmerItemColor),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Row 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => _buildMiniBlock(shimmerItemColor),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Row 3 (Label)
                      Container(
                        width: 150.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: shimmerItemColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),

                // Buttons Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: shimmerItemColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: shimmerItemColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBlock(Color color) {
    return Column(
      children: [
        Container(width: 50.w, height: 12.h, color: color),
        SizedBox(height: 6.h),
        Container(width: 40.w, height: 16.h, color: color),
      ],
    );
  }
}
