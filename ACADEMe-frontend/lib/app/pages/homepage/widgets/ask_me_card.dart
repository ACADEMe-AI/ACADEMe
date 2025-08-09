import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../localization/l10n.dart';
import '../../ask_me/screens/ask_me_screen.dart';
import 'dart:math';

class AskMeCard extends StatelessWidget {
  final TextEditingController messageController;

  const AskMeCard({super.key, required this.messageController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/icons/ASKMe.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'Your Personal Tutor'),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 10, 10, 10),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: "Roboto",
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "ASKMe",
                      style: TextStyle(
                        color: Color.fromARGB(255, 9, 9, 9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      hintText:
                          L10n.getTranslatedText(context, 'ASKMe Anything...'),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Transform.rotate(
                angle: -pi / 4,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 24),
                  onPressed: () {
                    String message = messageController.text.trim();
                    if (message.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AskMeScreen(initialMessage: message),
                        ),
                      );
                      messageController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
