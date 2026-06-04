import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isTyping;
  final Color glow;
  final bool isExpectingQuestion;
  final Function(String)? onChanged;

  const MessageInput({
    required this.controller,
    required this.onSend,
    required this.isTyping,
    required this.glow,
    required this.isExpectingQuestion,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isExpectingQuestion) Icon(Icons.help_outline, color: glow),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isTyping,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: glow,
            child: IconButton(
              icon: Icon(
                isTyping ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
              ),
              onPressed: isTyping ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
