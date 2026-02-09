import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod Import
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/models/artist_model.dart';
import 'package:musicapp/models/song_model.dart';
import 'package:musicapp/pages/artist_detail_screen.dart';
import 'package:musicapp/pages/LibraryScreen/library_screen.dart';
import 'package:musicapp/pages/search_screen.dart';
import 'package:musicapp/pages/song_metadata_screen.dart';
import 'package:musicapp/provider/home_provider.dart'; // Apna naya provider import karo
import 'package:musicapp/utils/slide_route.dart';
import 'package:musicapp/widgets/home_skelton.dart'; // Spelling check karlena (skeleton/skelton)
import 'package:musicapp/widgets/bottom_sheet_lib.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).fetchHomeData();
    });
  }

  void _handleSongTap(BuildContext context, SongModel song) {
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
  }

  void _handleArtistTap(BuildContext context, ArtistModel artist) {
    Navigator.push(
      context,
      SlideRightToLeftRoute(
        page: ArtistDetailScreen(
          artistName: artist.name,
          artistImageUrl: artist.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final theme = Theme.of(context);

    if (homeState.isOffline) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80.sp,
                  color: theme.iconTheme.color,
                ),
                SizedBox(height: 24.h),
                Text(
                  "No Internet Connection",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  "You are not connected to the internet. Please check your connection.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                TextButton(
                  onPressed: () {
                    ref.read(homeProvider.notifier).fetchHomeData();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: homeState.isLoading
          ? null
          : AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 18.w,
              title: Text(
                "Home",
                style: TextStyle(
                  color: theme.textTheme.headlineLarge?.color,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: theme.iconTheme.color,
                      size: 22.sp,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        SlideRightToLeftRoute(page: const SearchScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

      body: SafeArea(
        child: homeState.isLoading
            ? const HomeSkeleton()
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(homeProvider.notifier).refresh();
                },
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),

                        // Trending Now
                        _buildSectionTitle('Trending Now'),
                        SizedBox(height: 12.h),
                        _buildTrendingList(context, homeState.trending),

                        SizedBox(height: 28.h),

                        _buildSectionTitle('Featured Songs'),
                        SizedBox(height: 16.h),
                        _buildFeaturedTracks(context, homeState.featured),
                        _buildSectionTitle('Popular Artist'),
                        SizedBox(height: 16.h),
                        _buildPopularArtists(context, homeState.artists),

                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? actionText}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.headlineMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              letterSpacing: 1.2,
            ),
          ),
          if (actionText != null)
            Text(
              actionText,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
                decoration: TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, List<SongModel> songs) {
    const int itemsPerColumn = 4;
    if (songs.isEmpty) return const SizedBox.shrink();
    final int pageCount = (songs.length / itemsPerColumn).ceil();

    return SizedBox(
      height: (70.h * itemsPerColumn).toDouble(),
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          final int startIndex = pageIndex * itemsPerColumn;
          final int endIndex = (startIndex + itemsPerColumn < songs.length)
              ? startIndex + itemsPerColumn
              : songs.length;
          final List<SongModel> columnSongs = songs.sublist(
            startIndex,
            endIndex,
          );
          return Container(
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: columnSongs
                  .map(
                    (song) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
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
                      child: _buildSongRow(context, song, disableTap: true),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongRow(
    BuildContext context,
    SongModel song, {
    bool disableTap = false,
  }) {
    final theme = Theme.of(context);
    final row = Container(
      height: 60.h,
      margin: EdgeInsets.only(bottom: 10.h, left: 20.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: song.imageUrl,
              width: 50.h,
              height: 50.h,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: theme.cardColor),
              errorWidget: (context, url, error) =>
                  Container(color: theme.cardColor),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  song.genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.iconTheme.color?.withOpacity(0.5),
              size: 20.sp,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => NetworkSongOptionsWidget(
                  songId: song.id,
                  title: song.title,
                  artist: song.genre,
                  imageUrl: song.imageUrl,
                ),
              );
            },
          ),
        ],
      ),
    );
    if (disableTap) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleSongTap(context, song),
      child: row,
    );
  }

  Widget _buildFeaturedTracks(BuildContext context, List<SongModel> songs) {
    final theme = Theme.of(context);
    if (songs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (context, index) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
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
            child: SizedBox(
              width: 160.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Image.network(
                          song.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: theme.cardColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    song.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularArtists(BuildContext context, List<ArtistModel> artists) {
    final theme = Theme.of(context);
    if (artists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 99.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        itemCount: artists.length,
        separatorBuilder: (context, index) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Column(
            children: [
              GestureDetector(
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
                child: CircleAvatar(
                  radius: 30.r,
                  backgroundImage: NetworkImage(artist.imageUrl),
                  backgroundColor: theme.cardColor,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
              SizedBox(height: 7.h),
              SizedBox(
                width: 65.w,
                child: Text(
                  artist.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
