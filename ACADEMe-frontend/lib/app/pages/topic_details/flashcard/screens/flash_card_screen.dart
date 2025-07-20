import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/flash_card_controller.dart';
import '../widgets/flash_card_widget.dart';
import 'package:ACADEMe/academe_theme.dart';

class FlashCardScreen extends StatelessWidget {
  final FlashCardController controller;

  const FlashCardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<FlashCardController>(
        builder: (context, controller, child) {
          if (controller.materials.isEmpty && controller.quizzes.isEmpty) {
            return Scaffold(
              backgroundColor: Theme.of(context).primaryColor,
              body: Container(),
            );
          }

          return Scaffold(
            backgroundColor: AcademeTheme.appColor,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Subtopic Materials',
                style: TextStyle(
                    color: Colors.black, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18),
              ),
              centerTitle: true,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressIndicatorWidget(controller: controller),
                SubtopicTitleWidget(controller: controller),
                Expanded(
                  child: FlashCardContentWidget(controller: controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}