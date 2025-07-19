import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';

class AttachmentOptionsSheet extends StatelessWidget {
  final VoidCallback onImageSelected;
  final VoidCallback onDocumentSelected;
  final VoidCallback onVideoSelected;
  final VoidCallback onAudioSelected;

  const AttachmentOptionsSheet({
    super.key,
    required this.onImageSelected,
    required this.onDocumentSelected,
    required this.onVideoSelected,
    required this.onAudioSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAttachmentOption(
              context,
              Icons.image,
              L10n.getTranslatedText(context, 'Image'),
              Colors.blue,
              onImageSelected),
          _buildAttachmentOption(
              context,
              Icons.insert_drive_file,
              L10n.getTranslatedText(context, 'Document'),
              Colors.green,
              onDocumentSelected),
          _buildAttachmentOption(
              context,
              Icons.video_library,
              L10n.getTranslatedText(context, 'Video'),
              Colors.orange,
              onVideoSelected),
          _buildAttachmentOption(
              context,
              Icons.audiotrack,
              L10n.getTranslatedText(context, 'Audio'),
              Colors.purple,
              onAudioSelected),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(BuildContext context, IconData icon,
      String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
