class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isMemoryFollowUp;
  final String? memoryKey;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isMemoryFollowUp = false,
    this.memoryKey,
  });
}
