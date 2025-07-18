import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../controllers/ask_me_controller.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../models/chat_message.dart';
import '../widgets/attachment_options_sheet.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/file_view.dart';
import '../widgets/full_screen_video.dart';
import '../widgets/language_selection_sheet.dart';
import '../widgets/new_chat_icon.dart';
import '../widgets/typing_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AskMeScreen extends StatefulWidget {
  final String? initialMessage;
  const AskMeScreen({super.key, this.initialMessage});

  @override
  State<AskMeScreen> createState() => _AskMeScreenState();
}

class _AskMeScreenState extends State<AskMeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Global.context = context;
  }

  void _loadChatSession(ChatSession chat) {
    debugPrint("Selected chat: ${chat.title}");
  }

  @override
  Widget build(BuildContext context) {
    List<ChatSession> chatHistory = [
      ChatSession(
          title: L10n.getTranslatedText(context, 'Chat with AI'),
          timestamp: "Feb 22, 2025"),
      ChatSession(
          title: L10n.getTranslatedText(context, 'Math Help'),
          timestamp: "Feb 21, 2025"),
    ];

    return ChangeNotifierProvider(
      create: (context) => AskMeController(),
      child: Consumer<AskMeController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(controller),
            drawer: ChatHistoryDrawer(
              chatHistory: chatHistory,
              onSelectChat: (chat) {
                _loadChatSession(chat);
              },
            ),
            body: controller.chatMessages.isEmpty
                ? _buildInitialUI(context)
                : _buildChatUI(context, controller),
            bottomNavigationBar: _buildInputBar(context, controller),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(AskMeController controller) {
    return AppBar(
      backgroundColor: AcademeTheme.appColor,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: false,
      title: SizedBox(
        height: kToolbarHeight,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.menu, size: 28, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
            const Center(
              child: Text(
                'ASKMe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const NewChatIcon(),
                    onPressed: controller.startNewChat,
                  ),
                  IconButton(
                    icon: const Icon(Icons.translate, size: 28, color: Colors.white),
                    onPressed: () {
                      _showLanguageSelection(context, controller);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelection(BuildContext context, AskMeController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return LanguageSelectionSheet(
          languages: controller.languages,
          selectedLanguage: controller.selectedLanguage,
          onLanguageSelected: (code) {
            controller.selectedLanguage = code;
            controller.notifyListeners();
          },
        );
      },
    );
  }

  Widget _buildInitialUI(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Image.asset('assets/icons/ASKMe_dark.png',
                    width: width * 0.3, height: height * 0.09),
                SizedBox(height: height * 0.01),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: L10n.getTranslatedText(
                              context, 'Hey there! I am '),
                          style: _textStyle(Colors.black)),
                      TextSpan(
                          text: 'ASKMe', style: _textStyle(Colors.amber[700]!)),
                      TextSpan(
                          text: L10n.getTranslatedText(
                              context, ' your\npersonal tutor.'),
                          style: _textStyle(Colors.black)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: height * 0.03),
            Wrap(
              spacing: width * 0.03,
              runSpacing: height * 0.01,
              alignment: WrapAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      context,
                      Icons.help_outline,
                      L10n.getTranslatedText(context, 'Clear Your Doubts'),
                      Colors.lightBlue.shade400,
                      width,
                    ),
                    SizedBox(width: width * 0.03),
                    _buildButton(
                      context,
                      Icons.quiz,
                      L10n.getTranslatedText(context, 'Explain / Quiz'),
                      Colors.orange.shade400,
                      width,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      context,
                      Icons.upload_file,
                      L10n.getTranslatedText(context, 'Upload Study Materials'),
                      Colors.green.shade500,
                      width,
                    ),
                    SizedBox(width: width * 0.03),
                    _buildButton(
                      context,
                      Icons.more_horiz,
                      L10n.getTranslatedText(context, 'More'),
                      Colors.grey,
                      width,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600);
  }

  Widget _buildButton(BuildContext context, IconData icon, String text, Color color, double width) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.03, vertical: height * 0.01),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon, size: width * 0.05),
      label: SizedBox(
        width: width * 0.25,
        child: AutoSizeText(
          text,
          maxLines: 1,
          minFontSize: 10,
          stepGranularity: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildChatUI(BuildContext context, AskMeController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      controller: controller.scrollController,
      itemCount: controller.chatMessages.length,
      itemBuilder: (context, index) {
        ChatMessage message = controller.chatMessages[index];
        bool isUser = message.role == "user";

        return Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.fileInfo != null && message.fileType != null)
              _buildFilePreview(context, message),
            if (message.text != null && message.isTyping != true)
              ChatBubble(
                text: message.text!,
                isUser: isUser,
              ),
            if (!isUser && message.isTyping != true)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.flag, color: Colors.grey[600], size: 18),
                    onPressed: () {
                      _showReportDialog(context, message);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(L10n.getTranslatedText(context, 'Copied to clipboard')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            if (message.isTyping == true) const TypingIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildFilePreview(BuildContext context, ChatMessage message) {
    switch (message.fileType) {
      case 'Image':
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImage(imagePath: message.fileInfo!),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(message.fileInfo!),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'Video':
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenVideo(videoPath: message.fileInfo!),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black12,
                ),
              ),
              const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
            ],
          ),
        );
      case 'Audio':
        return Container(
          width: MediaQuery.of(context).size.width * 0.75,
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: AudioPlayerWidget(audioPath: message.fileInfo!),
        );
      default: // Document
        return GestureDetector(
          onTap: () {
            OpenFile.open(message.fileInfo);
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.55,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    L10n.getTranslatedText(context, 'Open Document'),
                    style: const TextStyle(color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  void _showReportDialog(BuildContext context, ChatMessage message) {
    TextEditingController reportController = TextEditingController();
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Report Message')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(L10n.getTranslatedText(context, 'Please describe the issue:')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reportController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "${L10n.getTranslatedText(context, 'Enter your reason for reporting')}...",
                    ),
                    onChanged: (text) {
                      setState(() {
                        isButtonEnabled = text.trim().isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.getTranslatedText(context, 'Cancel')),
                ),
                TextButton(
                  onPressed: isButtonEnabled
                      ? () {
                    _submitReport(message, reportController.text);
                    Navigator.pop(context);
                  }
                      : null,
                  child: Text(L10n.getTranslatedText(context, 'Send')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitReport(ChatMessage message, String reportReason) {
    print("Reported message: ${message.text} | Reason: $reportReason");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.getTranslatedText(context, 'Report submitted.')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AskMeController controller) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                icon: Icon(Icons.attach_file,
                    color: AcademeTheme.appColor, size: 27),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext context) {
                      return AttachmentOptionsSheet(
                        onImageSelected: () => controller.pickFile(context, 'Image'),
                        onDocumentSelected: () => controller.pickFile(context, 'Document'),
                        onVideoSelected: () => controller.pickFile(context, 'Video'),
                        onAudioSelected: () => controller.pickFile(context, 'Audio'),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: controller.textController,
                    maxLines: 2,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: controller.isConverting
                          ? L10n.getTranslatedText(context, 'Converting ... ')
                          : (controller.isRecording
                          ? '${L10n.getTranslatedText(
                          context, 'Recording')}... ${controller.seconds}s'
                          : L10n.getTranslatedText(
                          context, 'Type a message ...')),
                      contentPadding: const EdgeInsets.only(
                          left: 20, right: 60, top: 14, bottom: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                        BorderSide(color: Colors.grey[300]!, width: 1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    child: GestureDetector(
                      onTap: controller.toggleRecording,
                      child: Icon(
                        controller.isRecording ? Icons.stop : Icons.mic,
                        color: AcademeTheme.appColor,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.textController,
              builder: (context, value, child) {
                final bool isEmpty = value.text.trim().isEmpty;
                return SizedBox(
                  width: 42,
                  height: 42,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: isEmpty ? Colors.grey : AcademeTheme.appColor,
                      size: 25,
                    ),
                    onPressed: isEmpty
                        ? null
                        : () {
                      String message = controller.textController.text.trim();
                      controller.sendMessage(message);
                      controller.textController.clear();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
