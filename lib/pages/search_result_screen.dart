import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/artist_detail_screen.dart';
import 'package:musicapp/pages/song_metadata_screen.dart';
import 'package:musicapp/pages/search_screen.dart'; // For search bar tap
import 'package:musicapp/provider/search_provider.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:musicapp/widgets/search_result_skelton.dart';

class SearchResultScreen extends ConsumerStatefulWidget {
  final String searchQuery;

  const SearchResultScreen({super.key, required this.searchQuery});

  @override
  ConsumerState<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends ConsumerState<SearchResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Screen open hote hi search trigger karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).search(widget.searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            // Wapis search input par jao agar user tap kare
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                SizedBox(width: 10.w),
                Text(widget.searchQuery, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          tabs: const [
            Tab(text: "Songs"),
            Tab(text: "Artists"),
          ],
        ),
      ),
      body: searchState.isLoading
          ? const SearchResultSkelton()
          : TabBarView(
              controller: _tabController,
              children: [
                // --- SONGS TAB ---
                _buildSongsList(searchState.songs, theme),

                // --- ARTISTS TAB ---
                _buildArtistsList(searchState.artists, theme),
              ],
            ),
    );
  }

  Widget _buildSongsList(List<SongModel> songs, ThemeData theme) {
    if (songs.isEmpty) return _buildEmpty("No songs found", theme);

    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      itemCount: songs.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: song.imageUrl,
              width: 50.h,
              height: 50.h,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: theme.cardColor),
              errorWidget: (_, __, ___) => Container(color: theme.cardColor),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            song.genre,
            maxLines: 1,
            style: theme.textTheme.bodySmall,
          ),
          onTap: () {
            Navigator.push(
              context,
              SlideRightToLeftRoute(
                page: SongMetadataScreen(
                  songId: song.id,
                  imageUrl: song.imageUrl,
                  title: song.title,
                  artist: song.genre,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsList(List<ArtistModel> artists, ThemeData theme) {
    if (artists.isEmpty) return _buildEmpty("No artists found", theme);

    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      itemCount: artists.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28.r,
            backgroundImage: CachedNetworkImageProvider(artist.imageUrl),
            backgroundColor: theme.cardColor,
          ),
          title: Text(
            artist.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text("Artist"),
          onTap: () {
            Navigator.push(
              context,
              SlideRightToLeftRoute(
                page: ArtistDetailScreen(
                  artistName: artist.name,
                  artistImageUrl: artist.imageUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(String text, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 60,
            color: theme.disabledColor,
          ),
          SizedBox(height: 10.h),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
