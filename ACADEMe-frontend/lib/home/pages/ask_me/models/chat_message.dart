class ChatMessage {
  final String role;
  final String? text;
  final String? fileInfo;
  final String? fileType;
  final bool isTyping;
  final String? status;

  ChatMessage({
    required this.role,
    this.text,
    this.fileInfo,
    this.fileType,
    this.isTyping = false,
    this.status,
  });
}
