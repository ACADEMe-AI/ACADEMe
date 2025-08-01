import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
import '../controllers/flash_card_controller.dart';
import 'quiz.dart';
import 'whatsapp_audio.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final FlashCardController controller;

  const ProgressIndicatorWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: List.generate(
              controller.materials.length + controller.quizzes.length, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: controller.currentPage == index
                      ? Colors.yellow[700]
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SubtopicTitleWidget extends StatelessWidget {
  final FlashCardController controller;

  const SubtopicTitleWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
          ],
        ),
        child: Text(
          controller.subtopicTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class FlashCardContentWidget extends StatelessWidget {
  final FlashCardController controller;

  const FlashCardContentWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (_) {
              if (controller.showSwipeHint) {
                controller.hideSwipeHint();
              }
            },
            onPanStart: (_) {
              if (controller.showSwipeHint) {
                controller.hideSwipeHint();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Swiper(
              controller: controller.swiperController,
              itemWidth: constraints.maxWidth,
              itemHeight: constraints.maxHeight,
              loop: false,
              duration: 175, // Increased from 0 to 400ms for slower animation
              layout: SwiperLayout.STACK,
              axisDirection: AxisDirection.right,
              index: controller.currentPage,
              curve: Curves.easeInOutCubic, // Changed to smoother curve
              viewportFraction: 1.0,
              scale: 0.9,
              onIndexChanged: (index) {
                controller.updateCurrentPage(index);
                if (controller.showSwipeHint) {
                  controller.hideSwipeHint();
                }
              },
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    // Only show content if it's the current page or we're not transitioning
                    if (!controller.isTransitioning ||
                        index == controller.currentPage)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: _buildMaterial(index, controller),
                      ),

                    // Show overlay for non-current pages
                    if (controller.currentPage != index &&
                        !controller.isTransitioning)
                      IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300), // Slightly increased duration
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),

                    // Swipe hint overlay
                    if (controller.showSwipeHint && index == 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Image.asset(
                              'assets/images/swipe_left_no_bg.gif',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              itemCount: controller.materials.length + controller.quizzes.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterial(int index, FlashCardController controller) {
    final material = index < controller.materials.length
        ? controller.materials[index]
        : {
            "type": "quiz",
            "quiz": controller.quizzes[index - controller.materials.length],
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedOpacity(
            opacity: controller.isTransitioning && index != controller.currentPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200), // Smooth opacity transition
            child: Container(
              // Add explicit white background to prevent blue background showing
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: controller.isTransitioning && index != controller.currentPage
                  ? Container(
                      // Ensure the placeholder also has white background
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : _getMaterialWidget(material, index, controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMaterialWidget(Map<String, dynamic> material, int index,
      FlashCardController controller) {
    switch (material["type"]) {
      case "text":
        return TextContentWidget(
            content: material["content"]!, controller: controller);
      case "video":
        return VideoContentWidget(controller: controller);
      case "image":
        return ImageContentWidget(
            imageUrl: material["content"]!, controller: controller);
      case "audio":
        return AudioContentWidget(audioUrl: material["content"]!);
      case "document":
        return DocumentContentWidget(docUrl: material["content"]!);
      case "quiz":
        return QuizContentWidget(
            quiz: material["quiz"], index: index, controller: controller);
      default:
        return const Center(child: Text('Unsupported content type'));
    }
  }
}

// Celebration Widget
// class CelebrationWidget extends StatelessWidget {
//   final FlashCardController controller;
//
//   const CelebrationWidget({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     final listenable =
//         controller.celebrationController ?? AlwaysStoppedAnimation(0);
//
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Center(
//           child: AnimatedBuilder(
//             animation: listenable,
//             builder: (context, child) {
//               // Safely get all animation values with null checks
//               final bounceValue = controller.bounceAnimation?.value ?? 0;
//               final scaleValue = controller.scaleAnimation?.value ?? 1;
//               // Use the animation itself, not its value for SlideTransition
//               final slideAnimation = controller.slideAnimation ??
//                   AlwaysStoppedAnimation(Offset.zero);
//               final pulseValue = controller.pulseAnimation?.value ?? 1;
//               final rotateValue = controller.rotateAnimation?.value ?? 0;
//               final controllerValue =
//                   controller.celebrationController?.value ?? 0;
//
//               return Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Transform.scale(
//                     scale: bounceValue,
//                     child: Container(
//                       width: 100,
//                       height: 100,
//                       decoration: BoxDecoration(
//                         color: Colors.yellow[600],
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.yellow.withOpacity(0.5),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.star,
//                         color: Colors.white,
//                         size: 50,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   SlideTransition(
//                     position: slideAnimation,
//                     child: Transform.scale(
//                       scale: scaleValue *
//                           (1.0 +
//                               0.1 *
//                                   (1.0 +
//                                       (pulseValue - 1.0) *
//                                           (1.0 +
//                                               0.5 *
//                                                   (controllerValue * 10) %
//                                                   1.0))),
//                       child: Transform.rotate(
//                         angle: rotateValue *
//                             (1.0 + 0.3 * ((controllerValue * 8) % 1.0 - 0.5)),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 30, vertical: 15),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.green[400]!,
//                                 Colors.green[600]!,
//                                 Colors.green[400]!,
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               stops: [
//                                 0.0,
//                                 0.5 + 0.3 * ((controllerValue * 5) % 1.0),
//                                 1.0,
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(25),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.green.withOpacity(0.4),
//                                 blurRadius:
//                                 15 + 5 * ((controllerValue * 6) % 1.0),
//                                 spreadRadius: 2,
//                               ),
//                             ],
//                           ),
//                           child: const Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.check_circle,
//                                 color: Colors.white,
//                                 size: 24,
//                               ),
//                               SizedBox(width: 10),
//                               Text(
//                                 'Great Job! 🌟',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ...List.generate(8, (index) {
//                     final delay = index * 0.1;
//                     final animationValue =
//                     (controllerValue - delay).clamp(0.0, 1.0);
//                     final continuousMotion =
//                         (controllerValue * 4 + index) % 1.0;
//                     return Transform.translate(
//                       offset: Offset(
//                         (index - 4) * 40.0 * animationValue +
//                             20 * continuousMotion * (index % 2 == 0 ? 1 : -1),
//                         -30 * animationValue +
//                             10 * continuousMotion * (index % 3 == 0 ? 1 : -1),
//                       ),
//                       child: Transform.scale(
//                         scale: animationValue * (0.8 + 0.4 * continuousMotion),
//                         child: Transform.rotate(
//                           angle: continuousMotion * 6.28,
//                           child: Container(
//                             width: 18,
//                             height: 18,
//                             decoration: BoxDecoration(
//                               color: [
//                                 Colors.red,
//                                 Colors.blue,
//                                 Colors.green,
//                                 Colors.orange,
//                                 Colors.purple,
//                                 Colors.pink,
//                                 Colors.teal,
//                                 Colors.amber
//                               ][index],
//                               shape: BoxShape.circle,
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Colors.black26,
//                                   blurRadius: 3,
//                                   spreadRadius: 1,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }



// Content Widgets
class TextContentWidget extends StatelessWidget {
  final String content;
  final FlashCardController controller;

  const TextContentWidget(
      {super.key, required this.content, required this.controller});

  @override
  Widget build(BuildContext context) {
    String processedContent =
    content.replaceAll(r'\n', '\n').replaceAll('<br>', '\n');

    return buildStyledContainer(
      context,
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _formattedText(processedContent),
              ),
            ),
            if (controller.quizzes.isEmpty &&
                controller.currentPage == controller.materials.length - 1)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.onQuizComplete != null) {
                      controller.onQuizComplete!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Mark as Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _formattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 16));
        continue;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isSpecialLine(line) ? Colors.transparent : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _parseLineContent(line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _parseLineContent(String line) {
    if (line.startsWith('#')) {
      return _processHeading(line);
    }
    if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
      return _buildBulletPoint(line);
    }
    if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
      return _buildNumberedListItem(line);
    }
    if (line.trim().startsWith('> ')) {
      return _buildQuote(line);
    }
    return _parseInlineFormatting(line);
  }

  bool _isSpecialLine(String line) {
    return line.startsWith('#') ||
        line.trim().startsWith('- ') ||
        line.trim().startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(line.trim()) ||
        line.trim().startsWith('> ');
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Icon(
            Icons.circle,
            size: 10,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _parseInlineFormatting(
            text.replaceFirst(RegExp(r'^[-*]\s+'), ''),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedListItem(String text) {
    final numberMatch = RegExp(r'^(\d+)\.').firstMatch(text);
    final number = numberMatch?.group(1) ?? '•';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$number.',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _parseInlineFormatting(
            text.replaceFirst(RegExp(r'^\d+\.\s+'), ''),
          ),
        ),
      ],
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.blue[300]!, width: 4)),
        color: Colors.blue[50],
      ),
      child: _parseInlineFormatting(
        text.replaceFirst('> ', ''),
      ),
    );
  }

  Widget _parseInlineFormatting(String text,
      {bool isHeading = false, int level = 1}) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    final pattern = RegExp(
      r'(\*\*(.*?)\*\*|__(.*?)__|\*(.*?)\*|_(.*?)_|`(.*?)`|\[(.*?)\]\((.*?)\))',
      dotAll: true,
    );

    while (true) {
      final match = pattern.firstMatch(text.substring(lastIndex));
      if (match == null) break;

      if (match.start > 0) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, lastIndex + match.start),
          style: _getBaseTextStyle(isHeading, level),
        ));
      }

      if (match.group(1) != null) {
        spans.add(_createStyledSpan(match, isHeading, level));
      }

      lastIndex += match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: _getBaseTextStyle(isHeading, level),
      ));
    }

    return RichText(
      text: TextSpan(
        style: _getBaseTextStyle(isHeading, level),
        children: spans,
      ),
    );
  }

  TextSpan _createStyledSpan(RegExpMatch match, bool isHeading, int level) {
    final baseStyle = _getBaseTextStyle(isHeading, level);

    if (match.group(2) != null) {
      return TextSpan(
        text: match.group(2),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple[800],
        ),
      );
    } else if (match.group(3) != null) {
      return TextSpan(
        text: match.group(3),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.amber[50],
        ),
      );
    } else if (match.group(4) != null) {
      return TextSpan(
        text: match.group(4),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.teal[800],
        ),
      );
    } else if (match.group(5) != null) {
      return TextSpan(
        text: match.group(5),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
          decorationColor: Colors.teal[300],
        ),
      );
    } else if (match.group(6) != null) {
      return TextSpan(
        text: match.group(6),
        style: baseStyle.copyWith(
          fontFamily: 'FiraCode',
          backgroundColor: Colors.grey[100],
        ),
      );
    } else if (match.group(7) != null) {
      return TextSpan(
        text: match.group(7),
        style: baseStyle.copyWith(
          color: Colors.blue[700],
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue[300],
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(match.group(8)!)),
      );
    }

    return TextSpan(text: match.group(0), style: baseStyle);
  }

  TextStyle _getBaseTextStyle(bool isHeading, int level) {
    return TextStyle(
      fontSize: isHeading ? _getHeadingSize(level) : 17,
      fontWeight: isHeading ? FontWeight.w800 : FontWeight.w400,
      color: Colors.grey[850],
      height: 1.6,
      letterSpacing: isHeading ? -0.5 : 0.3,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none,
    );
  }

  double _getHeadingSize(int level) {
    switch (level) {
      case 1:
        return 24;
      case 2:
        return 20;
      case 3:
        return 18;
      default:
        return 16;
    }
  }

  Widget _processHeading(String line) {
    final level = line.split(' ')[0].length;
    final content = line.substring(level).trim();

    return Padding(
      padding: EdgeInsets.only(
        top: level == 1 ? 24 : 16,
        bottom: 12,
      ),
      child: _parseInlineFormatting(
        content,
        isHeading: true,
        level: level.clamp(1, 3),
      ),
    );
  }
}

