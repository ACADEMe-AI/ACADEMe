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
            behavior: HitTestBehavior.translucent, // Add this line to ensure touches are captured
            child: Swiper(
              controller: controller.swiperController,
              itemWidth: constraints.maxWidth,
              itemHeight: constraints.maxHeight,
              loop: false,
              duration: 300,
              layout: SwiperLayout.STACK,
              axisDirection: AxisDirection.right,
              index: controller.currentPage,
              curve: Curves.easeOutCubic,
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
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: _buildMaterial(index, controller),
                    ),
                    if (controller.currentPage != index)
                      IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
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
              itemCount:
                  controller.materials.length + controller.quizzes.length,
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
          child: _getMaterialWidget(material, index, controller),
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

  const QuizContentWidget(
      {super.key,
      required this.quiz,
      required this.index,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return buildStyledContainer(
      context,
      QuizPage(
        quizzes: [quiz],
        onQuizComplete: () {
          controller.nextMaterialOrQuiz();
        },
        onSwipeToNext: () {
          controller.nextMaterialOrQuiz();
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
