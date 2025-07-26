import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';

class NewChatIcon extends StatelessWidget {
  const NewChatIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AcademeTheme.appColor, shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
                color: AcademeTheme.appColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child:
            const Center(child: Icon(Icons.add, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
