import 'package:flutter/material.dart';

class LearningCard extends StatelessWidget {
  final String title;
  final int completed;
  final int total;
  final int percentage;
  final Color color;
  final VoidCallback onTap;

  const LearningCard({
    super.key,
    required this.title,
    required this.completed,
    required this.total,
    required this.percentage,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("$completed / $total"),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    color: Colors.blue,
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
                  onPressed: onTap,
                ),
                const SizedBox(height: 10),
                Text("$percentage%"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
