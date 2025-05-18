import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../config/theme.dart';

/// A widget that displays a chat message bubble
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDarkMode = brightness == Brightness.dark;

    // For loading indicator message
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 12.0,
          ),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDarkMode
                ? theme.colorScheme.surfaceVariant
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: message.getAlignment(),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 12.0,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 14.0,
        ),
        decoration: BoxDecoration(
          color: message.getBubbleColor(context, isDarkMode),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: message.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: message.getTextColor(context).withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
