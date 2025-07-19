import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isUser
            ? MediaQuery.of(context).size.width * 0.60
            : MediaQuery.of(context).size.width * 0.80,
      ),
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
          colors: [
            Colors.blue[300]!,
            Colors.blue[700]!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isUser ? null : Colors.grey[300]!,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUser
            ? [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _parseInlineBoldText(text, isUser),
        ],
      ),
    );
  }

  Widget _parseInlineBoldText(String text, bool isUser) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
