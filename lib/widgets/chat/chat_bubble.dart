import 'package:flutter/material.dart';
import 'package:lux_app/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color glow;
  final String luxName;

  const ChatBubble({
    required this.message,
    required this.glow,
    required this.luxName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: glow.withOpacity(0.2),
              child: Text(
                luxName[0],
                style: TextStyle(
                  color: glow,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? glow.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: message.isMemoryFollowUp
                    ? Border(
                        left: BorderSide(color: glow, width: 4),
                        top: BorderSide(color: glow.withOpacity(0.2)),
                        right: BorderSide(color: glow.withOpacity(0.2)),
                        bottom: BorderSide(color: glow.withOpacity(0.2)),
                      )
                    : (message.isUser
                          ? Border.all(color: glow.withOpacity(0.3))
                          : null),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? glow : Colors.grey[800],
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: glow.withOpacity(0.2),
              child: Icon(Icons.person, color: glow, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
