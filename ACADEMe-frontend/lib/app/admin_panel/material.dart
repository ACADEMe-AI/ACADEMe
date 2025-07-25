import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../../api_endpoints.dart';
import '../../localization/language_provider.dart'; // Import the LanguageProvider

class MaterialScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String? subtopicId; // Optional subtopicId
  final String materialId;
  final String materialType;
  final String materialCategory;
  final String? optionalText;
  final String? textContent;
  final String? fileUrl;

  const MaterialScreen({super.key, 
    required this.courseId,
    required this.topicId,
    this.subtopicId,
    required this.materialId,
    required this.materialType,
    required this.materialCategory,
    this.optionalText,
    this.textContent,
    this.fileUrl,
  });

  @override
  MaterialScreenState createState() => MaterialScreenState();
}

class MaterialScreenState extends State<MaterialScreen> {
  final _storage = FlutterSecureStorage();
  bool isLoading = true;
  Map<String, dynamic>? materialDetails;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _fetchMaterialDetails();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _fetchMaterialDetails() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    // Construct the URL based on whether subtopicId is provided
    final url = widget.subtopicId == null
        ? ApiEndpoints.getUri(ApiEndpoints.topicMaterials(widget.courseId, widget.topicId, targetLanguage))
        : ApiEndpoints.getUri(ApiEndpoints.subtopicMaterials(widget.courseId, widget.topicId, widget.subtopicId!, targetLanguage));

    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final material = data.firstWhere(
              (material) => material["id"] == widget.materialId,
          orElse: () => null,
        );

        if (material != null) {
          setState(() {
            materialDetails = material;
            isLoading = false;
          });

          // Initialize video player if the material is a video
          if (material["type"] == "video" && material["content"] != null) {
            _initializeVideoPlayer(material["content"]);
          }
        } else {
          _showError("Material not found");
        }
      } else {
        _showError("Failed to fetch material details: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching material details: $e");
    }
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.networkUrl(videoUrl as Uri)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: false,
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
          );
        });
      });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  Future<void> _launchFile(String fileUrl) async {
    if (await canLaunchUrl(fileUrl as Uri)) {
      await launchUrl(fileUrl as Uri);
    } else {
      _showError("Could not launch file: $fileUrl");
    }
  }

  Widget _buildMaterialContent() {
    if (materialDetails == null) {
      return Center(child: Text(L10n.getTranslatedText(context, 'No content available')));
    }

    final type = materialDetails!["type"];
    final content = materialDetails!["content"];
    // final optionalText = materialDetails!["optional_text"];

    switch (type) {
      case "text":
        return Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              content ?? L10n.getTranslatedText(context, 'No content available'),
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      case "image":
        return Card(
          margin: EdgeInsets.all(8),
          child: Image.network(
            content,
            fit: BoxFit.cover,
          ),
        );
      case "video":
        return Card(
          margin: EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Center(child: CircularProgressIndicator()),
          ),
        );
      case "audio":
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.audiotrack, size: 40),
            title: Text("Audio File"),
            subtitle: Text("Tap to play"),
            onTap: () => _launchFile(content),
          ),
        );
      case "document":
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.insert_drive_file, size: 40),
            title: Text("Document File"),
            subtitle: Text("Tap to open"),
            onTap: () => _launchFile(content),
          ),
        );
      default:
        return Center(child: Text("Unsupported material type"));
    }
  }

  Widget _buildOptionalText() {
    final optionalText = materialDetails?["optional_text"];
    if (optionalText == null || optionalText.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        optionalText,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.getTranslatedText(context, 'Material Details'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AcademeTheme.white),
        ),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  "${L10n.getTranslatedText(context, 'Type')}: ${materialDetails?["type"] ?? widget.materialType}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${L10n.getTranslatedText(context, 'Category')}: ${materialDetails?["category"] ?? widget.materialCategory}",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            _buildMaterialContent(),
            _buildOptionalText(),
          ],
        ),
      ),
    );
  }
}