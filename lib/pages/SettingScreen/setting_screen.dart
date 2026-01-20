import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicapp/pages/SettingScreen/playlists.dart';
import 'package:musicapp/provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:musicapp/widgets/setting_tile.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) instead of watching provider
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
                expandedHeight: 80,
                flexibleSpace: Container(
                  color: backgroundColor,
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: avatarBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '😊',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Muhammad Maaz',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'muhammad.maaz@gmail.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        'Appearance',
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
                        child: ListTile(
                          leading: Icon(Icons.dark_mode, color: textColor),
                          title: Text(
                            'Dark Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          trailing: _DarkModeToggle(isDarkTheme: isDarkTheme),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Library & Activity',
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
                              icon: Icons.favorite_border,
                              title: 'Liked Songs',
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
                              icon: Icons.queue_music,
                              title: 'Playlists',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PlaylistsScreen(),
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
                              icon: Icons.help_outline,
                              title: 'FAQs',
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
                              icon: Icons.headset_mic_outlined,
                              title: 'Contact Support',
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

// ISOLATED CONSUMER - Only this widget rebuilds on theme toggle
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
    debugPrint('🔄 DarkModeToggle rebuilt');

    return Switch(
      value: _localValue,
      onChanged: (value) {
        // 1️⃣ Update UI instantly (smooth animation)
        setState(() => _localValue = value);

        // 2️⃣ Update global theme AFTER
        final notifier = ref.read(themeModeProvider.notifier);
        notifier.state = value ? ThemeMode.dark : ThemeMode.light;

        // 3️⃣ Persist (async, non-blocking)
        saveThemeToPrefs(ref, notifier.state);
      },
    );
  }
}
