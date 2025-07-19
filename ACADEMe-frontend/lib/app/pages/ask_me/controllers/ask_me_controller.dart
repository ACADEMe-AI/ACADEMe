import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:open_file/open_file.dart';

class AskMeController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  String selectedLanguage = "en";
  List<ChatMessage> chatMessages = [];

  final TextEditingController textController = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();
  bool isRecording = false;
  Timer? timer;
  int seconds = 0;
  bool isConverting = false;

  String searchQuery = "";
  List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'German', 'code': 'de'},
    {'name': 'Hindi', 'code': 'hi'},
    {'name': 'Chinese', 'code': 'zh'},
    {'name': 'Japanese', 'code': 'ja'},
    {'name': 'Bengali', 'code': 'bn'},
  ];

  final Map<String, Map<String, String>> errorMessages = {
    'server_error': {
      'en': 'Oops! Something went wrong. Please try again.',
      'es': '¡Vaya! Algo salió mal. Por favor, inténtalo de nuevo.',
      'fr': 'Oups ! Quelque chose s\'est mal passé. Veuillez réessayer.',
      'de': 'Ups! Etwas ist schief gelaufen. Bitte versuche es erneut.',
      'hi': 'उफ़! कुछ गलत हो गया। कृपया पुनः प्रयास करें।',
      'zh': '哎呀！出了点问题。请再试一次。',
      'ja': 'おっと！問題が発生しました。もう一度お試しください。',
      'bn': 'ওহ! কিছু ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
    },
    'connection_error': {
      'en': 'Error connecting to the server. Please check your internet connection.',
      'es': 'Error al conectar con el servidor. Por favor, revise su conexión a internet.',
      'fr': 'Erreur de connexion au serveur. Veuillez vérifier votre connexion Internet.',
      'de': 'Fehler beim Verbinden mit dem Server. Bitte überprüfen Sie Ihre Internetverbindung.',
      'hi': 'सर्वर से कनेक्ट करने में त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।',
      'zh': '连接服务器出错。请检查您的互联网连接。',
      'ja': 'サーバーへの接続エラー。インターネット接続を確認してください。',
      'bn': 'সার্ভারের সাথে সংযোগে ত্রুটি হয়েছে। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
    },
  };

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void startNewChat() {
    chatMessages.clear();
    textController.clear();
    isRecording = false;
    timer?.cancel();
    seconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> initRecorder() async {
    bool hasPermission = await audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint("Recording permission not granted.");
    }
  }

  String getTranslatedError(String key, String langCode) {
    return errorMessages[key]?[langCode] ??
        errorMessages[key]?['en'] ??
        'An error occurred';
  }

  Future<void> pickFile(BuildContext context, String fileType) async {
    FileType type;
    List<String>? allowedExtensions;

    switch (fileType) {
      case 'Image':
        type = FileType.image;
        break;
      case 'Document':
        type = FileType.custom;
        allowedExtensions = ['pdf', 'docx', 'txt'];
        break;
      case 'Video':
        type = FileType.video;
        break;
      case 'Audio':
        type = FileType.audio;
        break;
      default:
        debugPrint("❌ Invalid file type.");
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: (type == FileType.custom) ? allowedExtensions : null,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      showPromptDialog(context, file, fileType);
    } else {
      debugPrint("❌ File selection canceled.");
    }
  }

  void showPromptDialog(BuildContext context, File file, String fileType) {
    TextEditingController promptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getTranslatedText(context, 'Add Optional Prompt')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(file.path.split('/').last),
              subtitle: Text("${(file.lengthSync() / 1024).toStringAsFixed(1)}KB"),
            ),
            TextField(
              controller: promptController,
              decoration: InputDecoration(
                hintText: L10n.getTranslatedText(context, 'Enter your prompt (optional)'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              uploadFile(file, fileType, promptController.text);
            },
            child: Text(L10n.getTranslatedText(context, 'Upload')),
          ),
        ],
      ),
    );
  }

  Future<void> uploadFile(File file, String fileType, String prompt) async {
    var url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_${fileType.toLowerCase()}');

    var request = http.MultipartRequest('POST', url);
    request.fields.addAll({
      'prompt': prompt.isNotEmpty ? prompt : 'Describe this file',
      'source_lang': 'auto',
      'target_lang': selectedLanguage,
    });

    String fileFieldName = (fileType == 'Image') ? 'image' : 'file';
    String? mimeType = lookupMimeType(file.path);
    mimeType ??=
    (fileType == 'Video') ? 'video/mp4' : 'application/octet-stream';

    request.files.add(await http.MultipartFile.fromPath(
      fileFieldName,
      file.path,
      contentType: MediaType.parse(mimeType),
    ));

    // Add user message to chat
    chatMessages.add(ChatMessage(
      role: "user",
      text: prompt.isNotEmpty ? prompt : "Uploaded $fileType",
      fileInfo: file.path,
      fileType: fileType,
      status: prompt.isNotEmpty ? prompt : "Processing...",
    ));

    // Add a "typing indicator" for the AI response
    chatMessages.add(ChatMessage(
      role: "assistant",
      isTyping: true,
    ));
    notifyListeners();

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);
        String aiResponse = decodedResponse is Map<String, dynamic>
            ? decodedResponse.values.first.toString()
            : responseBody;

        // Remove typing indicator
        chatMessages.removeWhere((msg) => msg.isTyping == true);

        // Add actual AI response
        chatMessages.add(ChatMessage(
          role: "assistant",
          text: aiResponse,
        ));
        notifyListeners();
      } else {
        chatMessages.removeWhere((msg) => msg.isTyping == true);
        chatMessages.add(ChatMessage(
          role: "assistant",
          text: "⚠️ Error uploading file: $responseBody",
        ));
        notifyListeners();
      }
    } catch (e) {
      chatMessages.removeWhere((msg) => msg.isTyping == true);
      chatMessages.add(ChatMessage(
        role: "assistant",
        text: "⚠️ Error connecting to server.",
      ));
      notifyListeners();
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      // Stop recording
      String? path = await audioRecorder.stop();
      isRecording = false;
      timer?.cancel();
      seconds = 0;
      notifyListeners();

      if (path != null) {
        File file = File(path);
        debugPrint(
            "Audio file path: $path, Size: ${file.existsSync() ? file.lengthSync() : 'File not found'} bytes");

        if (file.existsSync()) {
          debugPrint("File exists, uploading...");
          await uploadSpeech(file);
        } else {
          debugPrint("File does NOT exist. Path: $path");
        }
      } else {
        debugPrint("Recording path is null.");
      }
    } else {
      // Request microphone permission
      PermissionStatus micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint("Microphone permission not granted.");
        return;
      }

      // Prepare file path for recording in WAV format
      Directory tempDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        // Start recording with WAV format
        debugPrint("Starting recording at path: $filePath");
        await audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav), // WAV format
          path: filePath,
        );

        isRecording = true;
        seconds = 0;
        notifyListeners();

        // Timer for tracking recording duration
        timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          seconds++;
          notifyListeners();
        });
      } catch (e) {
        debugPrint("Error starting recording: $e");
      }
    }
  }

  Future<void> uploadSpeech(File file) async {
    try {
      if (!file.existsSync() || file.lengthSync() == 0) {
        debugPrint("❌ File does not exist or is empty.");
        return;
      }
      debugPrint("File size: ${file.lengthSync()} bytes");

      isConverting = true;
      notifyListeners();

      // Backend API URL
      var url = Uri.parse(
          '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_stt');

      var request = http.MultipartRequest('POST', url);

      // Ensure the selected language is not empty
      selectedLanguage = selectedLanguage.isNotEmpty ? selectedLanguage : "hi";
      debugPrint("Selected target language: $selectedLanguage");

      request.fields.addAll({
        'prompt': 'इस ऑडियो को हिंदी में लिखो',
        'source_lang': 'auto', // Let the server detect the source language
        'target_lang': selectedLanguage, // Send the selected language for the response
      });

      final mimeType = lookupMimeType(file.path) ?? "audio/flac";
      debugPrint("Detected MIME type: $mimeType");

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      debugPrint("Server response: $responseBody");

      if (response.statusCode == 200) {
        debugPrint("✅ Audio uploaded successfully!");

        var decodedResponse = jsonDecode(responseBody);

        // Fix: Extract detected language correctly
        String detectedLang = decodedResponse['language'] ?? 'unknown';
        debugPrint("Detected Language: $detectedLang");

        // If the detected language is Hindi and user hasn't explicitly chosen another language
        if (detectedLang == 'hi' && selectedLanguage == "auto") {
          selectedLanguage = 'hi'; // Update language to Hindi
          notifyListeners();
          debugPrint("✅ Updated selected language to Hindi");
        }

        // Proceed with handling the server response (your AI response)
        await handleServerResponse(decodedResponse);
      } else {
        debugPrint("❌ Upload failed with status: ${response.statusCode}");
        debugPrint("Server response: $responseBody");

        ScaffoldMessenger.of(Global.context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(Global.context, '❌ Something went wrong. Hugging Face may be down.')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error uploading audio: $e");
      ScaffoldMessenger.of(Global.context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(Global.context, '❌ Error uploading audio. Hugging Face may be down.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      isConverting = false;
      notifyListeners();
    }
  }

  Future<void> handleServerResponse(Map<String, dynamic> response) async {
    try {
      if (response.containsKey('text')) {
        String responseText = response['text'];

        // Update the input field with the 'text' part of the response
        textController.text = responseText;
        notifyListeners();
      } else {
        debugPrint("❌ No text key in server response");
      }
    } catch (e) {
      debugPrint("❌ Error handling server response: $e");
    }
  }

  void sendMessage(String message) async {
    chatMessages.add(ChatMessage(role: "user", text: message));
    chatMessages.add(ChatMessage(role: "assistant", isTyping: true));
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    var url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_text');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': message, 'target_language': selectedLanguage},
      );

      if (response.statusCode == 200) {
        String aiResponse = utf8.decode(response.bodyBytes);
        String aiMessage = jsonDecode(aiResponse)['response'];

        // Replace the typing indicator with the actual message
        chatMessages.removeLast();
        chatMessages.add(ChatMessage(role: "assistant", text: aiMessage));
        notifyListeners();

        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToBottom();
        });
      } else {
        chatMessages.removeLast();
        chatMessages.add(ChatMessage(
          role: "assistant",
          text: getTranslatedError('server_error', selectedLanguage),
        ));
        notifyListeners();
      }
    } catch (error) {
      chatMessages.removeLast();
      chatMessages.add(ChatMessage(
        role: "assistant",
        text: getTranslatedError('connection_error', selectedLanguage),
      ));
      notifyListeners();
    }
  }
}

class Global {
  static late BuildContext context;
}