class VideoContentWidget extends StatelessWidget {
  final FlashCardController controller;

  const VideoContentWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(0),
              child: controller.chewieController == null ||
                  controller.videoController == null ||
                  !controller.videoController!.value.isInitialized
                  ? SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      "Loading video...",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : SizedBox.expand(
                child: Chewie(controller: controller.chewieController!),
              ),
            ),
          ),
          if (controller.quizzes.isEmpty &&
              controller.currentPage == controller.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (controller.onQuizComplete != null) {
                    controller.onQuizComplete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Mark as Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ImageContentWidget extends StatelessWidget {
  final String imageUrl;
  final FlashCardController controller;

  const ImageContentWidget(
      {super.key, required this.imageUrl, required this.controller});

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<BoxFit>(
                future: _getImageFit(imageUrl),
                builder: (context, snapshot) {
                  BoxFit fit = snapshot.data ?? BoxFit.cover;
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
                    fit: fit,
                    alignment: Alignment.center,
                  );
                },
              ),
            ),
          ),
          if (controller.quizzes.isEmpty &&
              controller.currentPage == controller.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (controller.onQuizComplete != null) {
                    controller.onQuizComplete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Mark as Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<BoxFit> _getImageFit(String imageUrl) async {
    final Completer<ImageInfo> completer = Completer();
    final ImageStream stream =
    NetworkImage(imageUrl).resolve(const ImageConfiguration());

    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      completer.completeError(exception);
    });

    stream.addListener(listener);

    try {
      final ImageInfo imageInfo = await completer.future;
      final int width = imageInfo.image.width;
      final int height = imageInfo.image.height;
      stream.removeListener(listener);

      if (width > height) {
        return BoxFit.contain;
      } else {
        return BoxFit.cover;
      }
    } catch (e) {
      stream.removeListener(listener);
      return BoxFit.cover;
    }
  }
}

