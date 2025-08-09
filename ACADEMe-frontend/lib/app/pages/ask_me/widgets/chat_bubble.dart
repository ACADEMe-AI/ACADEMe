import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [Colors.blueAccent.shade400, AcademeTheme.appColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _parseInlineBoldText(text, isUser),
      ),
    );
  }

  Widget _parseInlineBoldText(String text, bool isUser) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));

    for (int i = 0; i < parts.length; i++) {
      bool isBold = i % 2 == 1;

      spans.add(TextSpan(
        text: parts[i],
        style: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          height: 1.4,
          color: isUser ? Colors.white : Colors.black87,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
