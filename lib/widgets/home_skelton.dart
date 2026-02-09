import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors for skeleton
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final shimmerItemColor = isDark ? Colors.white : Colors.grey[400]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // --- Header Skeleton ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 150.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: shimmerItemColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  _buildSectionTitleSkeleton(shimmerItemColor),
                  SizedBox(height: 12.h),
                  Column(
                    children: List.generate(
                      4,
                      (index) => _buildListItemSkeleton(shimmerItemColor),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  _buildSectionTitleSkeleton(shimmerItemColor),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 210.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (_, __) => SizedBox(width: 16.w),
                      itemBuilder: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160.w,
                            height: 160.w,
                            decoration: BoxDecoration(
                              color: shimmerItemColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            width: 100.w,
                            height: 16.h,
                            color: shimmerItemColor,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 60.w,
                            height: 14.h,
                            color: shimmerItemColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  _buildSectionTitleSkeleton(shimmerItemColor),
                  SizedBox(height: 16.h),
                  SizedBox(
                    height: 110.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      separatorBuilder: (_, __) => SizedBox(width: 18.w),
                      itemBuilder: (_, __) => Column(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: shimmerItemColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 50.w,
                            height: 12.h,
                            color: shimmerItemColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitleSkeleton(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: 120.w, height: 20.h, color: color),
        Container(width: 40.w, height: 14.h, color: color),
      ],
    );
  }

  Widget _buildListItemSkeleton(Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 50.h,
            height: 50.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150.w, height: 14.h, color: color),
              SizedBox(height: 6.h),
              Container(width: 100.w, height: 12.h, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
