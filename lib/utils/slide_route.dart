import 'package:flutter/material.dart';

class SlideRightToLeftRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightToLeftRoute({required this.page})
    : super(
        // Animation Duration (Aap isay kam ya zyada kar sakte hain)
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 200),

        pageBuilder: (context, animation, secondaryAnimation) => page,

        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Screen starts from Right (X=1.0)
          const begin = Offset(1.0, 0.0);
          // Screen ends at Center (X=0.0)
          const end = Offset.zero;
          // Smooth Curve used for professional feel
          const curve = Curves.easeOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
