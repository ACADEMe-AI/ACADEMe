import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/flash_card_controller.dart';
import '../widgets/flash_card_widget.dart';
import 'package:ACADEMe/academe_theme.dart';

class FlashCardScreen extends StatefulWidget {
  final FlashCardController controller;

  const FlashCardScreen({super.key, required this.controller});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Initialize animations when the widget is created
    widget.controller.initializeAnimations(this);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
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
                L10n.getTranslatedText(context, 'Subtopic Materials'),
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
