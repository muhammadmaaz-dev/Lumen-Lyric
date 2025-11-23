import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/presentation/bloc/theme/theme_cubit.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Text(
          'Library Screen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
