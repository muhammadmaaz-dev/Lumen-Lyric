import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          radius: 55.r,
          backgroundColor: Colors.grey.shade300,
          child: CircleAvatar(
            radius: 52.r,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(avatarPath),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          name,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          email,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
