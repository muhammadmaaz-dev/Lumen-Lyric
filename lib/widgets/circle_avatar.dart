import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String avatarPath; // asset or network
  final String name;
  final String email;

  const ProfileHeader({
    Key? key,
    required this.avatarPath,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.grey.shade300,
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(avatarPath),
            // For network:
            // backgroundImage: NetworkImage(avatarPath),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
      ],
    );
  }
}
