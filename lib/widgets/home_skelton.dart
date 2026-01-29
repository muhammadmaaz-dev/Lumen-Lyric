import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark theme colors for skeleton
    final baseColor = Colors.grey[900]!;
    final highlightColor = Colors.grey[800]!;

    return Scaffold(
      backgroundColor: Colors.black,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // --- Trending Section Skeleton ---
                  _buildSectionTitleSkeleton(),
                  SizedBox(height: 12.h),
                  Column(
                    children: List.generate(
                      4,
                      (index) => _buildListItemSkeleton(),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // --- Featured Section Skeleton ---
                  _buildSectionTitleSkeleton(),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            width: 100.w,
                            height: 16.h,
                            color: Colors.white,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 60.w,
                            height: 14.h,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // --- Artists Section Skeleton ---
                  _buildSectionTitleSkeleton(),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 50.w,
                            height: 12.h,
                            color: Colors.white,
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

  Widget _buildSectionTitleSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: 120.w, height: 20.h, color: Colors.white),
        Container(width: 40.w, height: 14.h, color: Colors.white),
      ],
    );
  }

  Widget _buildListItemSkeleton() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 50.h,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150.w, height: 14.h, color: Colors.white),
              SizedBox(height: 6.h),
              Container(width: 100.w, height: 12.h, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
