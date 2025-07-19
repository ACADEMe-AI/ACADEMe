// widgets/home/course_card.dart
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const CourseCard(
    this.title,
    this.subtitle,
    this.color, {
    super.key,
    required this.onTap,
  });

  IconData _getSubjectIcon(String title) {
    switch (title.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
        return Icons.calculate;
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science;
      case 'english':
      case 'language':
        return Icons.menu_book;
      case 'computer':
      case 'programming':
      case 'coding':
        return Icons.computer;
      case 'history':
      case 'geography':
      case 'social studies':
        return Icons.public;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.42,
        height: height * 0.20,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getSubjectIcon(title),
              size: width * 0.10,
              color: Colors.black.withAlpha(180),
            ),
            SizedBox(height: height * 0.015),
            AutoSizeText(
              title,
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: height * 0.008),
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: width * 0.035,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}