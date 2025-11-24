import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/presentation/bloc/theme/theme_cubit.dart';
import 'package:flutter/cupertino.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

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
      body: SafeArea(
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
                              child: Text('😊', style: TextStyle(fontSize: 60)),
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
                        trailing: CupertinoSwitch(
                          value: isDarkTheme,
                          onChanged: (value) {
                            context.read<ThemeCubit>().toggleTheme();
                          },
                          // Jab switch ON ho to ye color dikhega
                          activeColor: CupertinoColors.activeGreen,

                          // Jab switch OFF ho to ye background color dikhega (Replacement for inactiveTrackColor)
                          trackColor: Colors.grey[300],

                          // Thumb (gola) ka color. Agar state ke hisaab se change karna hai to condition lagani padegi
                          thumbColor: isDarkTheme
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 0, 0),
                        ),
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
                          _buildMenuItem(
                            icon: Icons.favorite_border,
                            title: 'Liked Songs',
                            onTap: () {},
                            textColor: textColor,
                          ),
                          Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 10,
                            endIndent: 10,
                          ),
                          _buildMenuItem(
                            icon: Icons.restore,
                            title: 'Recently Played',
                            onTap: () {},
                            textColor: textColor,
                          ),
                          Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 10,
                            endIndent: 10,
                          ),
                          _buildMenuItem(
                            icon: Icons.download_outlined,
                            title: 'Downloads',
                            onTap: () {},
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
                          _buildMenuItem(
                            icon: Icons.key_outlined,
                            title: 'Change Password',
                            onTap: () {},
                            textColor: textColor,
                          ),
                          Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 10,
                            endIndent: 10,
                          ),
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Linked Account',
                            onTap: () {},
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
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'FAQs',
                            onTap: () {},
                            textColor: textColor,
                          ),
                          Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 10,
                            endIndent: 10,
                          ),
                          _buildMenuItem(
                            icon: Icons.headset_mic_outlined,
                            title: 'Contact Support',
                            onTap: () {},
                            textColor: textColor,
                          ),
                          Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 10,
                            endIndent: 10,
                          ),
                          _buildMenuItem(
                            icon: Icons.bug_report_outlined,
                            title: 'Report a Bug',
                            onTap: () {},
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
    );
  }
}

Widget _buildMenuItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  required Color textColor,
  bool isLast = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 26, color: textColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 24, color: textColor),
          ],
        ),
      ),
    ),
  );
}