class AudioContentWidget extends StatelessWidget {
  final String audioUrl;

  const AudioContentWidget({super.key, required this.audioUrl});

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: WhatsAppAudioPlayer(audioUrl: audioUrl),
      ),
    );
  }
}

class DocumentContentWidget extends StatelessWidget {
  final String docUrl;

  const DocumentContentWidget({super.key, required this.docUrl});

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      Column(children: [
        Expanded(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                debugPrint("Document URL: $docUrl");
                launchUrl(Uri.parse(docUrl));
              },
              child: const Text('Open Document'),
            ),
          ),
        ),
      ]),
    );
  }
}

class QuizContentWidget extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final int index;
  final FlashCardController controller;

  const QuizContentWidget({
    super.key,
    required this.quiz,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      QuizPage(
        quizzes: [quiz],
        onQuizComplete: () {
          // Use post-frame callback to ensure smooth transition
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.nextMaterialOrQuiz();
          });
        },
        courseId: controller.courseId,
        topicId: controller.topicId,
        subtopicId: controller.subtopicId,
        subtopicTitle: quiz['title'] ?? 'Untitled Quiz',
        hasNextMaterial: index <
            (controller.materials.length + controller.quizzes.length - 1),
      ),
    );
  }
}

Widget buildStyledContainer(BuildContext context, Widget child) {
  final height = MediaQuery.of(context).size.height;
  return Center(
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: height * 1.5),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: child,
      ),
    ),
  );
}