import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ArtistDetailSkeleton extends StatelessWidget {
  const ArtistDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark theme colors for skeleton
    final baseColor = Colors.grey[900]!;
    final highlightColor = Colors.grey[800]!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Icon(Icons.arrow_back, color: Colors.grey[800]),
        actions: [
          Icon(Icons.search, color: Colors.grey[800]),
          const SizedBox(width: 16),
          Icon(Icons.more_vert, color: Colors.grey[800]),
          const SizedBox(width: 16),
        ],
      ),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Artist Circle Image
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 24),
              // Artist Name
              Container(
                width: 200,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              // Subscribers Text
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons Row (Shuffle & Follow)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButtonSkeleton(),
                  const SizedBox(width: 24),
                  _buildButtonSkeleton(),
                ],
              ),
              const SizedBox(height: 36),
              // "Popular Tracks" Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 150, height: 20, color: Colors.white),
                    Container(width: 80, height: 14, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Tracks List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8, // Fake items
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Number
                        Container(width: 20, height: 16, color: Colors.white),
                        const SizedBox(width: 16),
                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 100,
                                height: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Duration/Menu
                        Container(width: 40, height: 14, color: Colors.white),
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

  Widget _buildButtonSkeleton() {
    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}
