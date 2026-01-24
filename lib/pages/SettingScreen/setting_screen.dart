import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/pages/SettingScreen/liked_songs_screen.dart';
import 'package:musicapp/pages/SettingScreen/playlists.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:musicapp/utils/slide_route.dart';
import 'package:musicapp/widgets/setting_tile.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. Changed to ConsumerWidget to access providers
class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Fetch the SharedPreferences instance
    final prefs = ref.watch(sharedPreferencesProvider);
    // 3. Get the name saved during onboarding (Key: 'user_name')
    final userName = prefs.getString('user_name') ?? 'Guest';

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final cardColor = isDarkTheme
        ? const Color(0xff1a1a1a)
        : const Color(0xffffffff);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;
    final avatarBgColor = isDarkTheme
        ? const Color(0xff3a3a3c)
        : const Color(0xffffffff);
    final dividerColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RepaintBoundary(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                floating: true,
                expandedHeight: 70.h,
                flexibleSpace: Container(
                  color: backgroundColor,
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 18.w, bottom: 14.h),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(13.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 9.h),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 106.w,
                              height: 106.h,
                              decoration: BoxDecoration(
                                color: avatarBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '😊',
                                  style: TextStyle(fontSize: 53.sp),
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            // 4. Use the variable 'userName' here
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 21.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),

                      SizedBox(height: 26.h),

                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 11.h),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.dark_mode, color: textColor),
                          title: Text(
                            'Dark Theme',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          trailing: _DarkModeToggle(isDarkTheme: isDarkTheme),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                      SizedBox(height: 19.h),

                      Text(
                        'Library & Activity',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 11.h),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.favorite_border,
                              title: 'Liked Songs',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideRightToLeftRoute(
                                    page: const LikedSongsScreen(),
                                  ),
                                );
                              },
                              isDarkTheme: isDarkTheme,
                              textColor: textColor,
                            ),
                            Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 10,
                              endIndent: 10,
                            ),
                            SettingsTile(
                              icon: Icons.queue_music,
                              title: 'Playlists',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideRightToLeftRoute(
                                    page: const PlaylistsScreen(),
                                  ),
                                );
                              },
                              isDarkTheme: isDarkTheme,
                              textColor: textColor,
                            ),
                            Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 10,
                              endIndent: 10,
                            ),
                            SettingsTile(
                              icon: Icons.download_outlined,
                              title: 'Downloads',
                              onTap: () {},
                              isDarkTheme: isDarkTheme,
                              isLast: true,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Privacy & Security',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.key_outlined,
                              title: 'Change Password',
                              onTap: () {},
                              isDarkTheme: isDarkTheme,
                              textColor: textColor,
                            ),
                            Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 10,
                              endIndent: 10,
                            ),
                            SettingsTile(
                              icon: Icons.person_outline,
                              title: 'Linked Account',
                              onTap: () {},
                              isDarkTheme: isDarkTheme,
                              isLast: true,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.sign_language_sharp,
                              title: 'Suggest Feature',
                              onTap: () {},
                              isDarkTheme: isDarkTheme,
                              textColor: textColor,
                            ),
                            Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 10,
                              endIndent: 10,
                            ),
                            SettingsTile(
                              icon: Icons.bug_report_outlined,
                              title: 'Report a Bug',
                              onTap: () {},
                              isDarkTheme: isDarkTheme,
                              isLast: true,
                              textColor: textColor,
                            ),
                            Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 10,
                              endIndent: 10,
                            ),
                            SettingsTile(
                              icon: Icons.adb_outlined,
                              title: 'About App',
                              onTap: () async {
                                // 1. URL define karein
                                final Uri url = Uri.parse(
                                  'https://github.com/muhammadmaaz-dev/Lumen-Lyric',
                                );

                                // 2. Browser mein open karein
                                if (!await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  debugPrint('Could not launch $url');
                                }
                              },
                              isDarkTheme: isDarkTheme,
                              isLast: true,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: textColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _DarkModeToggle remains unchanged
class _DarkModeToggle extends ConsumerStatefulWidget {
  final bool isDarkTheme;

  const _DarkModeToggle({required this.isDarkTheme});

  @override
  ConsumerState<_DarkModeToggle> createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends ConsumerState<_DarkModeToggle> {
  late bool _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.isDarkTheme;
  }

  @override
  void didUpdateWidget(covariant _DarkModeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkTheme != widget.isDarkTheme) {
      _localValue = widget.isDarkTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _localValue,
      onChanged: (value) async {
        setState(() => _localValue = value);
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        final notifier = ref.read(themeModeProvider.notifier);
        notifier.state = value ? ThemeMode.dark : ThemeMode.light;
        saveThemeToPrefs(ref, notifier.state);
      },
    );
  }
}
