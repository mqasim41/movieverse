import 'package:flutter/material.dart';

/// Message role - either the user or the assistant (AI)
enum MessageRole {
  user,
  assistant,
}

/// A chat message in a conversation
class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  /// Creates a new chat message
  ChatMessage({
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a user message
  factory ChatMessage.user(String text) {
    return ChatMessage(
      text: text,
      role: MessageRole.user,
    );
  }

  /// Creates an assistant (AI) message
  factory ChatMessage.assistant(String text) {
    return ChatMessage(
      text: text,
      role: MessageRole.assistant,
    );
  }

  /// Creates a loading message
  factory ChatMessage.loading() {
    return ChatMessage(
      text: '',
      role: MessageRole.assistant,
      isLoading: true,
    );
  }

  /// Convert to a map for API request format
  Map<String, String> toMap() {
    final key = role == MessageRole.user ? 'user' : 'assistant';
    return {key: text};
  }

  /// Get the color for this message's bubble
  Color getBubbleColor(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    if (role == MessageRole.user) {
      return theme.colorScheme.primary;
    } else {
      return isDarkMode
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.secondaryContainer;
    }
  }

  /// Get the text color for this message
  Color getTextColor(BuildContext context) {
    final theme = Theme.of(context);

    if (role == MessageRole.user) {
      return theme.colorScheme.onPrimary;
    } else {
      return theme.colorScheme.onSecondaryContainer;
    }
  }

  /// Get alignment for this message
  Alignment getAlignment() {
    return role == MessageRole.user
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }
}
