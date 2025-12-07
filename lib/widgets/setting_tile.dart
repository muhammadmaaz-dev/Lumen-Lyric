import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDarkTheme;

  const SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDarkTheme,
    required Color textColor,
    bool isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400] : Colors.grey;

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
}
