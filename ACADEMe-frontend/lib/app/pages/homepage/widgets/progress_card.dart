import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../localization/l10n.dart';
import '../controllers/home_controller.dart';

class ProgressCard extends StatelessWidget {
  final VoidCallback onTap;

  const ProgressCard({super.key, required this.onTap});

  int _calculateTotalProgress(List<Map<String, dynamic>> courses) {
    if (courses.isEmpty) return 0;

    int totalCompleted = courses.fold<int>(
        0,
            (sum, course) => sum + (course['completedModules'] as int? ?? 0)
    );

    // Base calculation with a multiplier for visual appeal
    return (totalCompleted * 10).clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final progressValue = _calculateTotalProgress(controller.courses);

        return GestureDetector(
          onTap: onTap,
          child: Card(
            color: Colors.indigoAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'My Progress'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          L10n.getTranslatedText(context, 'Track your progress'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 247, 177, 55),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            progressValue.toString(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
