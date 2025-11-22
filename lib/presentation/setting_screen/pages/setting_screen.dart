import 'package:flutter/material.dart';
import 'package:musicapp/presentation/widgets/CircleAvatar/circle_avatar.dart';
import 'package:musicapp/presentation/widgets/SettingTile/setting_tile.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 120),
              Center(
                child: ProfileHeader(
                  avatarPath: "assets/images/demoimage.png",
                  name: "Muhammad Maaz",
                  email: "muhammad.maaz@gmail.com",
                ),
              ),

              // Section Title
              const Text(
                "Library & Activity",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Reusable Tiles
              SettingsTile(
                icon: Icons.favorite_border,
                title: "Liked Songs",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              SettingsTile(
                icon: Icons.history,
                title: "Recently Played",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              SettingsTile(
                icon: Icons.download,
                title: "Downloads",
                onTap: () {},
              ),

              const SizedBox(height: 25),

              const Text(
                "Privacy & Security",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SettingsTile(
                icon: Icons.key,
                title: "Change Password",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              SettingsTile(
                icon: Icons.person_outline,
                title: "Linked Account",
                onTap: () {},
              ),

              const SizedBox(height: 25),

              const Text(
                "Library & Activity",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SettingsTile(
                icon: Icons.help_outline,
                title: "FAQs",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              SettingsTile(
                icon: Icons.headset_mic_outlined,
                title: "Contact Support",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              SettingsTile(
                icon: Icons.bug_report_outlined,
                title: "Report a Bug",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
