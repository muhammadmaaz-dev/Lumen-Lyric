import 'package:flutter/material.dart';
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
        leading: Icon(Icons.arrow_back, color: iconColor), // Disabled look
        elevation: 0,
      ),
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Album Art Skeleton
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 22),

                // Title Skeleton
                Container(
                  width: 200,
                  height: 28,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),

                // Artist Skeleton
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),

                // Album Skeleton
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: shimmerItemColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 32),

                // Metadata Grid Skeleton
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 24),
                      // Row 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => _buildMiniBlock(shimmerItemColor),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Row 3 (Label)
                      Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                          color: shimmerItemColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons Skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: shimmerItemColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: shimmerItemColor,
                          borderRadius: BorderRadius.circular(8),
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
        Container(width: 50, height: 12, color: color),
        const SizedBox(height: 6),
        Container(width: 40, height: 16, color: color),
      ],
    );
  }
}
