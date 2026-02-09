import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:shimmer/shimmer.dart';

class ArtistDetailSkeleton extends StatelessWidget {
  const ArtistDetailSkeleton({super.key});

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
        elevation: 0,
        leading: Icon(Icons.arrow_back, color: iconColor),
        actions: [
          Icon(Icons.search, color: iconColor),
          SizedBox(width: 16.w),
          Icon(Icons.more_vert, color: iconColor),
          SizedBox(width: 16.w),
        ],
      ),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 8.h),
              // Artist Circle Image
              Container(
                width: 160.r,
                height: 160.r,
                decoration: BoxDecoration(
                  color: shimmerItemColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 24.h),
              // Artist Name
              Container(
                width: 200.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: shimmerItemColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 10.h),
              // Subscribers Text
              Container(
                width: 120.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: shimmerItemColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 24.h),
              // Buttons Row (Shuffle & Follow)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButtonSkeleton(shimmerItemColor),
                  SizedBox(width: 24.w),
                  _buildButtonSkeleton(shimmerItemColor),
                ],
              ),
              SizedBox(height: 36.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 150.w,
                      height: 20.h,
                      color: shimmerItemColor,
                    ),
                    Container(
                      width: 80.w,
                      height: 14.h,
                      color: shimmerItemColor,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        // Number
                        Container(
                          width: 20.w,
                          height: 16.h,
                          color: shimmerItemColor,
                        ),
                        SizedBox(width: 16.w),
                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16.h,
                                color: shimmerItemColor,
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                width: 100.w,
                                height: 12.h,
                                color: shimmerItemColor,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Duration/Menu
                        Container(
                          width: 40.w,
                          height: 14.h,
                          color: shimmerItemColor,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonSkeleton(Color color) {
    return Container(
      width: 120.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
      ),
    );
  }
}
