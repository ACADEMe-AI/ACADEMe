import 'package:flutter/material.dart';
import '../../../../localization/l10n.dart';

class CourseTagsRow extends StatelessWidget {
  final bool isSecondRow;

  const CourseTagsRow({super.key, this.isSecondRow = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: isSecondRow ? Colors.blue : Colors.red, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isSecondRow ? Colors.blue : Colors.red).withAlpha(50),
                  ),
                  child: Icon(
                    isSecondRow ? Icons.language : Icons.book,
                    size: 16,
                    color: isSecondRow ? Colors.blue : Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  L10n.getTranslatedText(
                      context, isSecondRow ? 'Language' : 'English'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSecondRow ? Colors.green : Colors.orange, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isSecondRow ? Colors.green : Colors.orange)
                        .withAlpha(50),
                  ),
                  child: Icon(
                    isSecondRow ? Icons.science : Icons.calculate,
                    size: 16,
                    color: isSecondRow ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  L10n.getTranslatedText(
                      context, isSecondRow ? 'Biology' : 'Maths'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}